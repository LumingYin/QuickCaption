//
//  TimelineOverallView.swift
//  Quick Caption
//
//  Created by Blue on 3/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class TimelineOverallView: NSView {
    override func awakeFromNib() {
        let nc =  NotificationCenter.default
        nc.addObserver(self, selector: #selector(scrollViewWillStartLiveScroll(notification:)), name: NSScrollView.willStartLiveScrollNotification, object: nil)
        nc.addObserver(self, selector: #selector(scrollViewDidLiveScroll(notification:)), name: NSScrollView.didLiveScrollNotification, object: nil)
        nc.addObserver(self, selector: #selector(scrollViewDidEndLiveScroll(notification:)), name: NSScrollView.didEndLiveScrollNotification, object: nil)
    }

    var scrollViewIsScrolling = false

    @objc func scrollViewWillStartLiveScroll(notification: Notification){
        scrollViewIsScrolling = true
        #if DEBUG
        print("scrollViewWillStartLiveScroll: \(#function) ")
        #endif
    }

    @objc func scrollViewDidLiveScroll(notification: Notification){
        scrollViewIsScrolling = true
        #if DEBUG
        // print("scrollViewDidLiveScroll: \(#function) ")
        #endif
    }

    @objc func scrollViewDidEndLiveScroll(notification: Notification){
        scrollViewIsScrolling = false
        #if DEBUG
        print("scrollViewDidEndLiveScroll: \(#function) ")
        #endif
    }

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
