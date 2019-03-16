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

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressViewColorLineBox: NSBox!

    @IBOutlet weak var subtitleTrackContainerView: NSView!
    @IBOutlet weak var videoPreviewContainerView: NSView!
    @IBOutlet weak var waveformImageView: NSImageView!

    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineOverallView: NSView!

    var cachedCaptionViews: [String: CaptionBoxView] = [:]


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
        if (episode == nil || episode.player == nil) {
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
            cap.guidIdentifier = NSUUID().uuidString
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
        self.episode.videoDuration = Float(CMTimeGetSeconds((self.episode.player?.currentItem?.asset.duration)!))
        self.populateThumbnail()
        self.configureOverallScrollView()
        self.configurateRedBar()

        DispatchQueue.main.async {
            self.configureTextTrack()
        }
        self.configureWaveTrack()
        DispatchQueue.main.async {
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
//            let desktopURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = self.applicationDataDirectory().appendingPathComponent("thumbnails")
            do {try FileManager.default.createDirectory(at: self.applicationDataDirectory().appendingPathComponent("thumbnails"), withIntermediateDirectories: true, attributes: nil)
            } catch {print(error)}
            let destinationURL = self.applicationDataDirectory().appendingPathComponent("thumbnails").appendingPathComponent("\(NSUUID().uuidString).png")
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
        NotificationCenter.default.removeObserver(self)

        episode.safelyRemoveObserver(self, forKeyPath: "arrayForCaption")
        if let arr = self.episode.arrayForCaption?.array as? [CaptionLine] {
            for line in arr {
                line.safelyRemoveObserver(self, forKeyPath: "caption")
                line.safelyRemoveObserver(self, forKeyPath: "startingTime")
                line.safelyRemoveObserver(self, forKeyPath: "endingTime")
            }
        }
        for (key, view) in cachedCaptionViews {
            view.removeFromSuperview()
        }
        self.cachedCaptionViews = [:]
        self.subtitleTrackContainerView.subviews = []
        self.videoPreviewContainerView.subviews = []
        self.waveformImageView.image = nil
        self.progressView.setFrameOrigin(NSPoint(x: 0, y: self.progressView.frame.origin.y))

        if let url = self.episode.videoURL {
            self.playVideo(url)
        } else {
            self.episode.player = AVPlayer()
            self.playerView.player = self.episode.player
            print("Can't configurate movie VC")
        }
    }

    var pointsPerFrameScaleFactor: CGFloat = 45
    var timelineLengthPixels: CGFloat {
        get {
            let player = self.episode.player!
            return CGFloat(CMTimeGetSeconds((player.currentItem?.asset.duration)!)) * pointsPerFrameScaleFactor
        }
    }
    var timeLineSegmentHeight: CGFloat {
        // 64 for now
//        return timelineScrollView.frame.height / 3
        return 64
    }

    // MARK: - Custom Timeline
    func configureOverallScrollView() {
        self.timelineOverallView.setFrameSize(NSSize(width: timelineLengthPixels + 100, height: self.timelineOverallView.frame.size.height))
    }

    private static var textTrackContext = 0

    func configureTextTrack() {
        self.subtitleTrackContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.subtitleTrackContainerView.frame.size.height))
