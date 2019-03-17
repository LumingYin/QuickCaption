//
//  TimelineOverallView.swift
//  Quick Caption
//
//  Created by Blue on 3/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class TimelineOverallView: NSView {
    // MARK: - Keyboard Handling
    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 49 && event.characters == " " {
            AppDelegate.movieVC()?.playPauseClicked(self)
        } else {
            interpretKeyEvents([event])
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

}
