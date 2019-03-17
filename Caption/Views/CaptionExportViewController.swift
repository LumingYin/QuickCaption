//
//  CaptionExportViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionExportViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }


    @IBAction func exportSRTClicked(_ sender: Any) {
        AppDelegate.movieVC()?.saveSRTToDisk(self)
    }

    @IBAction func exportFCPXMLClicked(_ sender: Any) {
        AppDelegate.movieVC()?.saveFCPXMLToDisk(self)
    }

    @IBAction func exportTXTClicked(_ sender: Any) {
        AppDelegate.movieVC()?.saveTXTToDisk(self)
    }

}
