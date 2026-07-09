#!/usr/bin/env python3
"""
Rebrand element-android checkout to "Topstar Chat":
  - Launcher icon (all densities + adaptive) -> Topstar robot on white
  - Login/splash logo -> robot, wordmark -> TOPSTAR
  - Help/About screen -> Hant Automation contact (web + email) + HANT logo
  - Remove old Element/Matrix informational links
Run from the element-android workspace root. Assets live next to this script
in brand_assets/.
"""
import os
import re
import glob
import shutil

ROOT = os.getcwd()
ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "brand_assets")

def log(m): print("[rebrand] " + m)

# ---------------------------------------------------------------------------
# 1) Launcher icons
# ---------------------------------------------------------------------------
APP_RES = os.path.join(ROOT, "vector-app", "src", "main", "res")
DENS = ["mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"]
for d in DENS:
    src = os.path.join(ASSETS, "icons", "mipmap-" + d)
    dst = os.path.join(APP_RES, "mipmap-" + d)
    os.makedirs(dst, exist_ok=True)
    for f in ("ic_launcher.png", "ic_launcher_round.png", "ic_launcher_foreground.png"):
        s = os.path.join(src, f)
        assert os.path.exists(s), "missing asset " + s
        shutil.copy(s, os.path.join(dst, f))
    log("icons -> mipmap-" + d)

# adaptive icon xml + background
anydpi = os.path.join(APP_RES, "mipmap-anydpi-v26")
os.makedirs(anydpi, exist_ok=True)
shutil.copy(os.path.join(ASSETS, "mipmap-anydpi-v26", "ic_launcher.xml"),
            os.path.join(anydpi, "ic_launcher.xml"))
shutil.copy(os.path.join(ASSETS, "mipmap-anydpi-v26", "ic_launcher_round.xml"),
            os.path.join(anydpi, "ic_launcher_round.xml"))
# ic_launcher_background may exist as vector xml -> overwrite with solid color shape
for p in glob.glob(os.path.join(APP_RES, "drawable*", "ic_launcher_background.*")):
    os.remove(p)
bgdir = os.path.join(APP_RES, "drawable")
os.makedirs(bgdir, exist_ok=True)
shutil.copy(os.path.join(ASSETS, "drawable", "ic_launcher_background.xml"),
            os.path.join(bgdir, "ic_launcher_background.xml"))
log("adaptive icon updated")

# ---------------------------------------------------------------------------
# 2) Splash / login logos: remove old drawables (any module, any variant),
#    drop replacement PNGs into vector module drawable-nodpi
# ---------------------------------------------------------------------------
LOGO_NAMES = ["element_logo_green", "element_logotype", "element_logo_stars",
              "element_splash_white"]
for name in LOGO_NAMES:
    for p in glob.glob(os.path.join(ROOT, "**", "res", "drawable*", name + ".*"), recursive=True):
        os.remove(p)
        log("removed old " + os.path.relpath(p, ROOT))
# element_logo_green (login logo) + element_splash_white (loading screen) are
# referenced via im.vector.lib.ui.styles.R -> must live in ui-styles module.
# The others are referenced only from the vector module.
vector_nodpi = os.path.join(ROOT, "vector", "src", "main", "res", "drawable-nodpi")
uistyles_nodpi = os.path.join(ROOT, "library", "ui-styles", "src", "main", "res", "drawable-nodpi")
DEST = {
    "element_logo_green": uistyles_nodpi,
    "element_splash_white": uistyles_nodpi,
    "element_logotype": vector_nodpi,
    "element_logo_stars": vector_nodpi,
    "logo_hant": vector_nodpi,
}
for name, dstdir in DEST.items():
    os.makedirs(dstdir, exist_ok=True)
    s = os.path.join(ASSETS, "drawable-nodpi", name + ".png")
    assert os.path.exists(s), "missing asset " + s
    shutil.copy(s, os.path.join(dstdir, name + ".png"))
    log(name + " -> " + os.path.relpath(dstdir, ROOT))
log("splash/wordmark/hant logos installed")

# ---------------------------------------------------------------------------
# 2d) Brand color: Element green (#0DBD8B) -> Topstar blue (#187DC1) everywhere.
#     Covers colorPrimary/accent (buttons, create-chat FAB, links, selected
#     states), the loading-screen background (?colorPrimary) and hardcoded
#     icon fills. Case-insensitive so alpha-prefixed values (#330DBD8B) match.
# ---------------------------------------------------------------------------
TOPSTAR_BLUE = "187DC1"
color_files = glob.glob(os.path.join(ROOT, "library", "ui-styles", "src", "main",
                                      "res", "**", "*.xml"), recursive=True)
