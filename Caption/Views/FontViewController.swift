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
    @IBOutlet weak var fontSizeButton: NSComboBox!
    @IBOutlet weak var fontShadowButton: NSPopUpButton!
    @IBOutlet weak var fontColorButton: NSColorWell!

    let allFontNames = NSFontManager.shared.availableFontFamilies
    var fontPostScriptArray: [String] = []
    let allFontSizes = [24, 36, 48, 53, 64, 72, 96]

    override func viewDidLoad() {
        super.viewDidLoad()
        configurateAllFonts()
    }

    func dismantleOldFontVC() {
        episode.safelyRemoveObserver(self, forKeyPath: "videoDescription")
        episode.safelyRemoveObserver(self, forKeyPath: "videoURL")
        episode.safelyRemoveObserver(self, forKeyPath: "videoDuration")
        episode.safelyRemoveObserver(self, forKeyPath: "framerate")
    }

    func configurateFontVC() {
        restoreFontSettings()
        episode.addObserver(self, forKeyPath: "videoDescription", options: [.new], context: nil)
        episode.addObserver(self, forKeyPath: "videoURL", options: [.new], context: nil)
        episode.addObserver(self, forKeyPath: "videoDuration", options: [.new], context: nil)
        episode.addObserver(self, forKeyPath: "framerate", options: [.new], context: nil)
        configureAllMetadata()
    }

    func configureAllMetadata() {
        self.videoName.stringValue = episode.videoURL?.lastPathComponent ?? ""
        self.videoPath.stringValue = episode.videoURL?.absoluteString ?? ""
        self.videoDurationField.stringValue = "\(episode.videoDuration) seconds"
        self.videoFramerateField.stringValue = "\(episode.framerate) fps"
    }

    private static var metadataObserverContext = 2

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &FontViewController.metadataObserverContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        self.configureAllMetadata()
    }

    func configurateAllFonts() {
        fontFamilyButton.removeAllItems()
        fontFamilyButton.addItems(withTitles: allFontNames)

        updateSubFamily(saveNewSelection: false)
        fontSizeButton.removeAllItems()
        fontSizeButton.addItems(withObjectValues: allFontSizes)
        fontSizeButton.selectItem(at: 3)
    }

    func updateSubFamily(saveNewSelection: Bool) {
        fontWeightButton.removeAllItems()
        if let selectedFamily = fontFamilyButton.titleOfSelectedItem {
            if let arrayofSubs = NSFontManager.shared.availableMembers(ofFontFamily: selectedFamily)  {
                var resultingSub:[String] = []
                fontPostScriptArray = []
                for i in 0..<arrayofSubs.count {
                    if let nameOfSubFamily = arrayofSubs[i][1] as? String {
                        resultingSub.append(nameOfSubFamily)
                    }
                    if let nameOfPostScript = arrayofSubs[i][0] as? String {
                        fontPostScriptArray.append(nameOfPostScript)
                    }
                }
                fontWeightButton.addItems(withTitles: resultingSub)
            }
        }
        if saveNewSelection {
            self.episode.styleFontWeight = fontWeightButton.title
        }
    }

    func restoreFontSettings() {
        fontFamilyButton.selectItem(withTitle: self.episode.styleFontFamily ?? "Helvetica")
        updateSubFamily(saveNewSelection: false)
        fontWeightButton.selectItem(withTitle: self.episode.styleFontWeight ?? "Regular")
        fontSizeButton.stringValue = self.episode.styleFontSize ?? "53"
        fontShadowButton.selectItem(at: Int(self.episode.styleFontShadow))
        fontColorButton.color = NSColor(hexString: self.episode.styleFontColor ?? "#ffffff") ?? NSColor.white
    }

    @IBAction func fontNameChanged(_ sender: NSPopUpButton) {
        updateSubFamily(saveNewSelection: true)
        self.episode.styleFontFamily = sender.title
    }

    @IBAction func fontSubFamilyChanged(_ sender: NSPopUpButton) {
        self.episode.styleFontWeight = sender.title
    }

    @IBAction func fontSizeChanged(_ sender: NSComboBox) {
        self.episode.styleFontSize = sender.stringValue
    }

    @IBAction func shadowChanged(_ sender: NSPopUpButton) {
        self.episode.styleFontShadow = Int16(sender.indexOfSelectedItem)
    }

    @IBAction func colorChanged(_ sender: NSColorWell) {
        self.episode.styleFontColor = sender.color.hexString
    }

}
