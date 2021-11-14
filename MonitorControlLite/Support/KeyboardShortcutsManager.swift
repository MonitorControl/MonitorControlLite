//  Copyright © MonitorControlLite. @waydabber

import Foundation
import KeyboardShortcuts
import os.log

class KeyboardShortcutsManager {
  var initialKeyRepeat = 0.21
  var keyRepeat = 0.028
  var keyRepeatCount = 0
  var currentCommand = KeyboardShortcuts.Name.none
  var isFirstKeypress = false
  var currentEventId = 0
  var isHold = false

  init() {
    KeyboardShortcuts.onKeyDown(for: .brightnessUp) { [self] in
      self.engage(KeyboardShortcuts.Name.brightnessUp)
    }
    KeyboardShortcuts.onKeyDown(for: .brightnessDown) { [self] in
      self.engage(KeyboardShortcuts.Name.brightnessDown)
    }
    KeyboardShortcuts.onKeyUp(for: .brightnessUp) { [self] in
      disengage()
    }
    KeyboardShortcuts.onKeyUp(for: .brightnessDown) { [self] in
      disengage()
    }
  }

  func engage(_ shortcut: KeyboardShortcuts.Name) {
    self.initialKeyRepeat = max(15, UserDefaults.standard.double(forKey: "InitialKeyRepeat")) * 0.014
    self.keyRepeat = max(2, UserDefaults.standard.double(forKey: "KeyRepeat")) * 0.014
    self.currentCommand = shortcut
    self.isFirstKeypress = true
    self.isHold = true
    self.currentEventId += 1
    self.keyRepeatCount = 0
    self.apply(shortcut, eventId: self.currentEventId)
  }

  func disengage() {
    self.isHold = false
    self.isFirstKeypress = false
    self.currentCommand = KeyboardShortcuts.Name.none
    self.keyRepeatCount = 0
  }

  func apply(_ shortcut: KeyboardShortcuts.Name, eventId: Int) {
    guard app.sleepID == 0, app.reconfigureID == 0, self.keyRepeatCount <= 100 else {
      self.disengage()
      return
    }
    guard self.currentCommand == shortcut, self.isHold, eventId == self.currentEventId else {
      return
    }
    if self.isFirstKeypress {
      self.isFirstKeypress = false
      DispatchQueue.main.asyncAfter(deadline: .now() + self.initialKeyRepeat) {
        self.apply(shortcut, eventId: eventId)
      }
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + self.keyRepeat) {
        self.apply(shortcut, eventId: eventId)
      }
    }
    self.keyRepeatCount += 1
    switch shortcut {
    case KeyboardShortcuts.Name.brightnessUp: self.brightness(isUp: true)
    case KeyboardShortcuts.Name.brightnessDown: self.brightness(isUp: false)
    default: break
    }
  }

  func brightness(isUp: Bool) {
    guard let affectedDisplays = DisplayManager.shared.getAffectedDisplays(isBrightness: true), [KeyboardBrightness.custom.rawValue].contains(prefs.integer(forKey: PrefKey.keyboardBrightness.rawValue)) else {
      self.disengage()
      return
    }
    for display in affectedDisplays where !display.readPrefAsBool(key: .isDisabled) {
      display.stepBrightness(isUp: isUp, isSmallIncrement: prefs.bool(forKey: PrefKey.useFineScaleBrightness.rawValue))
    }
  }
}
