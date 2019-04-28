//
//  CaptionWaveformBox.swift
//  Quick Caption
//
//  Created by Blue on 3/18/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionWaveformBox: NSBox {
    var guid: String?

    func addSubWaveformView(capturedGUID: String?, imageView: NSImageView) {
        if let cap = capturedGUID {
            if (self.guid == cap) {
                self.contentView!.addSubview(imageView)
            } else {
                #if DEBUG
                print("Rejecting waveform from GUID:\(capturedGUID ?? "")")
                #endif
            }
        }
    }
}
