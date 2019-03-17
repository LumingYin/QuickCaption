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

@objc class MovieViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, SubtitleTrackContainerViewDelegate {
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var timeLabel: NSTextField!

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressViewColorLineBox: NSBox!

    @IBOutlet weak var subtitleTrackContainerView: SubtitleTrackContainerView!
    @IBOutlet weak var videoPreviewContainerView: VideoPreviewContainerView!
    @IBOutlet weak var waveformImageView: NSImageView!

    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineOverallView: NSView!
    @IBOutlet weak var captionPreviewLabel: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var playPauseImageView: NSImageView!

    var cachedCaptionViews: [String: CaptionBoxView] = [:]


    var episode: EpisodeProject! {
        didSet {
            
        }
    }

    var recentTimer: Timer?

    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        AppDelegate.subtitleVC()?.dismantleSubtitleVC()
        AppDelegate.subtitleVC()?.configurateSubtitleVC()
    }
    
    // MARK: - Buttons and IBActions
    @IBAction func openFile(_ sender: Any) {
        let dialog = NSOpenPanel()
        
        dialog.title                   = "Choose a video file"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = false
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
        self.episode.player?.addObserver(self, forKeyPath: "rate", options: [.new], context: &MovieViewController.playerPlayrateContext)
        playerView.player = episode.player
        episode.player?.play()
        recentTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(updateLoadVideo), userInfo: nil, repeats: false)
    }

    func updatePersistedFramerate() {
        if self.episode.player?.currentItem?.tracks == nil || self.episode.player?.currentItem?.tracks.count ?? 0 <= 0 {
            return
        }
        if self.episode != nil && (self.episode.framerate == nil || self.episode.framerate == 0 || self.episode.framerate == 0.0)  {
            if let framerate = self.episode.player?.currentItem?.tracks[0].assetTrack?.nominalFrameRate {
                self.episode.framerate = framerate
                AppDelegate.fontVC()?.configureAllMetadata()
            }
        }
    }

    @objc func updateLoadVideo() {
        self.videoPreviewContainerView.guid = self.episode.guidIdentifier
        if self.episode.arrayForCaption?.count ?? 0 <= 0 {
            let cap = CaptionLine(context: Helper.context!)
            cap.guidIdentifier = NSUUID().uuidString
            cap.caption = ""
            cap.startingTime = Float(CMTimeGetSeconds((episode.player?.currentTime())!))
            cap.endingTime = 0

            self.episode.addToArrayForCaption(cap)
            updatePersistedFramerate()
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
        refreshFontToReflectStyleChanges()
        self.configurateFontPreviewListener()
        AppDelegate.fontVC()?.configureAllMetadata()
        if let desc = self.episode.videoDescription {
            AppDelegate.setCurrentEpisodeTitle(desc.withoutFileExtension)
        }
    }

    func configurateFontPreviewListener() {
        episode.addObserver(self, forKeyPath: "styleFontColor", options: [.new], context: &MovieViewController.fontPreviewTrackContext)
        episode.addObserver(self, forKeyPath: "styleFontFamily", options: [.new], context: &MovieViewController.fontPreviewTrackContext)
        episode.addObserver(self, forKeyPath: "styleFontShadow", options: [.new], context: &MovieViewController.fontPreviewTrackContext)
        episode.addObserver(self, forKeyPath: "styleFontSize", options: [.new], context: &MovieViewController.fontPreviewTrackContext)
        episode.addObserver(self, forKeyPath: "styleFontWeight", options: [.new], context: &MovieViewController.fontPreviewTrackContext)
    }


    func refreshFontToReflectStyleChanges() {
        var postScriptName = "Helvetica"
        let size = self.episode.styleFontSize ?? "53"
        guard let arrayofSubs = NSFontManager.shared.availableMembers(ofFontFamily: self.episode.styleFontFamily ?? "Helvetica"),
            let floatSize = Float(size) else { return }
        var resultingSub:[String] = []
        for i in 0..<arrayofSubs.count {
            if let nameOfSubFamily = arrayofSubs[i][1] as? String {
                if nameOfSubFamily == self.episode.styleFontWeight {
                    postScriptName = arrayofSubs[i][0] as? String ?? "Helvetica"
                    break
                }
            }
        }
        guard let desiredFont = NSFont.init(name: postScriptName, size: CGFloat(floatSize)) else { return }
        self.captionPreviewLabel.font = desiredFont
        self.captionPreviewLabel.textColor = NSColor(hexString: self.episode.styleFontColor ?? "#ffffff")
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

        if type == .srt {
            text = Exporter.generateSRTFromArray(arrayForCaption: copiedArray)
        } else if type == .txt {
            text = Exporter.generateTXTFromArray(arrayForCaption: copiedArray)
        } else if type == .fcpXML {
            text = Exporter.generateFCPXMLFromArray(episode: episode, player: episode.player, arrayForCaption: copiedArray, withoutAVPlayer: false)
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

    func dismantleOldMovieVC() {
        AppDelegate.setCurrentEpisodeTitle(nil)
        self.captionPreviewLabel.stringValue = ""
        recentTimer?.invalidate()
        volumeSlider.floatValue = 1
        speedSlider.floatValue = 1
        self.videoPreviewContainerView.guid = nil
        for task in accumulatedMainQueueTasks {
            task.cancel()
        }
        NotificationCenter.default.removeObserver(self)
        self.playerView.player?.safelyRemoveObserver(self, forKeyPath: "rate")
        if (episode != nil) {
            self.episode.player?.safelyRemoveObserver(self, forKeyPath: "rate")
            episode.safelyRemoveObserver(self, forKeyPath: "arrayForCaption")
            if let arr = self.episode.arrayForCaption?.array as? [CaptionLine] {
                for line in arr {
                    line.safelyRemoveObserver(self, forKeyPath: "caption")
                    line.safelyRemoveObserver(self, forKeyPath: "startingTime")
                    line.safelyRemoveObserver(self, forKeyPath: "endingTime")
                }
            }
            episode.safelyRemoveObserver(self, forKeyPath: "styleFontColor")
            episode.safelyRemoveObserver(self, forKeyPath: "styleFontFamily")
            episode.safelyRemoveObserver(self, forKeyPath: "styleFontShadow")
            episode.safelyRemoveObserver(self, forKeyPath: "styleFontSize")
            episode.safelyRemoveObserver(self, forKeyPath: "styleFontWeight")
        }

        self.subtitleTrackContainerView.stopTracking()
        for (_, view) in cachedCaptionViews {
            view.removeFromSuperview()
        }
        for view in videoPreviewContainerView.subviews {
            view.removeFromSuperview()
        }
        self.cachedCaptionViews = [:]
        self.subtitleTrackContainerView.subviews = []
        self.videoPreviewContainerView.subviews = []
        self.waveformImageView.image = nil
        self.progressView.setFrameOrigin(NSPoint(x: 0, y: self.progressView.frame.origin.y))
    }

    func configurateMovieVC() {
        if let url = self.episode.videoURL {
            self.playVideo(url)
        } else {
            self.episode.player = AVPlayer()
            self.playerView.player = self.episode.player
            self.episode.player?.addObserver(self, forKeyPath: "rate", options: [.new], context: &MovieViewController.playerPlayrateContext)
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
    private static var fontPreviewTrackContext = 1
    private static var playerPlayrateContext = 5

    func configureTextTrack() {
        self.subtitleTrackContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.subtitleTrackContainerView.frame.size.height))
//        self.subtitleTrackContainerView.layer?.backgroundColor = NSColor.purple.cgColor
        if (episode == nil || episode!.arrayForCaption == nil) { return }
        for captionLine in (episode!.arrayForCaption?.array as! [CaptionLine]) {
            self.addObserverForCaptionLine(captionLine)
        }
        episode.addObserver(self, forKeyPath: "arrayForCaption", options: [.initial, .new], context: &MovieViewController.textTrackContext)
        print(self.subtitleTrackContainerView.bounds)
        self.subtitleTrackContainerView.startTracking()
        self.subtitleTrackContainerView.delegate = self
    }

    func checkForCaptionDirectManipulation(with event: NSEvent) {
        if (self.episode == nil || self.episode.player == nil || self.episode.videoURL == nil || self.episode.player?.currentItem == nil) {
            return
        }

        let timePoint = correspondingTimeAtEvent(event)
        let (line1, line2, cursorType) = correspondingCaptionAtLocation(timePoint: timePoint)
        if cursorType != .normal {
            self.setStateForCaption(line1, state: .normal)
            self.setStateForCaption(line2, state: .normal)
        }
        switch cursorType {
        case .resizeLeft:
            self.view.window?.disableCursorRects()
            NSCursor.resizeLeft.set()
        case .resizeRight:
            self.view.window?.disableCursorRects()
            NSCursor.resizeRight.set()
        case .resizeLeftRight:
            self.view.window?.disableCursorRects()
            NSCursor.resizeLeftRight.set()
        default:
            self.view.window?.enableCursorRects()
            NSCursor.arrow.set()
        }
    }

    func correspondingTimeAtEvent(_ event: NSEvent) -> Float {
        let location = self.subtitleTrackContainerView.convert(event.locationInWindow, from: nil).x
        print(location)
        let percentage = Float(location / self.timelineLengthPixels)
        let timePoint = percentage * self.calculatedDuration
        return timePoint
    }

    let draggingMargin: Float = 0.25

    func correspondingCaptionAtLocation(timePoint: Float) -> (line1: CaptionLine?, line2: CaptionLine?, cursorType: CursorType) {
        if let eparr = episode.arrayForCaption?.array as? [CaptionLine] {
            if eparr.count < 2 {
                return (nil, nil, .normal)
            }
            for i in 0..<eparr.count - 1 {
                let captionLine = eparr[i]
                let captionLineNext = eparr[i + 1]

                let diffStarting = timePoint - captionLine.startingTime
                let diffEnding = timePoint - captionLine.endingTime
                let diffThisNext = abs(captionLineNext.startingTime - captionLine.endingTime)

                let diffNextStartThisEnd = (captionLineNext.startingTime - captionLine.endingTime)

                if diffThisNext < 0.1 && abs(diffEnding) < 0.1 {
                    return (captionLine, captionLineNext, .resizeLeftRight)
                } else if timePoint > captionLine.endingTime && timePoint < captionLineNext.startingTime + draggingMargin && timePoint >= captionLineNext.startingTime {
                    return (captionLineNext, nil, .resizeRight)
                } else if timePoint > captionLineNext.startingTime && abs(diffStarting) <= draggingMargin {
                    print(".resizeRight, diffStarting:\(diffStarting)")
                    return (captionLine, nil, .resizeRight)
                } else if abs(diffEnding) <= draggingMargin {
                    print(".resizeLeft, diffEnding:\(diffEnding)")
                    return (captionLine, nil, .resizeLeft)
                } else {
                    print(".passing, diffStarting:\(diffStarting), diffEnding: \(diffEnding)")
                }
            }

            for i in 0..<eparr.count {
                let captionLine = eparr[i]
                if timePoint > captionLine.startingTime && timePoint < captionLine.startingTime + draggingMargin {
                    return (captionLine, nil, .resizeRight)
                } else if timePoint < captionLine.endingTime && timePoint > captionLine.endingTime - draggingMargin {
                    return (captionLine, nil, .resizeLeft)
                } else if timePoint > captionLine.startingTime + draggingMargin && timePoint < captionLine.endingTime - draggingMargin {
                    return (captionLine, nil, .moveTime)
                }
            }
        }
        return (nil, nil, .normal)
    }

    enum CursorType {
        case resizeLeftRight
        case resizeRight
        case resizeLeft
        case moveTime
        case normal
    }

    func trackingMouseUp(with event: NSEvent) {
        commonBetweenDraggedAndUp(with: event)
        commonCursorReturn()
    }

    func commonCursorReturn() {
        self.setStateForCaption(cachedDownLine1, state: .normal)
        self.setStateForCaption(cachedDownLine2, state: .normal)
        cachedDownLine1 = nil
        cachedDownLine2 = nil
        cachedOperation = nil
        self.view.window?.enableCursorRects()
        NSCursor.arrow.set()
    }

    var cachedDownLine1: CaptionLine?
    var cachedDownLine2: CaptionLine?
    var cachedOperation: CursorType?

    func trackingMouseDown(with event: NSEvent) {
        let timePoint = correspondingTimeAtEvent(event)
        let cache = correspondingCaptionAtLocation(timePoint: timePoint)
        cachedDownLine1 = cache.line1
        cachedDownLine2 = cache.line2
        cachedOperation = cache.cursorType
    }

    func trackingMouseDragged(with event: NSEvent) {
        commonBetweenDraggedAndUp(with: event)
    }

    let errorAvoidanceThreshold: Float = 0.3

    func setStateForCaption(_ caption: CaptionLine?, state: CaptionManipulationState?) {
        if let line = caption, let guid = line.guidIdentifier, let matchedView = self.cachedCaptionViews[guid], let st = state {
            matchedView.state = st
            matchedView.bringToFront()
            matchedView.setNeedsDisplay(matchedView.bounds)
        }
    }

    func commonBetweenDraggedAndUp(with event: NSEvent) {
        let timePoint = correspondingTimeAtEvent(event)
        if let operation = cachedOperation {
            if (operation == .resizeLeftRight) {
                if (timePoint > cachedDownLine1!.startingTime + errorAvoidanceThreshold && timePoint < cachedDownLine2!.endingTime - errorAvoidanceThreshold) {
                    cachedDownLine1!.endingTime = timePoint
                    cachedDownLine2!.startingTime = timePoint
                    self.setStateForCaption(cachedDownLine1, state: .dragging)
                    self.setStateForCaption(cachedDownLine2, state: .dragging)
                }
            } else if (operation == .resizeLeft) {
                let newPotentialTimeIfCommitting = timePoint - cachedDownLine1!.startingTime
                if (newPotentialTimeIfCommitting > errorAvoidanceThreshold) {
                    self.setStateForCaption(cachedDownLine1, state: .dragging)
                    cachedDownLine1?.endingTime = timePoint
                }
            } else if (operation == .resizeRight) {
                let newPotentialTimeIfCommitting = cachedDownLine1!.endingTime - timePoint
                if (newPotentialTimeIfCommitting > errorAvoidanceThreshold) {
                    cachedDownLine1?.startingTime = timePoint
                    self.setStateForCaption(cachedDownLine1, state: .dragging)
                }
            } else if (operation == .moveTime) {
                let delta = event.deltaX
                let deltaTimeSeconds = Float(delta / self.timelineLengthPixels) * self.calculatedDuration
                let newStartIfCommitting = cachedDownLine1!.startingTime + deltaTimeSeconds
                let newEndIfCommtting = cachedDownLine1!.endingTime + deltaTimeSeconds
                if (newStartIfCommitting > 0 && newEndIfCommtting < self.calculatedDuration) {
                    cachedDownLine1?.startingTime = newStartIfCommitting
                    cachedDownLine1?.endingTime = newEndIfCommtting
                    self.setStateForCaption(cachedDownLine1, state: .dragging)
                }
            }
        }
    }

    func restoreOriginalPointer() {
        self.view.window?.enableCursorRects()
        NSCursor.arrow.set()
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
        guard context == &MovieViewController.textTrackContext || context == &MovieViewController.fontPreviewTrackContext || context == &MovieViewController.playerPlayrateContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if context == &MovieViewController.textTrackContext {
            self.observeMovieCaptionTextValue(forKeyPath: keyPath, of: object, change: change)
        } else if context == &MovieViewController.fontPreviewTrackContext {
            self.observeFontStyleChangedValue(forKeyPath: keyPath, of: object, change: change)
        } else if context == &MovieViewController.playerPlayrateContext {
            if keyPath == "rate" {
                if let player = self.playerView.player {
                    if player.rate > 0 {
                        self.playPauseImageView.image = NSImage(named: "tb_pause")
                    } else {
                        self.playPauseImageView.image = NSImage(named: "tb_play")
                    }
                }
            }
        }
    }

    func observeFontStyleChangedValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        refreshFontToReflectStyleChanges()
    }

    func observeMovieCaptionTextValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
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
    }

    func configureWaveTrack() {
        let asset = self.episode.player?.currentItem?.asset
        let audioTracks:[AVAssetTrack] = asset!.tracks(withMediaType: AVMediaType.audio)
        if let track:AVAssetTrack = audioTracks.first{
            //let timeRange = CMTimeRangeMake(CMTime(seconds: 0, preferredTimescale: 1000), CMTime(seconds: 1, preferredTimescale: 1000))
            let timeRange:CMTimeRange? = nil
            self.waveformImageView.setFrameSize(NSSize(width: self.timelineLengthPixels, height: timeLineSegmentHeight)) // should this be self.waveformImageView.frame.size.height?
            var cachedBounds = self.waveformImageView.bounds.size
            cachedBounds.width = self.timelineLengthPixels
            let width = Int(timelineLengthPixels)

            DispatchQueue.global(qos: .background).async {
                // Let's extract the downsampled samples
//                let samplingStartTime = CFAbsoluteTimeGetCurrent()
                let capturedGUID = self.episode.guidIdentifier
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
                                                                                      borderWidth: 0,
                                                                                      borderColor: WaveColor.gray)
//                                            let drawingStartTime = CFAbsoluteTimeGetCurrent()
                                            if let imageDrawn = WaveFormDrawer.image(with: sampling, and: configuration) {
                                                let task = DispatchWorkItem {
                                                    if (self.episode.guidIdentifier == capturedGUID) {
                                                        self.waveformImageView.image = imageDrawn
                                                    }
                                                }
                                                self.accumulatedMainQueueTasks.append(task)
                                                DispatchQueue.main.async(execute: task)
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

    let thumbnailPerSeconds: Float64 = 2

    var accumulatedMainQueueTasks: [DispatchWorkItem] = []

    func configureVideoThumbnailTrack() {
        self.videoPreviewContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.videoPreviewContainerView.frame.size.height))
        // one snapshot every 10 seconds
        DispatchQueue.global(qos: .background).async {
            let asset = self.episode.player?.currentItem?.asset
            if asset == nil {
                return
            }
            let imageGenerator = AVAssetImageGenerator(asset: asset!)
            if let duration = self.episode.player?.currentItem?.duration {
                let totalSeconds = CMTimeGetSeconds(duration)
                var secondIndex: Float64 = 1
                var imageIndex: Int = 0
                if (totalSeconds.isNaN) {
                    return
                }
                let numberOfThumbnails = Int(totalSeconds / self.thumbnailPerSeconds)
                let widthOfThumbnail = self.timelineLengthPixels / CGFloat(numberOfThumbnails)
                var generatedImages: [NSImage] = []
                while (secondIndex < totalSeconds) {
                    let screenshotTime = CMTime(seconds: Double(secondIndex), preferredTimescale: 1)
                    do {
                        let imageRef = try? imageGenerator.copyCGImage(at: screenshotTime, actualTime: nil)
                        let image = NSImage(cgImage: imageRef!, size: NSSize(width: imageRef!.width, height: imageRef!.height))
                        generatedImages.append(image)
                        let capturedIndex = imageIndex
                        let capturedGUID = self.episode.guidIdentifier
                        let task = DispatchWorkItem {
                            let imageView = VideoPreviewImageView(frame: NSRect(x: widthOfThumbnail * CGFloat(capturedIndex), y: 0, width: widthOfThumbnail, height: self.timeLineSegmentHeight))
                            imageView.imageScaling = .scaleProportionallyUpOrDown
                            imageView.imageFrameStyle = .grayBezel
                            imageView.image = image
                            imageView.correspondingGUID = capturedGUID
                            if (capturedGUID != nil) {
                                self.videoPreviewContainerView.addSubImageView(capturedGUID: capturedGUID, imageView: imageView)
                            }
                        }
                        self.accumulatedMainQueueTasks.append(task)
                        DispatchQueue.main.async(execute: task)
                    } catch {
                        "Can't take screenshot: \(error)"
                    }
                    secondIndex += self.thumbnailPerSeconds
                    imageIndex += 1
                }
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
        let interval = CMTime(value: 1, timescale: 30)
        self.episode.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in
            self.updatePersistedFramerate()

            let seconds = CMTimeGetSeconds(progressTime)
            let timeCode = Helper.secondFloatToString(float: seconds)
            self.timeLabel.stringValue = timeCode

            //lets move the slider thumb
            if let duration = self.episode.player?.currentItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                let percent = CGFloat(seconds / durationSeconds)
                let originPoint = NSPoint(x: self.timelineLengthPixels * percent + self.offsetPixelInScrollView - self.redBarOffsetInScrollView, y: self.progressView.frame.origin.y)
                if (originPoint.x.isNaN || originPoint.y.isNaN) {
                    return
                }
                self.progressView.setFrameOrigin(originPoint)
            }

            var matched: Bool = false
            self.episode.arrayForCaption?.enumerateObjects({ (element, index, stop) in
                if let captionLine = element as? CaptionLine {
                    if let s = self.episode.player?.currentTime().seconds {
                        let sec = Float(s)
                        if sec > captionLine.startingTime && sec < captionLine.endingTime {
                            self.captionPreviewLabel.stringValue = captionLine.caption ?? ""
                            matched = true
                        }
                    }
                }
            })
            if matched == false {
                self.captionPreviewLabel.stringValue = ""
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

    var shouldResumePlayingAfterPanEnds = false

    @IBAction func pannedToNewTimelineIndex(_ sender: NSPanGestureRecognizer) {
        if sender.state == .began {
            if let player = playerView.player {
                if player.rate > 0 {
                    shouldResumePlayingAfterPanEnds = true
                    playerView.player?.pause()
                } else {
                    shouldResumePlayingAfterPanEnds = false
                }
            }
        } else if sender.state == .ended || sender.state == .cancelled || sender.state == .failed {
            if shouldResumePlayingAfterPanEnds {
                playerView.player?.play()
            }
        }
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

            let timeScale = self.episode.player?.currentItem?.asset.duration.timescale ?? 1
            let exactTime = CMTime(seconds: value, preferredTimescale: timeScale)
            self.episode.player!.seek(to: exactTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }


    // Mark: - Middle buttons

    @IBAction func volumeChanged(_ sender: NSSlider) {
        self.playerView.player?.volume = sender.floatValue
    }

    @IBAction func speedChanged(_ sender: NSSlider) {
        self.playerView.player?.rate = sender.floatValue
    }

    @IBAction func rewindByOneFrame(_ sender: Any) {
        if let item = self.playerView.player?.currentItem {
            item.step(byCount: -1)
        }
    }

    @IBAction func rewindByFiveSeconds(_ sender: Any) {
        movePlayheadBySeconds(-5)
    }

    func movePlayheadBySeconds(_ seconds: Double) {
        if let duration = self.episode.player?.currentItem?.duration, let currentTime = self.episode.player?.currentTime().seconds {
//            let totalSeconds = CMTimeGetSeconds(duration)
            let value = currentTime + seconds
//            if value >= 0 && value <= totalSeconds {
                let timeScale = self.episode.player?.currentItem?.asset.duration.timescale ?? 1
                let exactTime = CMTime(seconds: value, preferredTimescale: timeScale)
                self.episode.player!.seek(to: exactTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
//            }
        }
    }

    @IBAction func playPauseClicked(_ sender: Any) {
        if let player = playerView.player {
            if player.rate > 0 {
                self.playerView.player?.pause()
            } else {
                self.playerView.player?.play()
            }
        }
    }

    @IBAction func forwardByFiveSeconds(_ sender: Any) {
        movePlayheadBySeconds(5)
    }

    @IBAction func forwardByOneFrame(_ sender: Any) {
        if let item = self.playerView.player?.currentItem {
            item.step(byCount: 1)
        }
    }


}


