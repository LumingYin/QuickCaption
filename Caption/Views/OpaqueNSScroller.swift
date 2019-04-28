//
//  OpaqueNSScroller.swift
//  Quick Caption
//
//  Created by Blue on 4/28/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class OpaqueNSScroller: NSScroller {
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.setFill()
        dirtyRect.fill()
        // whatever style you want here for knob if you want
        knobStyle = .dark
    }
}
