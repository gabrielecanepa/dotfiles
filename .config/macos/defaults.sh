defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true
defaults write -g AppleIconAppearanceTheme -string RegularAutomatic
defaults write -g AppleReduceDesktopTinting -bool true
defaults write -g AppleAntiAliasingThreshold -int 4
defaults write -g AppleScrollerPagingBehavior -bool true
defaults write -g CGDisableCursorLocationMagnification -bool true
defaults write -g AppleActionOnDoubleClick -string Maximize
defaults write -g AppleMiniaturizeOnDoubleClick -bool false
defaults write -g AppleWindowTabbingMode -string fullscreen
defaults write -g NSQuitAlwaysKeepsWindows -bool true
defaults write -g NSCloseAlwaysConfirmsChanges -bool true
defaults write com.apple.WindowManager GloballyEnabled -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager AppWindowGroupingBehavior -int 1
defaults write com.apple.WindowManager StandardHideDesktopIcons -bool true
defaults write com.apple.WindowManager StandardHideWidgets -bool false
defaults write com.apple.WindowManager StageManagerHideWidgets -bool false
defaults write com.apple.WindowManager HideDesktop -bool true
defaults write com.apple.WindowManager AutoHide -bool true
defaults write com.apple.ActivityMonitor ShowCategory -int 100
defaults write com.apple.ActivityMonitor SelectedTab -int 1
defaults write com.apple.ActivityMonitor DisplayType -int 0
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit AddExtensionToNewPlainTextFiles -bool false
defaults write com.apple.TextEdit SmartQuotes -bool false
defaults write com.apple.TextEdit SmartDashes -bool false
defaults write com.apple.TextEdit TextReplacement -bool false
defaults write com.apple.TextEdit CheckSpellingWhileTyping -bool false
defaults write com.apple.TextEdit CorrectSpellingAutomatically -bool false
defaults write com.apple.TextEdit IgnoreRichText -bool true
defaults write com.apple.TextEdit IgnoreHTML -bool true
defaults write com.apple.TextEdit NSFont -string Menlo-Regular
defaults write com.apple.TextEdit NSFontSize -int 14
defaults write com.apple.TextEdit NSFixedPitchFont -string Monaco
defaults write com.apple.TextEdit NSFixedPitchFontSize -int 14
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari EnableNarrowTabs -bool true
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool false
defaults write com.apple.Safari ShowOverlayStatusBar -bool false
defaults write com.apple.Safari ShowSidebarInNewWindows -bool false
defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool true
defaults write com.apple.Safari NewWindowBehavior -int 4
defaults write com.apple.Safari NewTabBehavior -int 4
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.mail PollTime -int -1
defaults write com.apple.mail ThreadingDefault -bool true
defaults write com.apple.mail MailShowFlags -bool true
defaults write com.apple.mail ShowCcHeader -bool true
defaults write com.apple.mail ShowBccHeader -bool false
defaults write com.apple.mail ShowReplyToHeader -bool false
defaults write com.apple.mail ShowPriorityControl -bool false
defaults write com.apple.mail SuppressDeliveryFailure -bool true
defaults write com.apple.mail IndexJunk -bool false
defaults write com.apple.mail IndexTrash -bool false
defaults write com.apple.mail IndexDecryptedMessages -bool false
defaults write com.apple.mail NSFont -string Helvetica
defaults write com.apple.mail NSFontSize -int 12
defaults write com.apple.mail NSFixedPitchFont -string Menlo-Regular
defaults write com.apple.mail NSFixedPitchFontSize -int 11
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -float 63
defaults write com.apple.dock magnification -bool true
defaults write com.apple.dock largesize -float 76
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.2
defaults write com.apple.dock mineffect -string genie
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-process-indicators -bool true
defaults write com.apple.dock showhidden -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false
defaults write com.apple.dock expose-group-apps -bool true
defaults write com.apple.dock showAppExposeGestureEnabled -bool false
defaults write com.apple.dock wvous-bl-corner -int 5
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowSidebar -bool true
defaults write com.apple.finder ShowPreviewPane -bool false
defaults write com.apple.finder ShowRecentTags -bool false
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
defaults write com.apple.finder FXPreferredSearchViewStyle -string Nlsv
defaults write com.apple.finder FXDefaultSearchScope -string SCsp
defaults write com.apple.finder FXArrangeGroupViewBy -string Name
defaults write com.apple.finder FXPreferredGroupBy -string None
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
defaults write com.apple.finder _FXEnableColumnAutoSizing -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder NewWindowTarget -string PfHm
defaults write com.apple.screencapture location -string "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
defaults write com.apple.screencapture location-screenshot -string "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
defaults write com.apple.screencapture location-screenrecording -string "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture target -string file
defaults write com.apple.screencapture style -string window
defaults write com.apple.screencapture show-thumbnail -bool true
defaults write com.apple.screencapture showsClicks -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g AppleKeyboardUIMode -int 0
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool true
defaults write -g NSUserKeyEquivalents -dict-add "System Settings..." '@~^,'
defaults write com.apple.HIToolbox AppleFnUsageType -int 3
defaults write com.apple.HIToolbox AppleDictationAutoEnable -int 1
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool false
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
defaults write com.apple.AppleMultitouchTrackpad TrackpadHandResting -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadMomentumScroll -bool true
defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadTwoFingerFromRightEdgeSwipeGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadHandResting -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadMomentumScroll -bool true
defaults write -g com.apple.trackpad.forceClick -bool false
defaults write -g com.apple.trackpad.scaling -float 3
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string OneButton
defaults write com.apple.AppleMultitouchMouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.AppleMultitouchMouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string OneButton
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseOneFingerDoubleTapGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerDoubleTapGesture -int 3
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseTwoFingerHorizSwipeGesture -int 2
defaults write -g com.apple.sound.beep.feedback -int 0
defaults write -g com.apple.sound.beep.flash -int 0
defaults write -g com.apple.sound.beep.sound -string /System/Library/Sounds/Tink.aiff
defaults write -g com.apple.sound.beep.volume -float 1
defaults write -g _HIHideMenuBar -bool false
defaults write -g AppleMenuBarVisibleInFullscreen -bool false
defaults write com.apple.controlcenter AutoHideMenuBarOption -int 2
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock ShowSeconds -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -int 0
defaults write com.apple.menuextra.clock FlashDateSeparators -bool true
defaults -currentHost write com.apple.controlcenter Battery -int 1
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
defaults -currentHost write com.apple.controlcenter BatteryShowEnergyMode -bool true
defaults -currentHost write com.apple.controlcenter Sound -int 18
defaults -currentHost write com.apple.controlcenter NowPlaying -int 2
defaults -currentHost write com.apple.controlcenter WiFi -int 2
defaults -currentHost write com.apple.controlcenter Bluetooth -int 2
defaults -currentHost write com.apple.controlcenter Display -int 2
defaults -currentHost write com.apple.controlcenter FocusModes -int 2
defaults -currentHost write com.apple.controlcenter ScreenMirroring -int 2
defaults -currentHost write com.apple.controlcenter Weather -int 2
defaults -currentHost write com.apple.controlcenter KeyboardBrightness -int 4
defaults -currentHost write com.apple.controlcenter UserSwitcher -int 4
defaults -currentHost write com.apple.controlcenter MusicRecognition -int 9
defaults -currentHost write com.apple.controlcenter AccessibilityShortcuts -int 8
defaults -currentHost write com.apple.controlcenter AirDrop -int 8
defaults -currentHost write com.apple.controlcenter Siri -int 8
defaults -currentHost write com.apple.controlcenter StageManager -int 8
defaults -currentHost write com.apple.controlcenter TimeMachine -int 8
defaults -currentHost write com.apple.controlcenter VPN -int 8
defaults -currentHost write com.apple.controlcenter VoiceControl -int 8
defaults -currentHost write com.apple.controlcenter ShowSuggestions -bool true
defaults write com.apple.Siri TypeToSiriEnabled -bool true
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool true
defaults write com.apple.Siri ConfirmSiriInvokedViaEitherCmdTwice -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.assistant.support "Dictation Enabled" -bool true
defaults write com.apple.assistant.support "Siri Data Sharing Opt-In Status" -int 2
defaults write com.apple.assistant.support "Search Queries Data Sharing Status" -int 2
defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
defaults -currentHost write com.apple.screensaver idleTime -int 0
defaults -currentHost write com.apple.screensaver showClock -bool false
if ! defaults read -g NSUserDictionaryReplacementItems >/dev/null 2>&1; then
	defaults write -g NSUserDictionaryReplacementItems -array \
		'{ on = 1; replace = ":)"; with = "🙂"; }' \
		'{ on = 1; replace = ":("; with = "😞"; }' \
		'{ on = 1; replace = ";)"; with = "😉"; }' \
		'{ on = 1; replace = ":D"; with = "😄"; }' \
		'{ on = 1; replace = "<3"; with = "❤️"; }' \
		'{ on = 1; replace = ":joy:"; with = "😂"; }' \
		'{ on = 1; replace = ":hello:"; with = "👋"; }' \
		'{ on = 1; replace = ":ok:"; with = "👍"; }' \
		'{ on = 1; replace = ":+1:"; with = "👍"; }' \
		'{ on = 1; replace = ":done:"; with = "✅"; }' \
		'{ on = 1; replace = ":check:"; with = "✔️"; }' \
		'{ on = 1; replace = "kisskiss"; with = "😘😘"; }' \
		'{ on = 1; replace = ":it:"; with = "🇮🇹"; }' \
		'{ on = 1; replace = ":es:"; with = "🇪🇸"; }' \
		'{ on = 1; replace = ":fr:"; with = "🇫🇷"; }' \
		'{ on = 1; replace = ":pt:"; with = "🇵🇹"; }' \
		'{ on = 1; replace = ":gb:"; with = "🇬🇧"; }' \
		'{ on = 1; replace = ":ma:"; with = "🇲🇦"; }' \
		'{ on = 1; replace = "=/"; with = "≠"; }' \
		'{ on = 1; replace = "->>"; with = "→"; }' \
		'{ on = 1; replace = "<-"; with = "←"; }' \
		'{ on = 1; replace = "<->"; with = "↔︎"; }' \
		'{ on = 1; replace = "E'"'"'"; with = "È"; }' \
		'{ on = 1; replace = "gia"; with = "già"; }' \
		'{ on = 1; replace = "piu"; with = "più"; }' \
		"{ on = 1; replace = \"po\"; with = \"po'\"; }" \
		"{ on = 1; replace = \"dovee\"; with = \"dov’è \"; }" \
		"{ on = 1; replace = \"Im\"; with = \"I’m\"; }"
fi
