//
//  VideoPreviewContainerView.swift
//  Quick Caption
//
//  Created by Blue on 3/17/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class VideoPreviewContainerView: NSView {
    var guid: String?

    func addSubImageView(capturedGUID: String?, imageView: VideoPreviewImageView) {
        if let cap = capturedGUID {
            if (self.guid == cap && self.guid == imageView.correspondingGUID) {
                self.addSubview(imageView)
            }
        }
    }

}

class VideoPreviewImageView: NSImageView {
    var correspondingGUID: String?
}