//        self.subtitleTrackContainerView.layer?.backgroundColor = NSColor.purple.cgColor
        if (episode == nil || episode!.arrayForCaption == nil) { return }
        for captionLine in (episode!.arrayForCaption?.array as! [CaptionLine]) {
            self.addObserverForCaptionLine(captionLine)
        }
        episode.addObserver(self, forKeyPath: "arrayForCaption", options: [.initial, .new], context: &MovieViewController.textTrackContext)
    }

    var calculatedDuration: Float {
        get {
            return Float(CMTimeGetSeconds((self.episode.player!.currentItem?.asset.duration)!))
        }
    }

    func addObserverForCaptionLine(_ captionLine: CaptionLine) {
        captionLine.addObserver(self, forKeyPath: "caption", options: [.new, .initial], context: &MovieViewController.textTrackContext)
        captionLine.addObserver(self, forKeyPath: "startingTime", options: [.new, .initial], context: &MovieViewController.textTrackContext)
        captionLine.addObserver(self, forKeyPath: "endingTime", options: [.new, .initial], context: &MovieViewController.textTrackContext)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &MovieViewController.textTrackContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        for aChange in change ?? [:] {
            print("The change key: \(aChange.key), value: \(aChange.value)")
            if let indexSet = aChange.value as? NSIndexSet {
                print("The NSIndexSet is: \(indexSet)")
                for index in indexSet {
                    let indexInt: Int = index
                    if let captionLine = episode.arrayForCaption?.object(at: indexInt) as? CaptionLine {
                        addObserverForCaptionLine(captionLine)
                    }
                }
            }
        }
        if let captionLine = object as? CaptionLine {
            guard let guid = captionLine.guidIdentifier else {return}
            if cachedCaptionViews[guid] == nil {
                cachedCaptionViews[guid] = CaptionBoxView()
                self.subtitleTrackContainerView.addSubview(cachedCaptionViews[guid]!)
            }
            guard let existingView = cachedCaptionViews[guid] else { return }
            existingView.captionText = captionLine.caption ?? ""

            let startingPercentile = CGFloat(captionLine.startingTime / calculatedDuration)
            let endingPercentile = CGFloat(captionLine.endingTime / calculatedDuration)
            let diffBetweenStartEnd = endingPercentile - startingPercentile
            var width = diffBetweenStartEnd * timelineLengthPixels
            if width == 0 {
                width = 0
            }
            existingView.frame = NSRect(x: startingPercentile * timelineLengthPixels, y: 0, width: width, height: timeLineSegmentHeight)
            existingView.setNeedsDisplay(existingView.bounds)
        }
//        if let line = object as? CaptionLine {
//            print("Changed captionline object: \(line)")
//        }
//        print("Something on object: \(object) changed: \(change)")
    }

    func configureWaveTrack() {
        let asset = self.episode.player?.currentItem?.asset
        let audioTracks:[AVAssetTrack] = asset!.tracks(withMediaType: AVMediaType.audio)
        if let track:AVAssetTrack = audioTracks.first{
            //let timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: 1000), CMTime(seconds: 1, preferredTimescale: 1000))
            let timeRange:CMTimeRange? = nil
            self.waveformImageView.setFrameSize(NSSize(width: self.timelineLengthPixels, height: self.waveformImageView.frame.size.height))
            var cachedBounds = self.waveformImageView.bounds.size
            cachedBounds.width = self.timelineLengthPixels
            let width = Int(timelineLengthPixels)

            DispatchQueue.global(qos: .background).async {
                // Let's extract the downsampled samples
//                let samplingStartTime = CFAbsoluteTimeGetCurrent()
                SamplesExtractor.samples(audioTrack: track,
                                         timeRange: timeRange,
                                         desiredNumberOfSamples: width,
                                         onSuccess: { s, sMax, _ in
                                            let sampling = (samples: s, sampleMax: sMax)
                                            // let samplingDuration = CFAbsoluteTimeGetCurrent() - samplingStartTime
                                            // Image Drawing
                                            // Let's draw the sample into an image.
                                            let configuration = WaveformConfiguration(size: cachedBounds,
                                                                                      color: WaveColor(red: 77 / 255, green: 103 / 255, blue: 143 / 255, alpha: 1),
                                                                                      backgroundColor: WaveColor(red: 22 / 255, green: 38 / 255, blue: 67 / 255, alpha: 1),
                                                                                      style: .gradient,
                                                                                      position: .middle,
                                                                                      scale: 1,
                                                                                      borderWidth: 1,
                                                                                      borderColor: WaveColor.gray)
//                                            let drawingStartTime = CFAbsoluteTimeGetCurrent()
                                            let imageDrawn = WaveFormDrawer.image(with: sampling, and: configuration)
                                            DispatchQueue.main.async {
                                                // self.waveformImageView.imageFrameStyle = .grayBezel
                                                self.waveformImageView.image = imageDrawn
                                            }
                                            // let drawingDuration = CFAbsoluteTimeGetCurrent() - drawingStartTime
                                            // self.nbLabel.stringValue = "\(width)/\(sampling.samples.count)"
                                            // self.samplingDurationLabel.stringValue = String(format:"%.3f s",samplingDuration)
                                            // self.drawingDurationLabel.stringValue = String(format:"%.3f s",drawingDuration)
                }, onFailure: { error, id in
                    print("\(id ?? "") \(error)")
                })
            }
        }
    }

    func configureVideoThumbnailTrack() {
        self.videoPreviewContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.videoPreviewContainerView.frame.size.height))
