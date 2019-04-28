//
//  QuickCaptionWindow.swift
//  Quick Caption
//
//  Created by Blue on 3/17/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class QuickCaptionWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        #if DEBUG
        print("Intercepted keyDown: \(event)")
        #endif
        if event.keyCode == 49 && event.characters == " " {
            AppDelegate.movieVC()?.playPauseClicked(self)
        } else {
            super.keyDown(with: event)
        }
    }
}
