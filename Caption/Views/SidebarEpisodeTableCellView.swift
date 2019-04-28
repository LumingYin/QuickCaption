//
//  SidebarEpisodeTableCellView.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class SidebarEpisodeTableCellView: NSTableCellView {
    @IBOutlet var episodePreview: NSImageView!
    @IBOutlet weak var videoFileNameTextField: NSTextField!
    @IBOutlet weak var lastModifiedDateTextField: NSTextField!

    override func awakeFromNib() {
        if #available(macOS 10.14, *) {
        } else {
            videoFileNameTextField.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        willSet {
            if newValue == .dark {
                videoFileNameTextField.textColor = NSColor.white
                lastModifiedDateTextField.textColor = NSColor.white
            } else {
                videoFileNameTextField.textColor = NSColor.labelColor
                lastModifiedDateTextField.textColor = NSColor.labelColor
            }
        }
    }


}