//        self.videoPreviewContainerView.layer?.backgroundColor = NSColor.purple.cgColor
        // one snapshot every 10 seconds
        let asset = self.episode.player?.currentItem?.asset
        let imageGenerator = AVAssetImageGenerator(asset: asset!)
        if let duration = self.episode.player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            var secondIndex: Float64 = 1
            var imageIndex: Int = 0
            if (totalSeconds.isNaN) {
                return
            }
            let numberOfThumbnails = Int(totalSeconds / 10)
            let widthOfThumbnail = timelineLengthPixels / CGFloat(numberOfThumbnails)
            while (secondIndex < totalSeconds) {
                let screenshotTime = CMTime(seconds: Double(secondIndex), preferredTimescale: 1)
                do {
                    let imageRef = try? imageGenerator.copyCGImage(at: screenshotTime, actualTime: nil)
                    let image = NSImage(cgImage: imageRef!, size: NSSize(width: imageRef!.width, height: imageRef!.height))
                    let imageView = NSImageView(frame: NSRect(x: widthOfThumbnail * CGFloat(imageIndex), y: 0, width: widthOfThumbnail, height: timeLineSegmentHeight))
                    imageView.imageScaling = .scaleProportionallyUpOrDown
                    imageView.imageFrameStyle = .grayBezel
                    imageView.image = image
                    videoPreviewContainerView.addSubview(imageView)
                } catch {
                    "Can't take screenshot: \(error)"
                }
                secondIndex += 10
                imageIndex += 1
            }
        }
//        var imageGenerator = AVAssetImageGenerator(asset: asset!)
//            let value = Float64(percent) * totalSeconds
//            let seekTime = CMTime(seconds: Double(value), preferredTimescale: 1)
//        }
//        var time = CMTimeMake(1, 1)
//        var imageRef = try! imageGenerator.copyCGImage(at: time, actualTime: nil)
//        var thumbnail = UIImage(cgImage:imageRef)

    }

    let offsetPixelInScrollView: CGFloat = 8
    let redBarOffsetInScrollView: CGFloat = 8

    func configurateRedBar() {
        let interval = CMTime(value: 1, timescale: 2)
        self.episode.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in
            let seconds = CMTimeGetSeconds(progressTime)
            let secondsString = String(format: "%02d", Int(seconds.truncatingRemainder(dividingBy: 60)))
            let minutesString = String(format: "%02d", Int(seconds / 60))

//            self.currentTimeLabel.text = "\(minutesString):\(secondsString)"

            //lets move the slider thumb
            if let duration = self.episode.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                let percent = CGFloat(seconds / durationSeconds)
                self.progressView.setFrameOrigin(NSPoint(x: self.timelineLengthPixels * percent + self.offsetPixelInScrollView - self.redBarOffsetInScrollView, y: self.progressView.frame.origin.y))
            }

//            if !(self.timelineScrollView.bounds.contains(self.progressView.frame)) {
//                print("Not matching up, self.timelineScrollView.bounds:\(self.timelineScrollView.bounds), self.progressView.frame:\(self.progressView.frame)")
//                // time to scroll to make the new timestamp visible!
//                var targetFrame = self.progressView.frame
//                targetFrame.size.width = self.timelineScrollView.frame.width
//                targetFrame.origin.x -= self.offsetPixelInScrollView
////                var newPoint = NSPoint(x: self.progressView.frame.origin.x, y: self.timelineScrollView.contentView.frame.origin.y)
//                self.timelineScrollView.contentView.scrollToVisible(targetFrame)
////                self.timelineScrollView.contentView.scroll(to: newPoint)
//            } else {
//                print("matching up, self.timelineScrollView.bounds:\(self.timelineScrollView.bounds), self.progressView.frame:\(self.progressView.frame)")
//            }
        })
    }

    @IBAction func clickedOnNewTimelineIndex(_ sender: NSClickGestureRecognizer) {
        handleNewTimelineLocation(sender: sender)
    }

    @IBAction func pannedToNewTimelineIndex(_ sender: NSPanGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            progressViewColorLineBox.fillColor = NSColor.yellow
        } else {
            progressViewColorLineBox.fillColor = NSColor.red
        }
        handleNewTimelineLocation(sender: sender)
    }

    func handleNewTimelineLocation(sender: NSGestureRecognizer) {
        if (self.episode == nil || self.episode.player == nil || self.episode.player?.currentItem == nil) {
            return
        }
        let location = sender.location(in: timelineOverallView).x - self.offsetPixelInScrollView
        let percent = location / self.timelineLengthPixels

        if let duration = self.episode.player?.currentItem?.duration {
            let totalSeconds = CMTimeGetSeconds(duration)
            let value = Float64(percent) * totalSeconds
            let seekTime = CMTime(seconds: Double(value), preferredTimescale: 1)
            //            let seekTime = CMTime(value: Int64(value * 10000000), timescale: 10000000)
            print("Seeking to: \(seekTime) with percent of \(percent) at location \(location)")
            //            self.episode.player?.pause()
            self.episode.player?.seek(to: seekTime, completionHandler: { (completedSeek) in
                //perhaps do something later here
                //                self.episode.player?.play()
            })
        }
    }
}


