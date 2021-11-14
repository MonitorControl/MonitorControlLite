//  Copyright © MonitorControlLite. @waydabber

enum PrefKey: String {
  /* -- App-wide settings -- */

  // Build number
  case buildNumber

  // Was the app launched once
  case appAlreadyLaunched

  // Hide menu icon
  case menuIcon

  // Menu item style
  case menuItemStyle

  // Keys listened for
  case keyboardBrightness

  // Do not show sliders for Apple displays (including built-in display) in menu
  case hideAppleFromMenu

  // Disable slider snapping
  case enableSliderSnap

  // Disable slider snapping
  case enableSliderPercent

  // Show tick marks for sliders
  case showTickMarks

  // Instead of assuming default values, enable write upon startup
  case startupAction

  // Allow zero software brightness
  case allowZeroSwBrightness

  // Keyboard brightness control for multiple displays
  case multiKeyboardBrightness

  // Use fine OSD scale for brightness
  case useFineScaleBrightness

  // Use smoothBrightness
  case disableSmoothBrightness

  // Sliders for multiple displays
  case multiSliders

  /* -- Display specific settings */

  // Display should avoid gamma table manipulation and use shades instead (to coexist with other apps doing gamma manipulation)
  case avoidGamma

  // Display disabled for keyboard control
  case isDisabled

  // Software brightness for display
  case SwBrightness

  // Friendly name
  case friendlyName

  /* -- Display+Command specific settings -- */

  // Command value display
  case value
}

enum MultiKeyboardBrightness: Int {
  case mouse = 0
  case allScreens = 1
  case focusInsteadOfMouse = 2
}

enum StartupAction: Int {
  case doNothing = 0
  case write = 1
}

enum MultiSliders: Int {
  case separate = 0
  case relevant = 1
  case combine = 2
}

enum MenuIcon: Int {
  case show = 0
  case hide = 2
}

enum MenuItemStyle: Int {
  case text = 1
  case icon = 0
  case hide = 2
}

enum KeyboardBrightness: Int {
  case disabled = 0
  case custom = 3
}
