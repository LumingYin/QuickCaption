//
//  CaptionBoxView.swift
//  Quick Caption
//
//  Created by Blue on 3/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionBoxView: NSView {
    var captionText: String = "Caption"
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.blue.setFill()
        dirtyRect.fill()
        NSColor.white.setStroke()
        NSBezierPath.stroke(bounds)
        // Drawing code here.
    }
    
}
