//
//  CaptionDetailTableCellView.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionDetailTableCellView: NSTableCellView {
    @IBOutlet weak var startTimeField: NSTextField!
    @IBOutlet weak var endTimeField: NSTextField!
    @IBOutlet var captionContentTextField: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
