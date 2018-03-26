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
    
    var fileData: FileData?
    var videoDescription: String = ""
    var player: AVPlayer?
    var videoURL: URL?
    var arrayForCaption: [CaptionLine] = []
    enum FileType {
        case srt
        case txt
    }
    
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
        dialog.allowedFileTypes        = ["mp4", "mpeg4", "m4v", "ts", "mpg", "mpeg", "mp3", "mpeg3", "m4a", "mov"]
        
        dialog.beginSheetModal(for: self.view.window!) { (result) in
            if let result = dialog.url, let path = dialog.url?.path {
                self.fileData = FileData(path: path)
                NSFileCoordinator.addFilePresenter(self.fileData!)
                self.saveToDisk(.srt)
                self.arrayForCaption = []
                self.videoDescription = result.lastPathComponent
                self.playVideo(result)
            }
        }
        
    }
    
    @IBAction func queryTime(_ sender: Any) {
        if (player == nil) {
            return
        }
        let time = player?.currentTime().value
        let second = player?.currentTime().seconds
        let scale = player?.currentTime().timescale
        self.timeLabel.stringValue = "\(time ?? kCMTimeZero.value), \(second ?? 0.0), \(scale ?? CMTimeScale(kCMTimeMaxTimescale))  \(self.videoDescription)"
    }

    func playVideo(_ videoURL: URL) {
        self.videoURL = videoURL
        player = AVPlayer(url: videoURL)
        playerView.player = player
        player?.play()
        Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateFirstCaption), userInfo: nil, repeats: false)
    }
    
    @objc func updateFirstCaption() {
        let cap = CaptionLine(caption: "", startingTime: self.player?.currentTime(), endingTime: nil)
        self.arrayForCaption.append(cap)
        
        if let framerate = self.player?.currentItem?.tracks[0].assetTrack.nominalFrameRate {
            self.videoDescription = "\(framerate)fps  |  \(self.videoDescription)"
        }
        self.timeLabel.stringValue = "\(self.videoDescription)"

    }
    
    // MARK: - Table View Delegate/Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrayForCaption.count
    }
    

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var cell: NSTableCellView?
        
        let correspondingCaption = arrayForCaption[row]
        if tableColumn?.title == "Start Time" {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "StartTimeCell"), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "\(correspondingCaption.startingTimeString)"
        } else if tableColumn?.title == "End Time" {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EndTimeCell"), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "\(correspondingCaption.endingTimeString)"
        } else {
            cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CaptionCell"), owner: self) as? NSTableCellView
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
    
    func generateTXTFromArray() -> String {
        var txtString = ""
        for i in 0..<arrayForCaption.count {
            if let str: String = arrayForCaption[i].caption {
                if str.count > 0 {
                    txtString = txtString + "\(str)\n"
                }
            }
        }
        print(txtString)
        return txtString
    }

    
    @IBAction func saveTXTToDisk(_ sender: Any) {
        saveToDisk(.txt)
    }
    
    @IBAction func saveSRTToDisk(_ sender: Any) {
        saveToDisk(.srt)
    }
    
    func saveToDisk(_ type: FileType) {
        arrayForCaption.sort(by: { (this, that) -> Bool in
            if let thisST = this.startingTime, let thatST = that.startingTime {
                return thisST < thatST
            }
            return true
        })

        var text = "Export is unsuccessful."
        
        if let fData = fileData {
            if type == .srt {
                text = generateSRTFromArray()
                fData.ext = "srt"
                NSFileCoordinator.removeFilePresenter(fData)
                NSFileCoordinator.addFilePresenter(fData)
                print(fData.ext)
            } else if type == .txt {
                text = generateTXTFromArray()
                fData.ext = "txt"
                NSFileCoordinator.removeFilePresenter(fData)
                NSFileCoordinator.addFilePresenter(fData)
                print(fData.ext)
            }

        }
        
        guard let origonalVideoName = self.videoURL?.lastPathComponent else {
            return
        }
        let ogVN = (origonalVideoName as NSString).deletingPathExtension
        
        var newSubtitleName = "\(ogVN).srt"
        if (type == .txt) {
            newSubtitleName = "\(ogVN).txt"
        }

        guard let newPath = self.videoURL?.deletingLastPathComponent().appendingPathComponent(newSubtitleName) else {
            return
        }
        
        if let fData = fileData, let url = fData.presentedItemURL {

            var errorMain: NSError?
            let coord = NSFileCoordinator(filePresenter: fData)
            coord.coordinate(writingItemAt: url as URL, options: .forReplacing, error: &errorMain, byAccessor: { writeUrl in
                print("Write File")
                do {
                    try text.write(toFile: writeUrl.path, atomically: true, encoding: String.Encoding.utf8)
                    _ = dialogOKCancel(question: "Saved successfully!", text: "Subtitle saved as \(newSubtitleName) under \(newPath.deletingLastPathComponent()).")

                } catch {
                    print("Error writing to file: \(error)")
                    _ = dialogOKCancel(question: "Saved failed!", text: "Save has failed. \(error)")

                }
                return
            })
        }
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    func dialogTwoButton(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

}


class CaptionWindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        self.window?.delegate = self
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