color_files += glob.glob(os.path.join(ROOT, "vector", "src", "main",
                                       "res", "**", "*.xml"), recursive=True)
recolored = 0
for cf in color_files:
    with open(cf, encoding="utf-8") as f:
        c = f.read()
    nc = re.sub("0DBD8B", TOPSTAR_BLUE, c, flags=re.IGNORECASE)
    if nc != c:
        with open(cf, "w", encoding="utf-8") as f:
            f.write(nc)
        recolored += 1
log("recolored Element green -> #%s in %d files" % (TOPSTAR_BLUE, recolored))

# ---------------------------------------------------------------------------
# 2e) Login splash screens: enlarge the machine logo so both machines are
#     visible, and hide the old TOPSTAR wordmark (user wants machines only).
# ---------------------------------------------------------------------------
login_layouts = [
    os.path.join(ROOT, "vector", "src", "main", "res", "layout", "fragment_ftue_auth_splash.xml"),
    os.path.join(ROOT, "vector", "src", "main", "res", "layout", "fragment_login_splash.xml"),
]
logo_old = ('android:id="@+id/loginSplashLogo"\n'
            '            android:layout_width="64dp"\n'
            '            android:layout_height="64dp"')
logo_new = ('android:id="@+id/loginSplashLogo"\n'
            '            android:layout_width="260dp"\n'
            '            android:layout_height="120dp"\n'
            '            android:scaleType="fitCenter"')
for lay in login_layouts:
    if not os.path.exists(lay):
        log("WARN login layout missing: " + lay)
        continue
    with open(lay, encoding="utf-8") as f:
        t = f.read()
    orig_t = t
    if logo_old in t:
        t = t.replace(logo_old, logo_new, 1)
    else:
        log("WARN loginSplashLogo size anchor not found in " + os.path.basename(lay))
    t = t.replace('android:id="@+id/logoType"',
                  'android:id="@+id/logoType"\n            android:visibility="gone"', 1)
    if t != orig_t:
        with open(lay, "w", encoding="utf-8") as f:
            f.write(t)
        log("login layout updated: " + os.path.basename(lay))

# ---------------------------------------------------------------------------
# 2b) App name is set via resValue in vector-app/build.gradle (NOT strings.xml)
# ---------------------------------------------------------------------------
gradle = os.path.join(ROOT, "vector-app", "build.gradle")
with open(gradle) as f:
    g = f.read()
g = g.replace('resValue "string", "app_name", "Element Classic - dbg"',
              'resValue "string", "app_name", "Topstar Chat"')
g = g.replace('resValue "string", "app_name", "Element Classic"',
              'resValue "string", "app_name", "Topstar Chat"')

# 2c) Release signing: the upstream `release` signingConfig reads gradle
#     properties (signing.element.*) that don't exist in our fork, which
#     would break configuration. Rewrite it to read from environment vars
#     (populated from GitHub Actions secrets), and enable it on the release
#     build type. Falls back to the debug keystore when env vars are absent
#     so a plain `assembleFdroidRelease` still configures locally.
release_sig_old = '''        release {
            keyAlias project.property("signing.element.keyId")
            keyPassword project.property("signing.element.keyPassword")
            storeFile file(project.property("signing.element.storePath"))
            storePassword project.property("signing.element.storePassword")
        }'''
release_sig_new = '''        release {
            keyAlias System.env.TOPSTAR_KEY_ALIAS ?: 'androiddebugkey'
            keyPassword System.env.TOPSTAR_KEY_PASSWORD ?: 'android'
            storeFile file(System.env.TOPSTAR_STORE_FILE ?: './signature/debug.keystore')
            storePassword System.env.TOPSTAR_STORE_PASSWORD ?: 'android'
        }'''
assert release_sig_old in g, "release signingConfig anchor not found"
g = g.replace(release_sig_old, release_sig_new, 1)

# enable signing on the release build type (upstream leaves it commented out)
g = g.replace('            // signingConfig signingConfigs.release',
              '            signingConfig signingConfigs.release')

with open(gradle, "w") as f:
    f.write(g)
log("app_name resValue -> Topstar Chat; release signing wired to env vars")

# ---------------------------------------------------------------------------
# 3) Replace old informational links
# ---------------------------------------------------------------------------
urls_kt = os.path.join(ROOT, "vector", "src", "main", "java", "im", "vector",
                       "app", "features", "settings", "VectorSettingsUrls.kt")
with open(urls_kt) as f:
    txt = f.read()
for old in ['"https://element.io/help"', '"https://element.io/copyright"',
            '"https://element.io/acceptable-use-policy-terms"',
            '"https://element.io/privacy"']:
    txt = txt.replace(old, '"https://hauto.store"')
