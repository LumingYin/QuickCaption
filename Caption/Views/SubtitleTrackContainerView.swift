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
    }

    override func mouseMoved(with event: NSEvent) {
        delegate?.checkForCaptionDirectManipulation(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.trackingMouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        delegate?.trackingMouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        delegate?.trackingMouseUp(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        delegate?.commonCursorReturn()
    }

}

protocol SubtitleTrackContainerViewDelegate {
    func checkForCaptionDirectManipulation(with event: NSEvent)
    func trackingMouseUp(with event: NSEvent)
    func trackingMouseDown(with event: NSEvent)
    func trackingMouseDragged(with event: NSEvent)
    func commonCursorReturn()
    
}
