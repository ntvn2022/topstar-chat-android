#!/usr/bin/env bash
# =====================================================================
# apply_topstar_app_changes.sh
# Re-applies ALL the Topstar Chat app feature changes (made in the
# element-android "develop" working tree) onto the CLEAN Topstar tree.
#
# What it applies (source-code only; NOT build.gradle/signing/icons):
#   1. Hide 6 items: Dev tools, Add Matrix apps, Session ID, Session key,
#      Access Token, Email notification.
#   2. "Name" field on the account-creation screen -> set as display name
#      right after registration.
#   3. Onboarding/login tweaks (server selection, login fragment,
#      splash carousel, homeserver alias), settings general/notifications.
#
# Usage:
#   ./apply_topstar_app_changes.sh [path-to-clean-element-android]
# If no path is given it uses the current directory.
# =====================================================================
set -euo pipefail

TARGET="${1:-$(pwd)}"
cd "$TARGET"

if [ ! -f "vector-app/build.gradle" ] || [ ! -d "vector/src/main/java/im/vector/app" ]; then
  echo "ERROR: '$TARGET' does not look like an element-android tree." >&2
  echo "       Run:  ./apply_topstar_app_changes.sh /path/to/clean/element-android" >&2
  exit 1
fi

echo ">> Target tree: $TARGET"

PATCH="$(mktemp /tmp/topstar_app_changes.XXXXXX.patch)"
trap 'rm -f "$PATCH"' EXIT

cat > "$PATCH" <<'TOPSTAR_PATCH_EOF'
diff --git a/library/ui-strings/src/main/res/values/strings.xml b/library/ui-strings/src/main/res/values/strings.xml
index 02c87d3..4a60cff 100644
--- a/library/ui-strings/src/main/res/values/strings.xml
+++ b/library/ui-strings/src/main/res/values/strings.xml
@@ -2004,6 +2004,16 @@
     <!-- Note to translators: the translation MUST contain the string "${app_name}", which will be replaced by the application name -->
     <string name="ftue_auth_carousel_workplace_body">${app_name} is also great for the workplace. It’s trusted by the world’s most secure organisations.</string>
 
+    <!-- Topstar product showcase on the login carousel -->
+    <string name="ftue_topstar_robot_title">Robot lấy sản phẩm TDME.</string>
+    <string name="ftue_topstar_robot_body">Cánh tay servo tốc độ cao cho máy ép nhựa: gắp – lấy sản phẩm chính xác, giảm nhân công, tăng năng suất và độ ổn định.</string>
+    <string name="ftue_topstar_3in1_title">Máy sấy 3 trong 1.</string>
+    <string name="ftue_topstar_3in1_body">Tách ẩm – sấy khô – tiếp liệu trong một thiết bị. Giữ hạt nhựa luôn khô, siêu tiết kiệm điện, chất lượng sản phẩm đồng đều.</string>
+    <string name="ftue_topstar_chiller_title">Máy làm lạnh nước (Chiller).</string>
+    <string name="ftue_topstar_chiller_body">Làm mát khuôn nhanh và ổn định, rút ngắn chu kỳ ép, tiết kiệm điện, vận hành bền bỉ 24/7.</string>
+    <string name="ftue_topstar_mtc_title">Máy điều nhiệt khuôn (MTC).</string>
+    <string name="ftue_topstar_mtc_body">Kiểm soát nhiệt độ khuôn chính xác, bề mặt sản phẩm đẹp, giảm phế phẩm, nâng cao chất lượng ép nhựa.</string>
+
     <string name="ftue_auth_use_case_title">Who will you chat to the most?</string>
     <string name="ftue_auth_use_case_subtitle">We\'ll help you get connected</string>
     <string name="ftue_auth_use_case_option_one">Friends and family</string>
@@ -2024,6 +2034,8 @@
     <!-- Note for translators, %s is the full matrix of the account being created, eg @hello:matrix.org -->
     <string name="ftue_auth_create_account_username_entry_footer">Others can discover you %s</string>
     <string name="ftue_auth_create_account_password_entry_footer">Must be 8 characters or more</string>
+    <string name="ftue_auth_create_account_name_hint">Name</string>
+    <string name="error_empty_field_enter_display_name">Please enter your name</string>
     <string name="ftue_auth_create_account_choose_server_header">Where your conversations will live</string>
     <string name="ftue_auth_sign_in_choose_server_header">Where your conversations live</string>
     <string name="ftue_auth_create_account_sso_section_header">Or</string>
