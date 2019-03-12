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
import AppCenter
import AppCenterAnalytics

class MovieViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var timeLabel: NSTextField!
    var fileData: FileData?
    var episode: EpisodeProject! {
        didSet {
            
        }
    }

    var recentTimer: Timer?

    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        AppDelegate.subtitleVC()?.configurateSubtitleVC()
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
//                self.saveToDisk(.srt)
                if self.episode == nil {
                    AppDelegate.sourceListVC()?.updateSelectRow(index: 0)
                }
                self.episode.arrayForCaption = []
                self.episode.videoDescription = result.lastPathComponent
                self.playVideo(result)
                MSAnalytics.trackEvent("New file opened", withProperties: ["Name": (path as NSString).lastPathComponent])
            }
        }
        
    }
    
    @IBAction func queryTime(_ sender: Any) {
        if (episode.player == nil) {
            return
        }
        let time = episode.player?.currentTime().value
        let second = episode.player?.currentTime().seconds
        let scale = episode.player?.currentTime().timescale
        self.timeLabel.stringValue = "\(time ?? CMTime.zero.value), \(second ?? 0.0), \(scale ?? CMTimeScale(kCMTimeMaxTimescale))  \(self.episode.videoDescription)"
    }

    func playVideo(_ videoURL: URL) {
        self.episode.videoURL = videoURL
        episode.player = AVPlayer(url: videoURL)
        playerView.player = episode.player
        episode.player?.play()
        recentTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateFirstCaption), userInfo: nil, repeats: false)
    }

    @objc func updateFirstCaption() {
        if self.episode.arrayForCaption?.count ?? 0 <= 0 {
            let cap = CaptionLine(context: Helper.context!)
            cap.caption = ""
            cap.startingTime = Float(CMTimeGetSeconds((episode.player?.currentTime())!))
            cap.endingTime = 0

            self.episode.addToArrayForCaption(cap)

            if let framerate = self.episode.player?.currentItem?.tracks[0].assetTrack?.nominalFrameRate {
                self.episode.framerate = framerate
            }
            self.timeLabel.stringValue = "\(self.episode.framerate)fps  |  \(self.episode.videoDescription ?? "")"
            self.episode.creationDate = NSDate()
        } else {
            self.episode.modifiedDate = NSDate()
        }
        self.populateThumbnail()
    }

    func populateThumbnail() {
        if (self.episode.thumbnailURL == nil) {
            let sourceURL = self.episode!.videoURL
            let asset = AVAsset(url: sourceURL!)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let time = CMTimeMake(value: 1, timescale: 1)
            let imageRef = try! imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = NSImage(cgImage: imageRef, size: NSSize(width: imageRef.width, height: imageRef.height))
            let desktopURL = FileManager.default.urls(for: .allLibrariesDirectory, in: .userDomainMask).first!
            let destinationURL = desktopURL.appendingPathComponent("\(NSUUID().uuidString).png")
            let result = thumbnail.pngWrite(to: destinationURL)
            print("Writing thumbnail: \(result)")
            self.episode.thumbnailURL = destinationURL
        }
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
        if episode == nil {
            return
        }

        guard var copiedArray = (episode.arrayForCaption?.array as? [CaptionLine]) else { return }

        copiedArray.sort(by: { (this, that) -> Bool in
            return this.startingTime < that.startingTime
        })

        var text = "Export is unsuccessful."
        
        if let fData = fileData {
            if type == .srt {
                text = Exporter.generateSRTFromArray(arrayForCaption: copiedArray)
                fData.ext = "srt"
                NSFileCoordinator.removeFilePresenter(fData)
                NSFileCoordinator.addFilePresenter(fData)
                print(fData.ext)
            } else if type == .txt {
                text = Exporter.generateTXTFromArray(arrayForCaption: copiedArray)
                fData.ext = "txt"
                NSFileCoordinator.removeFilePresenter(fData)
                NSFileCoordinator.addFilePresenter(fData)
                print(fData.ext)
            } else if type == .fcpXML {
                text = Exporter.generateFCPXMLFromArray(player: episode.player, arrayForCaption: copiedArray)
                fData.ext = "fcpxml"
                NSFileCoordinator.removeFilePresenter(fData)
                NSFileCoordinator.addFilePresenter(fData)
                print(fData.ext)
            }
        }
        
        guard let origonalVideoName = self.episode.videoURL?.lastPathComponent else {
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

        guard let newPath = self.episode.videoURL?.deletingLastPathComponent().appendingPathComponent(newSubtitleName) else {
            return
        }
        
        if let fData = fileData, let url = fData.presentedItemURL {

            var errorMain: NSError?
            let coord = NSFileCoordinator(filePresenter: fData)
            coord.coordinate(writingItemAt: url as URL, options: .forReplacing, error: &errorMain, byAccessor: { writeUrl in
                print("Write File")
                do {
                    try text.write(toFile: writeUrl.path, atomically: true, encoding: String.Encoding.utf8)
                    _ = Helper.dialogOKCancel(question: "Saved successfully!", text: "Subtitle saved as \(newSubtitleName) under \(newPath.deletingLastPathComponent()).")

                } catch {
                    print("Error writing to file: \(error)")
                    _ = Helper.dialogOKCancel(question: "Saved failed!", text: "Save has failed. \(error)")

                }
                return
            })
        }
    }

    func configurateMovieVC() {
        recentTimer?.invalidate()
        if let url = self.episode.videoURL {
            self.playVideo(url)
        } else {
            self.episode.player = AVPlayer()
            self.playerView.player = self.episode.player
            print("Can't configurate movie VC")
        }
    }
}


