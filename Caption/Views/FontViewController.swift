//
//  FontViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/10/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class FontViewController: NSViewController {
    weak var episode: EpisodeProject?
    @IBOutlet weak var videoName: NSTextField!
    @IBOutlet weak var videoPath: NSTextField!
    @IBOutlet weak var videoDurationField: NSTextField!
    @IBOutlet weak var videoFramerateField: NSTextField!

    @IBOutlet weak var fontFamilyButton: NSPopUpButton!
    @IBOutlet weak var fontWeightButton: NSPopUpButton!
    @IBOutlet weak var fontSizeButton: NSComboBox!
    @IBOutlet weak var fontShadowButton: NSPopUpButton!
    var fontColorButton: Any?
//    @IBOutlet weak var fontColorButton: ComboColorWell!
    @IBOutlet weak var colorContainerView: NSView!

    let allFontNames = NSFontManager.shared.availableFontFamilies
    var fontPostScriptArray: [String] = []
    let allFontSizes = [24, 36, 48, 53, 64, 72, 96]

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(OSX 10.12, *) {
            let button = ComboColorWell(frame: NSRect(x: 0, y: 0, width: 80, height: 23))
            fontColorButton = button
            button.target = self
            button.action = #selector(colorChanged(_:))
            self.colorContainerView.addSubview(button)
        } else {
            let well = NSColorWell(frame: NSRect(x: 0, y: 0, width: 80, height: 23))
            fontColorButton = well
            well.target = self
            well.action = #selector(colorChanged(_:))
            self.colorContainerView.addSubview(well)
        }
        configurateAllFonts()
    }

    func dismantleOldFontVC() {
        if episode != nil {
            episode?.safelyRemoveObserver(self, forKeyPath: "videoDescription")
            episode?.safelyRemoveObserver(self, forKeyPath: "videoURL")
            episode?.safelyRemoveObserver(self, forKeyPath: "videoDuration")
            episode?.safelyRemoveObserver(self, forKeyPath: "framerate")
        }
    }

    func configurateFontVC() {
        restoreFontSettings()
//        episode.addObserver(self, forKeyPath: "videoDescription", options: [.new], context: nil)
//        episode.addObserver(self, forKeyPath: "videoURL", options: [.new], context: nil)
//        episode.addObserver(self, forKeyPath: "videoDuration", options: [.new], context: nil)
//        episode.addObserver(self, forKeyPath: "framerate", options: [.new], context: nil)
        configureAllMetadata()
    }

    func configureAllMetadata() {
        if let up = episode?.videoURL {
            let url = URL(fileURLWithPath: up)
            self.videoName.stringValue = url.lastPathComponent
            self.videoPath.stringValue = url.path
        } else {
            self.videoName.stringValue = ""
            self.videoPath.stringValue = ""
        }
        self.videoDurationField.stringValue = "\(episode?.videoDuration ?? 0) seconds"
        self.videoFramerateField.stringValue = "\(episode?.framerate ?? 0) fps"
    }

    private static var metadataObserverContext = 2

//    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//        guard context == &FontViewController.metadataObserverContext else {
//            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
//            return
//        }
//        self.configureAllMetadata()
//    }

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
            self.episode?.styleFontWeight = fontWeightButton.title
        }
    }

    func restoreFontSettings() {
        fontFamilyButton.selectItem(withTitle: self.episode?.styleFontFamily ?? "Helvetica")
        updateSubFamily(saveNewSelection: false)
        fontWeightButton.selectItem(withTitle: self.episode?.styleFontWeight ?? "Regular")
        fontSizeButton.stringValue = self.episode?.styleFontSize ?? "53"
        fontShadowButton.selectItem(at: Int(self.episode?.styleFontShadow ?? 1))
        if #available(OSX 10.12, *) {
            if let well = fontColorButton as? ComboColorWell {
                well.color = NSColor(hexString: self.episode?.styleFontColor ?? "#ffffff") ?? NSColor.white
            }
        } else {
            if let well = fontColorButton as? NSColorWell {
                well.color = NSColor(hexString: self.episode?.styleFontColor ?? "#ffffff") ?? NSColor.white
            }
        }
    }

    @IBAction func fontNameChanged(_ sender: NSPopUpButton) {
        updateSubFamily(saveNewSelection: true)
        self.episode?.styleFontFamily = sender.title
    }

    @IBAction func fontSubFamilyChanged(_ sender: NSPopUpButton) {
        self.episode?.styleFontWeight = sender.title
    }

    @IBAction func fontSizeChanged(_ sender: NSComboBox) {
        self.episode?.styleFontSize = sender.stringValue
    }

    @IBAction func shadowChanged(_ sender: NSPopUpButton) {
        self.episode?.styleFontShadow = Int16(sender.indexOfSelectedItem)
    }

    @IBAction func colorChanged(_ sender: Any) {
        if #available(OSX 10.12, *) {
            if let well = sender as? ComboColorWell {
                self.episode?.styleFontColor = well.color.hexString
            }
        } else {
            if let well = sender as? NSColorWell {
                self.episode?.styleFontColor = well.color.hexString
            }
        }
    }

}
