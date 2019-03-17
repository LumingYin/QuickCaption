//
//  SubtitleTrackContainerView.swift
//  Quick Caption
//
//  Created by Blue on 3/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class SubtitleTrackContainerView: NSView {
    var delegate: SubtitleTrackContainerViewDelegate?
    var trackingArea: NSTrackingArea?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func awakeFromNib() {
        
    }

    func startTracking() {
        trackingArea = NSTrackingArea.init(rect: self.bounds, options: [.mouseEnteredAndExited, .activeAlways, .mouseMoved], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    func stopTracking() {
        if (trackingArea != nil) {
            self.removeTrackingArea(trackingArea!)
            trackingArea = nil
            self.delegate = nil
        }
    }

    override func mouseEntered(with event: NSEvent) {
//        print(event)
    }

    override func mouseMoved(with event: NSEvent) {
//        print(event)
        delegate?.checkForCaptionDirectManipulation(with: event)
    }

    override func mouseDown(with event: NSEvent) {
//        print(event)
    }

    override func mouseDragged(with event: NSEvent) {
//        print(event)
    }

    override func mouseUp(with event: NSEvent) {
//        print(event)
    }

    override func mouseExited(with event: NSEvent) {
//        print(event)
    }



}

protocol SubtitleTrackContainerViewDelegate {
    func checkForCaptionDirectManipulation(with event: NSEvent)
}
