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

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextViewDelegate {
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var timeLabel: NSTextField!
    var player: AVPlayer?
    @IBOutlet var transcribeTextView: NSTextView!
    
    var arrayForCaption: [CaptionLine] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        transcribeTextView.delegate = self
        transcribeTextView.isAutomaticSpellingCorrectionEnabled = false
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        // play 上一个结束了
        // pause 下一个开始？
        
        print("\(String(describing: replacementString))")
//        if replacementString == "" {
//            player?.pause()
//        }
        
        
        if transcribeTextView.string == "" {
//            let cap = CaptionLine(caption: "", startingTime: player?.currentTime(), endingTime: nil)
//            arrayForCaption.append(cap)
            player?.pause()
            if let last = arrayForCaption.last {
                last.endingTime = player?.currentTime()
            }
        } else {
            let breakDict = transcribeTextView.string?.components(separatedBy: "\n")
            if let lastLine = breakDict?.last {
                if lastLine == "" && replacementString != "" {
                    player?.pause()
                    if let last = arrayForCaption.last {
                        last.endingTime = player?.currentTime()
                    }
                }
            }
        }
        if (replacementString == "\n") {
            player?.play()
            if let last = arrayForCaption.last {
                let breakDict = transcribeTextView.string?.components(separatedBy: "\n")
                if let lastLine = breakDict?.last {
                    last.caption = lastLine
                }
            }

            let new = CaptionLine.init(caption: "", startingTime: player?.currentTime(), endingTime: nil)
            arrayForCaption.append(new)
        }
        return true
    }
    
    
    @IBAction func generatePressed(_ sender: Any) {
        generateSRTFromArray()
    }
    
    func generateSRTFromArray() {
        var srtString = ""
        for i in 0..<arrayForCaption.count {
            srtString = srtString + "\(i+1)" + "\(arrayForCaption[i])"
//            print(\(i + 1))
//            print(arrayForCaption[i])
        }
        print(srtString)
    }
    
    
    func textDidChange(_ notification: Notification) {
//        transcribeTextView.
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    @IBAction func openFile(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .txt file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["mov", "mp4", "m4v"];
        
        if (dialog.runModal() == NSModalResponseOK) {
            if let result = dialog.url {
                playVideo(result)
            }
        } else {
            return
        }
    }

    func playVideo(_ videoURL: URL) {
        player = AVPlayer(url: videoURL)
        playerView.player = player
        player?.play()
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (timer) in
            let cap = CaptionLine(caption: "", startingTime: self.player?.currentTime(), endingTime: nil)
            self.arrayForCaption.append(cap)
        }
//        player?.currentTime()
//        let cap = CaptionLine(caption: "", startingTime: nil, endingTime: nil)
//        arrayForCaption.append(cap)
        tableView.reloadData()
//        let videoURL: NSURL = NSBundle.mainBundle().URLForResource("Para1_2", withExtension: "mp4")!
//        let player = AVPlayer(URL: videoURL)
//        playerLayer = AVPlayerLayer(player: player)
//        playerLayer!.frame = self.view!.bounds
//        self.view!.layer.addSublayer(playerLayer!)
//        player.play()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrayForCaption.count
    }
    
//    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
//        <#code#>
//    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.title == "Time" {
            let cell = tableView.make(withIdentifier: "TimeCellView", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "time"
            return cell

        } else {
            let cell = tableView.make(withIdentifier: "ContentCellView", owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "abncd"
            return cell
        }
    }
    
    @IBAction func queryTime(_ sender: Any) {
        let time = player?.currentTime().value
        let second = player?.currentTime().seconds
        let scale = player?.currentTime().timescale
        self.timeLabel.stringValue = "\(time ?? kCMTimeZero.value), \(second ?? 0.0), \(scale ?? CMTimeScale(kCMTimeMaxTimescale))"
    }
}

class CaptionLine: CustomStringConvertible {
    var caption: String?
    var startingTime: CMTime?
    var endingTime: CMTime?
    
    init(caption: String?, startingTime: CMTime?, endingTime: CMTime?) {
        self.caption = caption
        self.startingTime = startingTime
        self.endingTime = endingTime
    }
    
    var description: String {
        guard let cap = caption, let start = startingTime, let end = endingTime else {
            return ""
        }
        
        let st = CMTimeGetSeconds(start)
        let en = CMTimeGetSeconds(end)
        
        let stringStart = secondFloatToString(float: st)
        let stringEnd = secondFloatToString(float: en)
        
        return "\(stringStart) --> \(stringEnd)\n\(cap)"
    }
    
    func secondFloatToString(float: Float64) -> String {
        var second = float
        
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var milliseconds: Int = 0
        
        hours = Int(second / Float64(3600))
        second = second - Float64(hours * 3600)
        
        minutes = Int(second / Float64(60))
        second = second - Float64(minutes * 60)
        
        seconds = Int(second)
        second = second - Float64(seconds)
        
        milliseconds = Int(second * 1000)
        
        let string = NSString(format:"%.2f:%.2f:%.2f,%.3f", hours, minutes, seconds, milliseconds)
        
//        return "\(hours):\(minutes):\(seconds),\(milliseconds)"
        return string as String
    }
    
    
}
