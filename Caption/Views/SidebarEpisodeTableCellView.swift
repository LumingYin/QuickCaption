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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }

}
