//
//  QuickCaptionWindow.swift
//  Quick Caption
//
//  Created by Blue on 3/17/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

@objc(QuickCaptionApplication)
class QuickCaptionApplication: NSApplication {
//    override func insertText(_ insertString: Any) {
//        if let str = insertString as? String, let window = self.mainWindow {
//            if str == " " {
//                if let fakeEvent = NSEvent.keyEvent(with: .keyDown, location: window.mouseLocationOutsideOfEventStream, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: NSGraphicsContext.current, characters: " ", charactersIgnoringModifiers: " ", isARepeat: false, keyCode: 49) {
//                    NSApp.mainMenu?.performKeyEquivalent(with: fakeEvent)
//                } else {
//                    super.insertText(insertString)
//                }
//            } else {
//                super.insertText(insertString)
//            }
//        } else {
//            super.insertText(insertString)
//        }
//    }
//
//    override func performKeyEquivalent(with event: NSEvent) -> Bool {
//        return super.performKeyEquivalent(with: event)
//    }
}
