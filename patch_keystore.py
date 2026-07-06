#!/usr/bin/env python3
"""
Patch matrix-sdk-android SecretStoringUtils.kt so that when the hardware
Android Keystore fails to generate a key (e.g. TEE error -41
"Memory allocation failed" on some Xiaomi/Snapdragon devices), the app
falls back to a software AES key persisted in app-private SharedPreferences
instead of crashing on startup.
"""
import sys

PATH = "matrix-sdk-android/src/main/java/org/matrix/android/sdk/api/securestorage/SecretStoringUtils.kt"

with open(PATH, "r") as f:
    src = f.read()

orig = src

# --- 1. Add Base64 import ---
anchor_import = "import android.content.Context\n"
add_import = "import android.content.Context\nimport android.util.Base64\n"
assert anchor_import in src, "import anchor not found"
src = src.replace(anchor_import, add_import, 1)

# --- 2. Route M-path encryption through getOrGenerateSymmetricKeyForAliasM ---
enc_old = """    fun getEncryptCipher(alias: String): Cipher {
        val key = when (val keyEntry = ensureKey(alias)) {
            is KeyStore.SecretKeyEntry -> keyEntry.secretKey
            is KeyStore.PrivateKeyEntry -> keyEntry.certificate.publicKey
            else -> throw IllegalStateException("Unknown KeyEntry type.")
        }
        val cipherAlgorithm = when {
            buildVersionSdkIntProvider.get() >= Build.VERSION_CODES.M -> AES_MODE
            else -> RSA_MODE
        }
        val cipher = Cipher.getInstance(cipherAlgorithm)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        return cipher
    }"""
enc_new = """    fun getEncryptCipher(alias: String): Cipher {
        if (buildVersionSdkIntProvider.get() >= Build.VERSION_CODES.M) {
            val symKey = getOrGenerateSymmetricKeyForAliasM(alias)
            val cipherM = Cipher.getInstance(AES_MODE)
            cipherM.init(Cipher.ENCRYPT_MODE, symKey)
            return cipherM
        }
        val key = when (val keyEntry = ensureKey(alias)) {
            is KeyStore.SecretKeyEntry -> keyEntry.secretKey
            is KeyStore.PrivateKeyEntry -> keyEntry.certificate.publicKey
            else -> throw IllegalStateException("Unknown KeyEntry type.")
        }
        val cipher = Cipher.getInstance(RSA_MODE)
        cipher.init(Cipher.ENCRYPT_MODE, key)
        return cipher
    }"""
assert enc_old in src, "getEncryptCipher anchor not found"
src = src.replace(enc_old, enc_new, 1)

# --- 3. Wrap hardware key generation with software fallback ---
gen_old = """            generator.init(keyGenSpec)
            return generator.generateKey()
        }
        return secretKeyEntry
    }"""
gen_new = """            try {
                generator.init(keyGenSpec)
                return generator.generateKey()
            } catch (failure: Throwable) {
                Timber.e(failure, "## Hardware keystore key generation failed for alias %s, falling back to software key", alias)
                return getOrGenerateSoftwareKeyForAliasM(alias)
            }
        }
        return secretKeyEntry
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun getOrGenerateSoftwareKeyForAliasM(alias: String): SecretKey {
        val prefs = context.getSharedPreferences("sec_store_soft_keys", Context.MODE_PRIVATE)
        val existing = prefs.getString(alias, null)
        if (existing != null) {
            return SecretKeySpec(Base64.decode(existing, Base64.NO_WRAP), "AES")
        }
        val keyGen = KeyGenerator.getInstance("AES")
        keyGen.init(128)
        val key = keyGen.generateKey()
        prefs.edit().putString(alias, Base64.encodeToString(key.encoded, Base64.NO_WRAP)).apply()
        return key
    }"""
assert gen_old in src, "key generation anchor not found"
src = src.replace(gen_old, gen_new, 1)

assert src != orig, "no changes applied"

with open(PATH, "w") as f:
    f.write(src)

print("SecretStoringUtils.kt patched OK: software keystore fallback added")
