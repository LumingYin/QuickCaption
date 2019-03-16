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

        NSColor(red: 63 / 255, green: 34 / 255, blue: 114 / 255, alpha: 1.0).setFill()
        NSColor.white.setStroke()
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 5, yRadius: 5)

        path.stroke()
        path.fill()

        (captionText as NSString).drawLeftAligned(in: bounds, withAttributes: [.foregroundColor: NSColor(red: 179 / 255, green: 152 / 255, blue: 233 / 255, alpha: 1.0)])
        // Drawing code here.
    }
    
}
