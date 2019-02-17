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
        case fcpXML
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
                var new: CaptionLine!
                if let lastEndingTime = arrayForCaption.last?.endingTime {
                    new = CaptionLine.init(caption: "", startingTime: lastEndingTime, endingTime: nil)
                } else {
                    new = CaptionLine.init(caption: "", startingTime: player?.currentTime(), endingTime: nil)
                }
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
        self.timeLabel.stringValue = "\(time ?? CMTime.zero.value), \(second ?? 0.0), \(scale ?? CMTimeScale(kCMTimeMaxTimescale))  \(self.videoDescription)"
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
        
        if let framerate = self.player?.currentItem?.tracks[0].assetTrack?.nominalFrameRate {
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

    func generateFCPXMLFromArray() -> String {
        guard let totalDuration = player?.currentItem?.asset.duration, let asset = player?.currentItem?.asset else {
            return ""
        }
        let tracks = asset.tracks(withMediaType: .video)
        guard let fps = tracks.first?.nominalFrameRate else {
            return ""
        }
        let frameDurationSeconds = 1 / fps
        let totalDurationSeconds = CMTimeGetSeconds(totalDuration)
        let templateA = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE fcpxml>

<fcpxml version="1.8">
    <resources>
        <format id="r1" name="FFVideoFormat1080p30" frameDuration="\(frameDurationSeconds)s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
    </resources>
    <library location="file:///Volumes/Data/Movies/Library.fcpbundle/">
        <event name="2-16-19" uid="70DAF714-AC1D-4046-BEBC-0D778C57B48E">
            <project name="Caption 1080p 30fps" uid="2E89EF28-11F8-4AD8-8196-0C86E95EACD5" modDate="2019-02-16 18:17:23 -0500">
                <sequence duration="\(totalDurationSeconds)s" format="r1" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <gap name="Gap" offset="0s" duration="\(totalDurationSeconds)s" start="0s">
        <spine lane="1" offset="0s">

"""

        var templateB = ""

        for i in 0..<arrayForCaption.count {
            let line = arrayForCaption[i]
            if let str: String = line.caption {
                if str.count > 0 {
                    templateB += """
                        <title name="\(str)" offset="0s" ref="r2" duration="\(line.durationTimeSecondsString)" start="\(line.startingTimeSecondsString)">
                            <param name="Position" key="9999/999166631/999166633/1/100/101" value="0.5 -370.516"/>
                            <param name="Flatten" key="9999/999166631/999166633/2/351" value="1"/>
                            <param name="Alignment" key="9999/999166631/999166633/2/354/999169573/401" value="1 (Center)"/>
                            <param name="Wrap Mode" key="9999/999166631/999166633/5/999166635/21/25/5" value="1 (Repeat)"/>
                            <param name="Opacity" key="9999/999166631/999166633/5/999166635/21/26" value="0.6097"/>
                            <param name="Distance" key="9999/999166631/999166633/5/999166635/21/27" value="4"/>
                            <param name="Blur" key="9999/999166631/999166633/5/999166635/21/75" value="1.12 1.12"/>
                            <text>
                                <text-style ref="ts\(i + 1)">\(str)</text-style>
                            </text>
                            <text-style-def id="ts\(i + 1)">
                                <text-style font="Helvetica" fontSize="45" fontFace="Regular" fontColor="1 1 1 1" shadowColor="0 0 0 0.6097" shadowOffset="4 315" shadowBlurRadius="2.24" alignment="center"/>
                            </text-style-def>
                        </title>
                    """
                }
            }
        }


        let templateC = """
                    </spine>

                        </gap>
                    </spine>
                </sequence>
            </project>
        </event>
        <smart-collection name="Projects" match="all">
            <match-clip rule="is" type="project"/>
        </smart-collection>
        <smart-collection name="All Video" match="any">
            <match-media rule="is" type="videoOnly"/>
            <match-media rule="is" type="videoWithAudio"/>
        </smart-collection>
        <smart-collection name="Audio Only" match="all">
            <match-media rule="is" type="audioOnly"/>
        </smart-collection>
        <smart-collection name="Stills" match="all">
            <match-media rule="is" type="stills"/>
        </smart-collection>
        <smart-collection name="Favorites" match="all">
            <match-ratings value="favorites"/>
        </smart-collection>
    </library>
</fcpxml>
"""

        return "\(templateA)\(templateB)\(templateC)"
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
    
    @IBAction func saveFCPXMLToDisk(_ sender: Any) {
        saveToDisk(.fcpXML)
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
            } else if type == .fcpXML {
                text = generateFCPXMLFromArray()
                fData.ext = "fcpxml"
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
        if (type == .fcpXML) {
            newSubtitleName = "\(ogVN).fcpxml"
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


