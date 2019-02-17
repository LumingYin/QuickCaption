//
//  CaptionWindowController.swift
//  Quick Caption
//
//  Created by Blue on 2/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionWindowController: NSWindowController, NSWindowDelegate {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldCascadeWindows = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        shouldCascadeWindows = true
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        self.window?.delegate = self
        shouldCascadeWindows = true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let vc = self.contentViewController as? ViewController {
            if (vc.player != nil) {
                let response = vc.dialogTwoButton(question: "Save Captions?", text: "Would you like to save your captions before closing?")
                print(response)
                if response {
                    vc.saveToDisk(.srt)
                }
            }
        }
        return true
    }

}
