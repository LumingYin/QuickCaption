//
//  ViewController.swift
//  Caption
//
//  Created by Bright on 7/29/17.
//  Copyright © 2017 Bright. All rights reserved.
//

import Cocoa
import AVKit
import AVFoundation

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

    @IBOutlet weak var transcribeTextField: NSTextField!
    @IBOutlet weak var resultTableView: NSTableView!
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var timeLabel: NSTextField!
    
    var videoDescription: String = ""
    var player: AVPlayer?
    var videoURL: URL?
    var arrayForCaption: [CaptionLine] = []
    
    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        resultTableView.delegate = self
        resultTableView.dataSource = self
        transcribeTextField.delegate = self
    }
    
    // MARK: - TextField Controls
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        if (player == nil) {
            return true
        }

        if (control == transcribeTextField) {
            player?.pause()
            if let last = arrayForCaption.last {
                last.endingTime = player?.currentTime()
            }
        }
        return true
    }

    @IBAction func captionTextFieldDidChange(_ sender: NSTextField) {
        if (player == nil) {
            sender.stringValue = ""
            _ = dialogOKCancel(question: "A video is required before adding captions.", text: "Please open a video first, then add captions to the video.")
            return
        }
        if (sender == transcribeTextField) {
            player?.play()
            if sender.stringValue == "" {
                if let last = arrayForCaption.last {
                    last.startingTime = player?.currentTime()
                }
            } else {
                if let last = arrayForCaption.last {
                    last.caption = sender.stringValue
                }
                sender.stringValue = ""
                
                let new = CaptionLine.init(caption: "", startingTime: player?.currentTime(), endingTime: nil)
                arrayForCaption.append(new)
            }
            self.resultTableView.reloadData()
            if resultTableView.numberOfRows > 0 {
                self.resultTableView.scrollRowToVisible(resultTableView.numberOfRows - 1)
            }
        }
    }
    
    // MARK: - Buttons and IBActions
    @IBAction func openFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a video file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = ["mov", "mp4", "m4v", "ts", "mpg", "mpeg", "hevc", "mp3", "m4a"]
        
        if (dialog.runModal() == NSModalResponseOK) {
            if let result = dialog.url {
                saveSRT()
                arrayForCaption = []
                videoDescription = result.lastPathComponent
//                self.timeLabel.stringValue = "\(result.lastPathComponent)"
                playVideo(result)
            }
        } else {
            return
        }
    }
    
    @IBAction func queryTime(_ sender: Any) {
        let time = player?.currentTime().value
        let second = player?.currentTime().seconds
        let scale = player?.currentTime().timescale
        self.timeLabel.stringValue = "\(time ?? kCMTimeZero.value), \(second ?? 0.0), \(scale ?? CMTimeScale(kCMTimeMaxTimescale))"
    }

    func playVideo(_ videoURL: URL) {
        self.videoURL = videoURL
        player = AVPlayer(url: videoURL)
        playerView.player = player
        player?.play()
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (timer) in
            let cap = CaptionLine(caption: "", startingTime: self.player?.currentTime(), endingTime: nil)
            self.arrayForCaption.append(cap)
            
            if let framerate = self.player?.currentItem?.tracks[0].assetTrack.nominalFrameRate {
                self.videoDescription = "\(framerate)fps  |  \(self.videoDescription)"
            }
            self.timeLabel.stringValue = "\(self.videoDescription)"

        }
    }
    
    // MARK: - Table View Delegate/Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrayForCaption.count
    }
    

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSTableCellView?
        
        let correspondingCaption = arrayForCaption[row]
        if tableColumn?.title == "Start Time" {
            cell = tableView.make(withIdentifier: "StartTimeCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "\(correspondingCaption.startingTimeString)"
        } else if tableColumn?.title == "End Time" {
            cell = tableView.make(withIdentifier: "EndTimeCell", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "\(correspondingCaption.endingTimeString)"
        } else {
            cell = tableView.make(withIdentifier: "CaptionCell", owner: self) as? NSTableCellView
            if let cap = correspondingCaption.caption {
                cell?.textField?.stringValue = cap
            } else {
                cell?.textField?.stringValue = ""
            }
            cell?.textField?.isEditable = true
        }
        return cell
    }
    
    @IBAction func startingTimeChanged(_ sender: NSTextField) {
    }
    
    @IBAction func endingTimeChanged(_ sender: NSTextField) {
    }
    
    @IBAction func captionChanged(_ sender: NSTextField) {
        let row = resultTableView.row(for: sender)
        arrayForCaption[row].caption = sender.stringValue
    }
    
    // MARK: - Persistence
    func generateSRTFromArray() -> String {
        var srtString = ""
        for i in 0..<arrayForCaption.count {
            let str: String = arrayForCaption[i].description
            if str.count > 0 {
                srtString = srtString + "\(i+1)\n\(str)\n\n"
            }
        }
        print(srtString)
        return srtString
    }

    @IBAction func saveSRTToDisk(_ sender: Any) {
        saveSRT()
    }
    
    func saveSRT() {
        arrayForCaption.sort(by: { (this, that) -> Bool in
            if let thisST = this.startingTime, let thatST = that.startingTime {
                return thisST < thatST
            }
            return true
        })

        let text = generateSRTFromArray()
        
        guard let origonalVideoName = self.videoURL?.lastPathComponent else {
            return
        }
        let ogVN = (origonalVideoName as NSString).deletingPathExtension
        let newSubtitleName = "\(ogVN).srt"
        
        guard let newPath = self.videoURL?.deletingLastPathComponent().appendingPathComponent(newSubtitleName) else {
            return
        }
        
        do {
            try text.write(to: newPath, atomically: false, encoding: String.Encoding.utf8)
            _ = dialogOKCancel(question: "Saved successfully!", text: "Subtitle saved as \(newSubtitleName) under \(newPath.deletingLastPathComponent()).")
        }
        catch {
            _ = dialogOKCancel(question: "Saved failed!", text: "Save has failed.")
        }
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlertStyle.warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == NSAlertFirstButtonReturn
    }
    
    func dialogTwoButton(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlertStyle.warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
//        alert.buttons[1].becomeFirstResponder()
        return alert.runModal() == NSAlertFirstButtonReturn
    }

}


class CaptionWindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        self.window?.delegate = self
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        if let vc = self.contentViewController as? ViewController {
            if (vc.player != nil) {
                let response = vc.dialogTwoButton(question: "Save Captions?", text: "Would you like to save your captions before closing?")
                print(response)
                if response {
                    vc.saveSRT()
                }
            }
        }
        return true
    }
    
}
