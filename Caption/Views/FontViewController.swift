//
//  FontViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/10/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class FontViewController: NSViewController {
    weak var episode: EpisodeProject!
    @IBOutlet weak var videoName: NSTextField!
    @IBOutlet weak var videoPath: NSTextField!
    @IBOutlet weak var videoDurationField: NSTextField!
    @IBOutlet weak var videoFramerateField: NSTextField!

    @IBOutlet weak var fontFamilyButton: NSPopUpButton!
    @IBOutlet weak var fontWeightButton: NSPopUpButton!
    @IBOutlet weak var fontSizeButton: NSPopUpButton!
    @IBOutlet weak var fontShadowButton: NSPopUpButton!
    @IBOutlet weak var fontColorButton: NSColorWell!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configurateFontVC() {
        self.videoName.stringValue = episode.videoURL?.lastPathComponent ?? ""
        self.videoPath.stringValue = episode.videoURL?.absoluteString ?? ""
        self.videoDurationField.stringValue = "\(episode.videoDuration) seconds"
        self.videoFramerateField.stringValue = "\(episode.framerate) fps"
    }
}