with open(urls_kt, "w") as f:
    f.write(txt)
log("VectorSettingsUrls.kt links -> hauto.store")

urls_xml = os.path.join(ROOT, "vector-config", "src", "main", "res", "values", "urls.xml")
if os.path.exists(urls_xml):
    with open(urls_xml) as f:
        u = f.read()
    u = u.replace("https://element.io/help#threads", "https://hauto.store")
    u = u.replace("https://element.io/ems", "https://hauto.store")
    with open(urls_xml, "w") as f:
        f.write(u)
    log("urls.xml links -> hauto.store")

# 3b) Strip remaining visible element.io mentions from all string resources
#     (e.g. "element.io/ems" promo text shown during sign-up, in every locale).
#     Only touch user-facing strings; functional endpoints live in config.xml.
strings_files = glob.glob(os.path.join(ROOT, "library", "ui-strings", "src", "main",
                                       "res", "values*", "strings.xml"))
strings_files += glob.glob(os.path.join(ROOT, "library", "ui-strings", "src", "main",
                                        "res", "values*", "donottranslate.xml"))
changed = 0
for sf in strings_files:
    with open(sf, encoding="utf-8") as f:
        c = f.read()
    orig_c = c
    c = c.replace("element.io/ems", "hauto.store")
    c = c.replace("element.io/help", "hauto.store")
    c = c.replace("https://element.io", "https://hauto.store")
    c = c.replace(">element.io<", ">hauto.store<")
    if c != orig_c:
        with open(sf, "w", encoding="utf-8") as f:
            f.write(c)
        changed += 1
log("stripped element.io from %d string files" % changed)

# ---------------------------------------------------------------------------
# 4) Rewrite Help/About screen with Hant Automation contact
# ---------------------------------------------------------------------------
about_xml = None
for p in glob.glob(os.path.join(ROOT, "**", "vector_settings_help_about.xml"), recursive=True):
    about_xml = p
    break
assert about_xml, "vector_settings_help_about.xml not found"
NEW_ABOUT = '''<?xml version="1.0" encoding="utf-8"?>
<androidx.preference.PreferenceScreen xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <im.vector.app.core.preference.VectorPreferenceCategory android:title="Lien he / Support">

        <im.vector.app.core.preference.VectorPreference
            android:key="SETTINGS_HELP_PREFERENCE_KEY"
            android:icon="@drawable/logo_hant"
            android:title="Hant Automation"
            android:summary="Nhan de mo website ho tro: hauto.store" />

        <im.vector.app.core.preference.VectorPreference
            android:title="Website"
            android:summary="https://hauto.store">
            <intent android:action="android.intent.action.VIEW"
                android:data="https://hauto.store" />
        </im.vector.app.core.preference.VectorPreference>

        <im.vector.app.core.preference.VectorPreference
            android:title="Email"
            android:summary="ntha.2027@gmail.com">
            <intent android:action="android.intent.action.SENDTO"
                android:data="mailto:ntha.2027@gmail.com" />
        </im.vector.app.core.preference.VectorPreference>

    </im.vector.app.core.preference.VectorPreferenceCategory>

    <im.vector.app.core.preference.VectorPreferenceCategory android:title="@string/preference_versions">

        <im.vector.app.core.preference.VectorPreference
            android:key="SETTINGS_VERSION_PREFERENCE_KEY"
            android:title="@string/settings_version"
            tools:summary="1.2.3" />

        <im.vector.app.core.preference.VectorPreference
            android:key="SETTINGS_SDK_VERSION_PREFERENCE_KEY"
            android:title="@string/settings_sdk_version"
            tools:summary="4.5.6" />

        <im.vector.app.core.preference.VectorPreference
            android:key="SETTINGS_CRYPTO_VERSION_PREFERENCE_KEY"
            android:title="@string/settings_crypto_version"
            tools:summary="7.8.9" />

    </im.vector.app.core.preference.VectorPreferenceCategory>

    <im.vector.app.core.preference.VectorPreferenceCategory android:title="@string/preference_system_settings">

        <im.vector.app.core.preference.VectorPreference
            android:key="APP_INFO_LINK_PREFERENCE_KEY"
            android:summary="@string/settings_app_info_link_summary"
            android:title="@string/settings_app_info_link_title" />

    </im.vector.app.core.preference.VectorPreferenceCategory>

</androidx.preference.PreferenceScreen>
'''
with open(about_xml, "w") as f:
    f.write(NEW_ABOUT)
log("Help/About screen rewritten -> Hant Automation contact")

log("DONE")
