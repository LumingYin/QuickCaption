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
    @IBOutlet weak var waveformImageView: NSImageView!
    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineOverallView: NSView!


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
        recentTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateLoadVideo), userInfo: nil, repeats: false)
    }

    @objc func updateLoadVideo() {
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
            self.episode.videoDuration = Float(CMTimeGetSeconds((self.episode.player?.currentItem?.asset.duration)!))
        } else {
            self.episode.modifiedDate = NSDate()
        }
        self.populateThumbnail()
        DispatchQueue.main.async {
            self.configureOverallScrollView()
            self.configureTextTrack()
            self.configureWaveTrack()
            self.configureVideoThumbnailTrack()
        }
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
            let destinationURL = desktopURL.appendingPathComponent("CaptionStudio").appendingPathComponent("\(NSUUID().uuidString).png")
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
        var ext = ""
        
        if type == .srt {
            text = Exporter.generateSRTFromArray(arrayForCaption: copiedArray)
            ext = "srt"
        } else if type == .txt {
            text = Exporter.generateTXTFromArray(arrayForCaption: copiedArray)
            ext = "txt"
        } else if type == .fcpXML {
            text = Exporter.generateFCPXMLFromArray(player: episode.player, arrayForCaption: copiedArray)
            ext = "fcpxml"
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
        
        do {
            try text.write(to: newPath, atomically: true, encoding: String.Encoding.utf8)
            _ = Helper.dialogOKCancel(question: "Saved successfully!", text: "Subtitle saved as \(newSubtitleName) under \(newPath.deletingLastPathComponent()).")
        }
        catch {
            print("Error writing to file: \(error)")
            _ = Helper.dialogOKCancel(question: "Saved failed!", text: "Save has failed. \(error)")
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

    var pointsPerFrameScaleFactor: CGFloat = 15
    var timelineLengthPixels: CGFloat {
        get {
            let player = self.episode.player!
            return CGFloat(CMTimeGetSeconds((player.currentItem?.asset.duration)!)) * pointsPerFrameScaleFactor
        }
    }
    var timeLineSegmentHeight: CGFloat {
        // 64 for now
        return timelineScrollView.frame.height / 3
    }

    // MARK: - Custom Timeline
    func configureOverallScrollView() {
        self.timelineOverallView.setFrameSize(NSSize(width: timelineLengthPixels + 100, height: self.timelineOverallView.frame.size.height))
    }

    func configureTextTrack() {

    }

    func configureWaveTrack() {
        let asset = self.episode.player?.currentItem?.asset
        let audioTracks:[AVAssetTrack] = asset!.tracks(withMediaType: AVMediaType.audio)
        if let track:AVAssetTrack = audioTracks.first{
            //let timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: 1000), CMTime(seconds: 1, preferredTimescale: 1000))
            let timeRange:CMTimeRange? = nil
            self.waveformImageView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.waveformImageView.frame.size.height))
            let width = Int(timelineLengthPixels)

            // Let's extract the downsampled samples
            let samplingStartTime = CFAbsoluteTimeGetCurrent()
            SamplesExtractor.samples(audioTrack: track,
                                     timeRange: timeRange,
                                     desiredNumberOfSamples: width,
                                     onSuccess: { s, sMax, _ in
                                        let sampling = (samples: s, sampleMax: sMax)
                                        // let samplingDuration = CFAbsoluteTimeGetCurrent() - samplingStartTime
                                        // Image Drawing
                                        // Let's draw the sample into an image.
                                        let configuration = WaveformConfiguration(size: self.waveformImageView.bounds.size,
                                                                                  color: WaveColor.red,
                                                                                  backgroundColor:WaveColor.clear,
                                                                                  style: .gradient,
                                                                                  position: .middle,
                                                                                  scale: 1,
                                                                                  borderWidth:0,
                                                                                  borderColor:WaveColor.red)
                                        let drawingStartTime = CFAbsoluteTimeGetCurrent()
                                        self.waveformImageView.image = WaveFormDrawer.image(with: sampling, and: configuration)
                                        // let drawingDuration = CFAbsoluteTimeGetCurrent() - drawingStartTime
                                        // self.nbLabel.stringValue = "\(width)/\(sampling.samples.count)"
                                        // self.samplingDurationLabel.stringValue = String(format:"%.3f s",samplingDuration)
                                        // self.drawingDurationLabel.stringValue = String(format:"%.3f s",drawingDuration)
            }, onFailure: { error, id in
                print("\(id ?? "") \(error)")
            })
        }

    }

    func configureVideoThumbnailTrack() {

    }

}


