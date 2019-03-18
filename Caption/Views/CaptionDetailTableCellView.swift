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
    var delegate: CaptionDetailTableCellViewDelegate?

//    override func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//        // Drawing code here.
//    }

    @IBAction func textFieldEdited(_ sender: Any) {
        delegate?.textFieldEdited(self)
    }

}

protocol CaptionDetailTableCellViewDelegate {
    func textFieldEdited(_ sender: Any)
}