diff --git a/vector-config/src/main/res/values/config.xml b/vector-config/src/main/res/values/config.xml
index 6ab8892..c91f6fd 100755
--- a/vector-config/src/main/res/values/config.xml
+++ b/vector-config/src/main/res/values/config.xml
@@ -4,7 +4,7 @@
     <!-- "app_name" is now defined in build.gradle -->
 
     <!-- server urls -->
-    <string name="matrix_org_server_url" translatable="false">https://matrix.org</string>
+    <string name="matrix_org_server_url" translatable="false">https://chat.hauto.store</string>
 
     <!-- Rageshake configuration -->
     <string name="bug_report_url" translatable="false">https://rageshakes.element.io/api/submit</string>
diff --git a/vector/src/main/java/im/vector/app/features/home/room/detail/TimelineViewModel.kt b/vector/src/main/java/im/vector/app/features/home/room/detail/TimelineViewModel.kt
index f92a062..d05cfc6 100644
--- a/vector/src/main/java/im/vector/app/features/home/room/detail/TimelineViewModel.kt
+++ b/vector/src/main/java/im/vector/app/features/home/room/detail/TimelineViewModel.kt
@@ -836,14 +836,14 @@ class TimelineViewModel @AssistedInject constructor(
                 when (itemId) {
                     R.id.timeline_setting -> true
                     R.id.invite -> state.canInvite
-                    R.id.open_matrix_apps -> true
+                    R.id.open_matrix_apps -> false
                     R.id.voice_call -> state.isCallOptionAvailable() || state.hasActiveElementCallWidget()
                     R.id.video_call -> state.isCallOptionAvailable() || state.jitsiState.confId == null || state.jitsiState.hasJoined
                     // Show Join conference button only if there is an active conf id not joined. Otherwise fallback to default video disabled. ^
                     R.id.join_conference -> !state.isCallOptionAvailable() && state.jitsiState.confId != null && !state.jitsiState.hasJoined
                     R.id.search -> state.isSearchAvailable()
                     R.id.menu_timeline_thread_list -> vectorPreferences.areThreadMessagesEnabled()
-                    R.id.dev_tools -> vectorPreferences.developerMode()
+                    R.id.dev_tools -> false
                     else -> false
                 }
             }
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingAction.kt b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingAction.kt
index 78e204c..cfbda8c 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingAction.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingAction.kt
@@ -75,6 +75,8 @@ sealed interface OnboardingAction : VectorViewModelAction {
 
     data class UserAcceptCertificate(val fingerprint: Fingerprint, val retryAction: OnboardingAction) : OnboardingAction
 
+    data class SetPendingDisplayName(val displayName: String) : OnboardingAction
+
     object PersonalizeProfile : OnboardingAction
     data class UpdateDisplayName(val displayName: String) : OnboardingAction
     object UpdateDisplayNameSkipped : OnboardingAction
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewModel.kt b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewModel.kt
index d81d55d..91c6020 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewModel.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewModel.kt
@@ -155,6 +155,7 @@ class OnboardingViewModel @AssistedInject constructor(
             is OnboardingAction.ResetAction -> handleResetAction(action)
             is OnboardingAction.UserAcceptCertificate -> handleUserAcceptCertificate(action)
             OnboardingAction.ClearHomeServerHistory -> handleClearHomeServerHistory()
+            is OnboardingAction.SetPendingDisplayName -> setState { copy(pendingDisplayName = action.displayName) }
             is OnboardingAction.UpdateDisplayName -> updateDisplayName(action.displayName)
             OnboardingAction.UpdateDisplayNameSkipped -> handleDisplayNameStepComplete()
             OnboardingAction.UpdateProfilePictureSkipped -> completePersonalization()
@@ -620,9 +621,16 @@ class OnboardingViewModel @AssistedInject constructor(
 
         when (authenticationDescription) {
             is AuthenticationDescription.Register -> {
-                val personalizationState = createPersonalizationState(session, state)
+                // Apply the name entered on the account creation screen as the display name
+                state.pendingDisplayName?.takeIf { it.isNotBlank() }?.let { displayName ->
+                    runCatching { session.profileService().setDisplayName(session.myUserId, displayName) }
+                            .onFailure { Timber.e(it, "Failed to set display name after registration") }
+                }
+                val personalizationState = createPersonalizationState(session, state).let { ps ->
+                    state.pendingDisplayName?.takeIf { it.isNotBlank() }?.let { ps.copy(displayName = it) } ?: ps
+                }
                 setState {
-                    copy(isLoading = false, personalizationState = personalizationState)
+                    copy(isLoading = false, personalizationState = personalizationState, pendingDisplayName = null)
                 }
                 _viewEvents.post(OnboardingViewEvents.OnAccountCreated)
             }
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewState.kt b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewState.kt
index 15cd004..15323ed 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewState.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/OnboardingViewState.kt
@@ -50,6 +50,10 @@ data class OnboardingViewState(
 
         @PersistState
         val personalizationState: PersonalizationState = PersonalizationState(),
+
+        // Display name entered on the account creation screen, applied right after the account is created
+        @PersistState
+        val pendingDisplayName: String? = null,
 ) : MavericksState
 
 enum class OnboardingFlow {
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedLoginFragment.kt b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedLoginFragment.kt
index f8a5a28..ddaf352 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedLoginFragment.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedLoginFragment.kt
@@ -25,7 +25,6 @@ import im.vector.app.core.extensions.hidePassword
 import im.vector.app.core.extensions.realignPercentagesToParent
 import im.vector.app.core.extensions.setOnFocusLostListener
 import im.vector.app.core.extensions.setOnImeDoneListener
-import im.vector.app.core.extensions.toReducedUrl
 import im.vector.app.databinding.FragmentFtueCombinedLoginBinding
 import im.vector.app.features.VectorFeatures
 import im.vector.app.features.login.LoginMode
@@ -110,7 +109,7 @@ class FtueAuthCombinedLoginFragment :
         setupUi(state)
         setupAutoFill()
 
-        views.selectedServerName.text = state.selectedHomeserver.userFacingUrl.toReducedUrl()
+        views.selectedServerName.text = HomeserverAlias.displayName(state.selectedHomeserver.userFacingUrl)
 
         if (state.isLoading) {
             // Ensure password is hidden
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedRegisterFragment.kt b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedRegisterFragment.kt
index 8b5127b..d44e45a 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedRegisterFragment.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedRegisterFragment.kt
@@ -34,7 +34,6 @@ import im.vector.app.core.extensions.onTextChange
 import im.vector.app.core.extensions.realignPercentagesToParent
 import im.vector.app.core.extensions.setOnFocusLostListener
 import im.vector.app.core.extensions.setOnImeDoneListener
-import im.vector.app.core.extensions.toReducedUrl
 import im.vector.app.core.resources.BuildMeta
 import im.vector.app.core.utils.openApplicationStore
 import im.vector.app.core.utils.openUrlInChromeCustomTab
@@ -78,7 +77,7 @@ class FtueAuthCombinedRegisterFragment :
         views.createAccountRoot.realignPercentagesToParent()
         views.editServerButton.debouncedClicks { viewModel.handle(OnboardingAction.PostViewEvent(OnboardingViewEvents.EditServerSelection)) }
         views.createAccountPasswordInput.setOnImeDoneListener {
-            if (canSubmit(views.createAccountInput.content(), views.createAccountPasswordInput.content())) {
+            if (canSubmit(views.createAccountNameInput.content(), views.createAccountInput.content(), views.createAccountPasswordInput.content())) {
                 submit()
             }
         }
@@ -93,19 +92,25 @@ class FtueAuthCombinedRegisterFragment :
         }
     }
 
-    private fun canSubmit(account: CharSequence, password: CharSequence): Boolean {
+    private fun canSubmit(name: CharSequence, account: CharSequence, password: CharSequence): Boolean {
+        val nameIsValid = name.isNotEmpty()
         val accountIsValid = account.isNotEmpty()
         val passwordIsValid = password.length >= MINIMUM_PASSWORD_LENGTH
-        return accountIsValid && passwordIsValid
+        return nameIsValid && accountIsValid && passwordIsValid
     }
 
     private fun setupSubmitButton() {
         views.createAccountSubmit.setOnClickListener { submit() }
+        views.createAccountNameInput.clearErrorOnChange(viewLifecycleOwner)
         views.createAccountInput.clearErrorOnChange(viewLifecycleOwner)
         views.createAccountPasswordInput.clearErrorOnChange(viewLifecycleOwner)
 
-        combine(views.createAccountInput.editText().textChanges(), views.createAccountPasswordInput.editText().textChanges()) { account, password ->
-            views.createAccountSubmit.isEnabled = canSubmit(account, password)
+        combine(
+                views.createAccountNameInput.editText().textChanges(),
+                views.createAccountInput.editText().textChanges(),
+                views.createAccountPasswordInput.editText().textChanges()
+        ) { name, account, password ->
+            views.createAccountSubmit.isEnabled = canSubmit(name, account, password)
         }.launchIn(viewLifecycleOwner.lifecycleScope)
     }
 
@@ -113,11 +118,16 @@ class FtueAuthCombinedRegisterFragment :
         withState(viewModel) { state ->
             cleanupUi()
 
+            val name = views.createAccountNameInput.content()
             val login = views.createAccountInput.content()
             val password = views.createAccountPasswordInput.content()
 
             // This can be called by the IME action, so deal with empty cases
             var error = 0
+            if (name.isEmpty()) {
+                views.createAccountNameInput.error = getString(CommonStrings.error_empty_field_enter_display_name)
+                error++
+            }
             if (login.isEmpty()) {
                 views.createAccountInput.error = getString(CommonStrings.error_empty_field_choose_user_name)
                 error++
@@ -132,6 +142,7 @@ class FtueAuthCombinedRegisterFragment :
             }
 
             if (error == 0) {
+                viewModel.handle(OnboardingAction.SetPendingDisplayName(name.toString()))
                 val initialDeviceName = getString(CommonStrings.login_default_session_public_name)
                 val registerAction = when {
                     login.isMatrixId() -> AuthenticateAction.RegisterWithMatrixId(login, password, initialDeviceName)
@@ -144,6 +155,7 @@ class FtueAuthCombinedRegisterFragment :
 
     private fun cleanupUi() {
         views.createAccountSubmit.hideKeyboard()
+        views.createAccountNameInput.error = null
         views.createAccountInput.error = null
         views.createAccountPasswordInput.error = null
     }
@@ -190,7 +202,7 @@ class FtueAuthCombinedRegisterFragment :
     }
 
     private fun setupUi(state: OnboardingViewState) {
-        val serverName = state.selectedHomeserver.userFacingUrl.toReducedUrl()
+        val serverName = HomeserverAlias.displayName(state.selectedHomeserver.userFacingUrl)
         views.selectedServerName.text = serverName
 
         if (state.isLoading) {
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedServerSelectionFragment.kt b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedServerSelectionFragment.kt
index c58aac5..d82e821 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedServerSelectionFragment.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/FtueAuthCombinedServerSelectionFragment.kt
@@ -24,7 +24,6 @@ import im.vector.app.core.extensions.editText
 import im.vector.app.core.extensions.realignPercentagesToParent
 import im.vector.app.core.extensions.setOnImeDoneListener
 import im.vector.app.core.extensions.showKeyboard
-import im.vector.app.core.extensions.toReducedUrl
 import im.vector.app.core.resources.BuildMeta
 import im.vector.app.core.utils.ensureProtocol
 import im.vector.app.core.utils.ensureTrailingSlash
@@ -90,7 +89,8 @@ class FtueAuthCombinedServerSelectionFragment :
     private fun canSubmit(url: String) = url.isNotEmpty()
 
     private fun updateServerUrl() {
-        viewModel.handle(OnboardingAction.HomeServerChange.EditHomeServer(views.chooseServerInput.content().ensureProtocol().ensureTrailingSlash()))
+        val resolved = HomeserverAlias.resolve(views.chooseServerInput.content())
+        viewModel.handle(OnboardingAction.HomeServerChange.EditHomeServer(resolved.ensureProtocol().ensureTrailingSlash()))
     }
 
     override fun resetViewModel() {
@@ -107,7 +107,8 @@ class FtueAuthCombinedServerSelectionFragment :
         )
 
         if (views.chooseServerInput.content().isEmpty()) {
-            val userUrlInput = state.selectedHomeserver.userFacingUrl?.toReducedUrlKeepingSchemaIfInsecure() ?: viewModel.getDefaultHomeserverUrl()
+            val realUrl = state.selectedHomeserver.userFacingUrl ?: viewModel.getDefaultHomeserverUrl()
+            val userUrlInput = HomeserverAlias.displayName(realUrl)
             views.chooseServerInput.editText().setText(userUrlInput)
         }
 
@@ -141,6 +142,4 @@ class FtueAuthCombinedServerSelectionFragment :
                     getString(CommonStrings.view_download_replacement_app_title, config.replacementApplicationName)
         }
     }
-
-    private fun String.toReducedUrlKeepingSchemaIfInsecure() = toReducedUrl(keepSchema = this.startsWith("http://"))
 }
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/SplashCarouselStateFactory.kt b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/SplashCarouselStateFactory.kt
index 2f0f61d..d80eeb8 100644
--- a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/SplashCarouselStateFactory.kt
+++ b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/SplashCarouselStateFactory.kt
@@ -11,9 +11,7 @@ import android.content.Context
 import androidx.annotation.AttrRes
 import androidx.annotation.DrawableRes
 import im.vector.app.R
-import im.vector.app.core.resources.LocaleProvider
 import im.vector.app.core.resources.StringProvider
-import im.vector.app.core.resources.isEnglishSpeaking
 import im.vector.app.core.utils.colorTerminatingFullStop
 import im.vector.app.features.themes.ThemeProvider
 import im.vector.app.features.themes.ThemeUtils
@@ -25,51 +23,44 @@ import javax.inject.Inject
 class SplashCarouselStateFactory @Inject constructor(
         private val context: Context,
         private val stringProvider: StringProvider,
-        private val localeProvider: LocaleProvider,
         private val themeProvider: ThemeProvider,
 ) {
 
     fun create(): SplashCarouselState {
         val lightTheme = themeProvider.isLightTheme()
         fun background(@DrawableRes lightDrawable: Int) = if (lightTheme) lightDrawable else im.vector.lib.ui.styles.R.drawable.bg_color_background
-        fun hero(@DrawableRes lightDrawable: Int, @DrawableRes darkDrawable: Int) = if (lightTheme) lightDrawable else darkDrawable
+        // Topstar product showcase — 4 flagship machines (robot / 3in1 / chiller / mtc).
+        // The product photos have white backgrounds, so the same image works in both themes.
         return SplashCarouselState(
                 listOf(
                         SplashCarouselState.Item(
-                                CommonStrings.ftue_auth_carousel_secure_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
-                                CommonStrings.ftue_auth_carousel_secure_body,
-                                hero(R.drawable.ic_splash_conversations, R.drawable.ic_splash_conversations_dark),
+                                CommonStrings.ftue_topstar_robot_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
+                                CommonStrings.ftue_topstar_robot_body,
+                                R.drawable.ic_splash_robot,
                                 background(im.vector.lib.ui.styles.R.drawable.bg_carousel_page_1)
                         ),
                         SplashCarouselState.Item(
-                                CommonStrings.ftue_auth_carousel_control_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
-                                CommonStrings.ftue_auth_carousel_control_body,
-                                hero(R.drawable.ic_splash_control, R.drawable.ic_splash_control_dark),
+                                CommonStrings.ftue_topstar_3in1_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
+                                CommonStrings.ftue_topstar_3in1_body,
+                                R.drawable.ic_splash_3in1,
                                 background(im.vector.lib.ui.styles.R.drawable.bg_carousel_page_2)
                         ),
                         SplashCarouselState.Item(
-                                CommonStrings.ftue_auth_carousel_encrypted_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
-                                CommonStrings.ftue_auth_carousel_encrypted_body,
-                                hero(R.drawable.ic_splash_secure, R.drawable.ic_splash_secure_dark),
+                                CommonStrings.ftue_topstar_chiller_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
+                                CommonStrings.ftue_topstar_chiller_body,
+                                R.drawable.ic_splash_chiller,
                                 background(im.vector.lib.ui.styles.R.drawable.bg_carousel_page_3)
                         ),
                         SplashCarouselState.Item(
-                                collaborationTitle().colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
-                                CommonStrings.ftue_auth_carousel_workplace_body,
-                                hero(R.drawable.ic_splash_collaboration, R.drawable.ic_splash_collaboration_dark),
+                                CommonStrings.ftue_topstar_mtc_title.colorTerminatingFullStop(com.google.android.material.R.attr.colorAccent),
+                                CommonStrings.ftue_topstar_mtc_body,
+                                R.drawable.ic_splash_mtc,
                                 background(im.vector.lib.ui.styles.R.drawable.bg_carousel_page_4)
                         )
                 )
         )
     }
 
-    private fun collaborationTitle(): Int {
-        return when {
-            localeProvider.isEnglishSpeaking() -> CommonStrings.cut_the_slack_from_teams
-            else -> CommonStrings.ftue_auth_carousel_workplace_title
-        }
-    }
-
     private fun Int.colorTerminatingFullStop(@AttrRes color: Int): EpoxyCharSequence {
         return stringProvider.getString(this)
                 .colorTerminatingFullStop(ThemeUtils.getColor(context, color))
diff --git a/vector/src/main/res/layout/fragment_ftue_combined_register.xml b/vector/src/main/res/layout/fragment_ftue_combined_register.xml
index 353aa10..d69a918 100644
--- a/vector/src/main/res/layout/fragment_ftue_combined_register.xml
+++ b/vector/src/main/res/layout/fragment_ftue_combined_register.xml
@@ -160,7 +160,7 @@
             android:layout_marginTop="16dp"
             android:layout_marginBottom="16dp"
             android:visibility="gone"
-            app:layout_constraintBottom_toTopOf="@id/createAccountInput"
+            app:layout_constraintBottom_toTopOf="@id/createAccountNameInput"
             app:layout_constraintEnd_toEndOf="@id/createAccountGutterEnd"
             app:layout_constraintStart_toStartOf="@id/createAccountGutterStart"
             app:layout_constraintTop_toBottomOf="@id/chooseServerCardErrorMas"
@@ -173,6 +173,28 @@
 
         </FrameLayout>
 
+        <com.google.android.material.textfield.TextInputLayout
+            android:id="@+id/createAccountNameInput"
+            style="@style/Widget.Vector.TextInputLayout.Username"
+            android:layout_width="0dp"
+            android:layout_height="wrap_content"
+            android:hint="@string/ftue_auth_create_account_name_hint"
+            app:layout_constraintBottom_toTopOf="@id/createAccountInput"
+            app:layout_constraintEnd_toEndOf="@id/createAccountGutterEnd"
+            app:layout_constraintStart_toStartOf="@id/createAccountGutterStart"
+            app:layout_constraintTop_toBottomOf="@id/chooseServerCardDownloadReplacementApp">
+
+            <com.google.android.material.textfield.TextInputEditText
+                android:id="@+id/createAccountNameEditText"
+                android:layout_width="match_parent"
+                android:layout_height="match_parent"
+                android:imeOptions="actionNext"
+                android:inputType="textPersonName"
+                android:maxLines="1"
+                android:nextFocusForward="@id/createAccountEditText" />
+
+        </com.google.android.material.textfield.TextInputLayout>
+
         <com.google.android.material.textfield.TextInputLayout
             android:id="@+id/createAccountInput"
             style="@style/Widget.Vector.TextInputLayout.Username"
@@ -182,7 +204,7 @@
             app:layout_constraintBottom_toTopOf="@id/createAccountEntryFooter"
             app:layout_constraintEnd_toEndOf="@id/createAccountGutterEnd"
             app:layout_constraintStart_toStartOf="@id/createAccountGutterStart"
-            app:layout_constraintTop_toBottomOf="@id/chooseServerCardDownloadReplacementApp">
+            app:layout_constraintTop_toBottomOf="@id/createAccountNameInput">
 
             <com.google.android.material.textfield.TextInputEditText
                 android:id="@+id/createAccountEditText"
diff --git a/vector/src/main/res/xml/vector_settings_advanced_settings.xml b/vector/src/main/res/xml/vector_settings_advanced_settings.xml
index 56609fe..6f24210 100644
--- a/vector/src/main/res/xml/vector_settings_advanced_settings.xml
+++ b/vector/src/main/res/xml/vector_settings_advanced_settings.xml
@@ -81,12 +81,14 @@
 
     <im.vector.app.core.preference.VectorPreferenceCategory
         android:dependency="SETTINGS_DEVELOPER_MODE_PREFERENCE_KEY"
-        android:title="@string/settings_dev_tools">
+        android:title="@string/settings_dev_tools"
+        app:isPreferenceVisible="false">
 
         <im.vector.app.core.preference.VectorPreference
             android:persistent="false"
             android:title="@string/settings_account_data"
-            app:fragment="im.vector.app.features.settings.devtools.AccountDataFragment" />
+            app:fragment="im.vector.app.features.settings.devtools.AccountDataFragment"
+            app:isPreferenceVisible="false" />
 
         <im.vector.app.core.preference.VectorPreference
             android:persistent="false"
@@ -98,7 +100,8 @@
             android:key="SETTINGS_ACCESS_TOKEN"
             android:persistent="false"
             android:summary="@string/settings_access_token_summary"
-            android:title="@string/settings_access_token" />
+            android:title="@string/settings_access_token"
+            app:isPreferenceVisible="false" />
 
     </im.vector.app.core.preference.VectorPreferenceCategory>
 
diff --git a/vector/src/main/res/xml/vector_settings_general.xml b/vector/src/main/res/xml/vector_settings_general.xml
index 90c75f0..79ba802 100644
--- a/vector/src/main/res/xml/vector_settings_general.xml
+++ b/vector/src/main/res/xml/vector_settings_general.xml
@@ -31,7 +31,8 @@
             android:key="SETTINGS_DISCOVERY_PREFERENCE_KEY"
             android:persistent="false"
             android:summary="@string/settings_discovery_manage"
-            android:title="@string/settings_discovery_category" />
+            android:title="@string/settings_discovery_category"
+            app:isPreferenceVisible="false" />
 
         <im.vector.app.core.preference.VectorPreference
             android:key="SETTINGS_EXTERNAL_ACCOUNT_MANAGEMENT_KEY"
@@ -57,7 +58,9 @@
 
     </im.vector.app.core.preference.VectorPreferenceCategory>
 
-    <im.vector.app.core.preference.VectorPreferenceCategory android:title="@string/settings_integrations">
+    <im.vector.app.core.preference.VectorPreferenceCategory
+        android:title="@string/settings_integrations"
+        app:isPreferenceVisible="false">
 
         <im.vector.app.core.preference.VectorPreference
             android:focusable="false"
@@ -82,17 +85,20 @@
         <im.vector.app.core.preference.VectorPreference
             android:key="SETTINGS_LOGGED_IN_PREFERENCE_KEY"
             android:title="@string/settings_logged_in"
+            app:isPreferenceVisible="false"
             tools:summary="\@user:matrix.org" />
 
         <im.vector.app.core.preference.VectorPreference
             android:key="SETTINGS_HOME_SERVER_PREFERENCE_KEY"
             android:title="@string/settings_home_server"
             app:fragment="im.vector.app.features.settings.homeserver.HomeserverSettingsFragment"
+            app:isPreferenceVisible="false"
             tools:summary="https://homeserver.org" />
 
         <im.vector.app.core.preference.VectorPreference
             android:key="SETTINGS_IDENTITY_SERVER_PREFERENCE_KEY"
             android:title="@string/settings_identity_server"
+            app:isPreferenceVisible="false"
             tools:summary="https://identity.server.url" />
 
         <im.vector.app.core.preference.VectorPreference
diff --git a/vector/src/main/res/xml/vector_settings_notifications.xml b/vector/src/main/res/xml/vector_settings_notifications.xml
index 87f344f..76dce69 100644
--- a/vector/src/main/res/xml/vector_settings_notifications.xml
+++ b/vector/src/main/res/xml/vector_settings_notifications.xml
@@ -45,7 +45,8 @@
 
     <im.vector.app.core.preference.VectorPreferenceCategory
         android:key="SETTINGS_EMAIL_NOTIFICATION_CATEGORY_PREFERENCE_KEY"
-        android:title="@string/settings_notification_emails_category" />
+        android:title="@string/settings_notification_emails_category"
+        app:isPreferenceVisible="false" />
 
     <im.vector.app.core.preference.VectorPreferenceCategory
         android:persistent="false"
diff --git a/vector/src/main/res/xml/vector_settings_security_privacy.xml b/vector/src/main/res/xml/vector_settings_security_privacy.xml
index 78e1ba4..c45667c 100644
--- a/vector/src/main/res/xml/vector_settings_security_privacy.xml
+++ b/vector/src/main/res/xml/vector_settings_security_privacy.xml
@@ -36,12 +36,14 @@
             android:key="SETTINGS_ENCRYPTION_INFORMATION_DEVICE_ID_PREFERENCE_KEY"
             android:persistent="false"
             android:title="@string/device_manager_session_details_session_id"
+            app:isPreferenceVisible="false"
             tools:summary="VZRHETBEER" />
 
         <im.vector.app.core.preference.VectorPreference
             android:key="SETTINGS_ENCRYPTION_INFORMATION_DEVICE_KEY_PREFERENCE_KEY"
             android:persistent="false"
             android:title="@string/encryption_information_device_key"
+            app:isPreferenceVisible="false"
             tools:summary="3To0 8c/K VRJd 4Njb DUgv 6r8A SNp9 ETZt pMwU CpE4 XJE" />
 
         <im.vector.app.core.preference.VectorSwitchPreference
diff --git a/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/HomeserverAlias.kt b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/HomeserverAlias.kt
new file mode 100644
index 0000000..29023cc
--- /dev/null
+++ b/vector/src/main/java/im/vector/app/features/onboarding/ftueauth/HomeserverAlias.kt
@@ -0,0 +1,44 @@
+/*
+ * Topstar Chat customisation.
+ *
+ * Present homeservers under friendly aliases on the authentication UI
+ * (the "Where your conversations live" field) while the app keeps talking to
+ * the real hostnames internally:
+ *
+ *   chat1  ->  chat.hauto.store
+ *   chat2  ->  chat2.hauto.store
+ *
+ * displayName() maps a real url to its alias (for showing to the user).
+ * resolve()     maps typed input (possibly an alias) back to the real url.
+ *
+ * IMPORTANT: this is display/input sugar only. It must never be used where the
+ * real hostname is required (e.g. building a "@user:server" Matrix id).
+ */
+package im.vector.app.features.onboarding.ftueauth
+
+import im.vector.app.core.extensions.toReducedUrl
+
+object HomeserverAlias {
+
+    // alias (shown to the user) -> real host (used internally)
+    private val aliasToHost = linkedMapOf(
+            "chat1" to "chat.hauto.store",
+            "chat2" to "chat2.hauto.store",
+    )
+    private val hostToAlias = aliasToHost.entries.associate { it.value to it.key }
+
+    /** Turn a real user-facing url into its display alias, falling back to the reduced url. */
+    fun displayName(userFacingUrl: String?): String {
+        val reduced = userFacingUrl.toReducedUrl()
+        return hostToAlias[reduced.lowercase()] ?: reduced
+    }
+
+    /** Resolve typed input (possibly an alias) to the real server url. Unknown input is returned unchanged. */
+    fun resolve(input: String): String {
+        val key = input.trim()
+                .substringAfter("://")
+                .trim('/')
+                .lowercase()
+        return aliasToHost[key]?.let { "https://$it" } ?: input
+    }
+}
TOPSTAR_PATCH_EOF

echo ">> Backing up files that will be modified (into .orig if not present)..."
echo ">> Trying: git apply --3way ..."
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git apply --3way --whitespace=nowarn "$PATCH" 2>/tmp/topstar_apply.err; then
  echo "OK: applied cleanly with git apply --3way."
elif git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git apply --reject --whitespace=nowarn "$PATCH" 2>>/tmp/topstar_apply.err; then
  echo "PARTIAL: git apply --reject used. Check for *.rej files:"
  find . -name '*.rej' -newermt '-2 minutes' 2>/dev/null
else
  echo ">> git apply failed, falling back to patch(1) with fuzz..."
  if patch -p1 --forward --fuzz=3 < "$PATCH"; then
    echo "OK: applied with patch --fuzz=3 (check for .rej files)."
    find . -name '*.rej' -newermt '-2 minutes' 2>/dev/null
  else
    echo "ERROR: automatic apply failed. See /tmp/topstar_apply.err and any *.rej files." >&2
    echo "       The clean tree may differ too much; apply the changes manually from the patch." >&2
    exit 2
  fi
fi

echo ""
echo ">> DONE. Review the changes:  git -C \"$TARGET\" status  &&  git -C \"$TARGET\" diff"
echo ">> Then rebuild the clean Topstar AAB/APK the way that session normally does."
