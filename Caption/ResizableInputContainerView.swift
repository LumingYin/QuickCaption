//
//  ResizableInputContainerView.swift
//  Quick Caption
//
//  Created by Blue on 3/10/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class ResizableInputContainerView: NSView {

    var hasConfigured: Bool = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if !hasConfigured {
            configure()
        }
    }

    func configure() {
        for view in self.subviews {
            if view.tag != 1 && self.frame.width > 140 {
                view.setFrameSize(NSSize(width: self.frame.width - 130, height: view.frame.height))
            }
        }
    }
    
}
