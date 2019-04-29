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

@objc class MovieViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, SubtitleTrackContainerViewDelegate, NSWindowDelegate {
    @IBOutlet weak var playerView: AVPlayerView!
    @IBOutlet weak var timeLabel: NSTextField!

    @IBOutlet weak var progressView: NSView!
    @IBOutlet weak var progressViewColorLineBox: NSBox!

    @IBOutlet weak var subtitleTrackContainerView: SubtitleTrackContainerView!
    @IBOutlet weak var videoPreviewContainerView: VideoPreviewContainerView!
    @IBOutlet weak var waveformPreviewContainerBox: CaptionWaveformBox!

    @IBOutlet weak var timelineScrollView: NSScrollView!
    @IBOutlet weak var timelineOverallView: TimelineOverallView!
    @IBOutlet weak var captionPreviewLabel: NSTextField!
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBOutlet weak var speedSlider: NSSlider!
    @IBOutlet weak var playPauseImageView: NSImageView!
    @IBOutlet weak var captionBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var customHintContainerView: NSView!
    @IBOutlet weak var welcomingLabel: NSTextField!
    @IBOutlet weak var guidanceLabel: NSTextField!
    @IBOutlet weak var openFileOrRelinkButton: NSButton!
    var cachedCaptionViews: [String: CaptionBoxView] = [:]
    var episode: EpisodeProject!

    func removeCaptionFromTimeline(caption: CaptionLine) {
        if let capID = caption.guidIdentifier, let existing = self.cachedCaptionViews[capID] {
            existing.removeFromSuperview()
            cachedCaptionViews.removeValue(forKey: capID)
        }
    }

    //MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(OSX 10.11, *) {
            timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        } else {
            timeLabel.font = NSFont.systemFont(ofSize: 15)
        }
        if #available(OSX 10.14, *) {
            timelineScrollView.appearance = NSAppearance.init(named: .darkAqua)
            timelineScrollView.backgroundColor = .controlBackgroundColor
        } else {
            timelineScrollView.backgroundColor = NSColor.init(calibratedRed: 20/255, green: 20/255, blue: 20/255, alpha: 1)
        }
        playerView.wantsLayer = true
        customHintContainerView.wantsLayer = true
        captionPreviewLabel.wantsLayer = true
        customHintContainerView.layer?.zPosition = 1
        captionPreviewLabel.layer?.zPosition = 1
        #if DEBUG
        print("customHintContainerView.layer is: \(String(describing: customHintContainerView.layer)), captionPreviewLabel.layer is: \(String(describing: captionPreviewLabel.layer))")
        #endif
        AppDelegate.subtitleVC()?.dismantleSubtitleVC()
        AppDelegate.subtitleVC()?.configurateSubtitleVC()

    }

    override func viewDidAppear() {
        self.view.window?.delegate = self
        self.playerView.postsFrameChangedNotifications = true
    }

    @objc func frameDidChangeNotification(_ sender: Any) {
        refreshFontRelativeSize()
    }

    // MARK: - Buttons and IBActions
    @IBAction func openFile(_ sender: Any) {
        if self.episode == nil {
            Helper.displayInteractiveSheet(title: "Create a Project", text: "To import a video, you need to create a project. Click on your newly created project in the sidebar, then import a video to create captions.", firstButtonText: "Create Project", secondButtonText: "Dismiss") { (result) in
                if result {
                    AppDelegate.sourceListVC()?.addNewProject()
                    AppDelegate.sourceListVC()?.updateSelectRow(index: 0)
                }
            }
            return
        }
        if self.episode.videoURL != nil {
            if FileManager.default.fileExists(atPath: self.episode.videoURL!) {
                Helper.displayInteractiveSheet(title: "Create new project?", text: "The current project already has an associated video. Would you like to create a new project instead?", firstButtonText: "Create New Project", secondButtonText: "Cancel", callback: { (firstButtonClicked) in
                    if (firstButtonClicked) {
                        AppDelegate.sourceListVC()?.addNewProject()
                        AppDelegate.sourceListVC()?.updateSelectRow(index: 0)
                    }
                })
            } else {
                handleRelinkVideo()
            }
            return
        }

        Helper.displayOpenFileDialog { (hasFile, result, path) in
            if !hasFile {
                return
            }
            if let id = self.episode.guidIdentifier {
                Helper.removeFilesUnderURL(urlPath: "~/Library/Caches/com.dim.Caption/audio_thumbnail/\(id)")
                Helper.removeFilesUnderURL(urlPath: "~/Library/Caches/com.dim.Caption/video_thumbnail/\(id)")
                self.dismantleOldMovieVC()
            }
            if self.episode == nil {
                AppDelegate.sourceListVC()?.updateSelectRow(index: 0)
            }
            self.episode.arrayForCaption = []
            self.episode.videoDescription = result!.lastPathComponent
            self.playVideo(result!)
        }
    }

    func playVideo(_ videoURL: URL) {
        self.episode.videoURL = videoURL.path
        AppSandboxFileAccess()?.accessFileURL(videoURL, persistPermission: true, with: {
            self.episode.player = AVPlayer(url: videoURL)
            self.customHintContainerView.isHidden = true
            self.episode.player?.addObserver(self, forKeyPath: "rate", options: [.new], context: &MovieViewController.playerPlayrateContext)
            self.playerView.player = self.episode.player
            self.episode.player?.addObserver(self, forKeyPath: "status", options: [.new], context: &MovieViewController.playerReadinessContext)
        })
    }

    func updatePersistedFramerate() {
        if self.episode != nil {
            if let tracks = self.episode.player?.currentItem?.asset.tracks {
                if !tracks.isEmpty {
                    let framerate = tracks[0].nominalFrameRate
                    self.episode.framerate = framerate
                    AppDelegate.fontVC()?.configureAllMetadata()
                }
            }
        }
    }

    @objc func updateLoadVideo() {
        self.updatePersistedFramerate()

        if self.episode.arrayForCaption?.count ?? 0 <= 0 {
            let description = NSEntityDescription.entity(forEntityName: "CaptionLine", in: Helper.context!)
            let cap = CaptionLine(entity: description!, insertInto: Helper.context!)
            cap.guidIdentifier = NSUUID().uuidString
            cap.caption = ""
            cap.startingTime = Float(CMTimeGetSeconds((episode.player?.currentTime())!))
            cap.endingTime = 0

            self.episode.addToArrayForCaption(cap)
            self.episode.creationDate = NSDate()
        }

        self.episode.videoDuration = Float(CMTimeGetSeconds((self.episode.player?.currentItem?.asset.duration)!))
        self.populateThumbnail()
        self.configureOverallScrollView()
        self.configurateRedBar()
        self.configureTextTrack()
        self.configureVideoThumbnailTrack()

        self.configureWaveTrack()
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

        if self.episode.styleFontShadow != 0 {
            let shadow: NSShadow = NSShadow()
            shadow.shadowBlurRadius = 1.07
            shadow.shadowOffset = NSMakeSize(1, 1.5)
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.75)
            self.captionPreviewLabel.shadow = shadow
        } else {
            self.captionPreviewLabel.shadow = nil
        }

        refreshFontRelativeSize()
    }

    var videoRect: CGRect {
        get {
            guard let item = self.playerView.player?.currentItem, let track = item.asset.tracks(withMediaType: .video).first else {return CGRect.zero}
            let trackSize = track.naturalSize
            let videoViewSize = self.playerView.bounds.size
            let trackRatio = trackSize.width / trackSize.height
            let videoViewRatio = videoViewSize.width / videoViewSize.height
            var newSize: CGSize

            if (videoViewRatio > trackRatio) {
                newSize = CGSize(width: trackSize.width * videoViewSize.height / trackSize.height, height: videoViewSize.height)
            } else {
                newSize = CGSize(width: videoViewSize.width, height: trackSize.height * videoViewSize.width / trackSize.width);
            }

            let newX = (videoViewSize.width - newSize.width) / 2;
            let newY = (videoViewSize.height - newSize.height) / 2;

            return CGRect(x: newX, y: newY, width: newSize.width, height: newSize.height)
        }
    }

    func refreshFontRelativeSize() {
        guard let asset = self.playerView.player?.currentItem?.asset else {return}
        let videoFrame = videoRect

        if isAudioOnly {
            captionBottomConstraint.constant = 14
        } else {
            let diffHeights = (playerView.frame.height - videoFrame.height) / 2
            if diffHeights > 0 {
                captionBottomConstraint.constant = 14 + diffHeights
            } else {
                captionBottomConstraint.constant = 14
            }
        }

        let shrinkingPercentage = videoFrame.size.width / asset.tracks[0].naturalSize.width

        let size = self.episode.styleFontSize ?? "53"
        let sizeFloat = CGFloat(Float(size) ?? 53)
        let shrunkFontSize = sizeFloat * shrinkingPercentage
        guard let oldFont = self.captionPreviewLabel.font else {return}
        let newFont = NSFont(descriptor: oldFont.fontDescriptor, size: shrunkFontSize)
        self.captionPreviewLabel.font = newFont
    }

    var isAudioOnly: Bool {
        get {
            guard let asset = self.playerView.player?.currentItem?.asset else { return false }
            if asset.tracks(withMediaType: .video).count == 0 { return true }
            return false
        }
    }

    var isVideoOnly: Bool {
        get {
            guard let asset = self.playerView.player?.currentItem?.asset else { return false }
            if asset.tracks(withMediaType: .audio).count == 0 { return true }
            return false
        }
    }

    func populateThumbnail() {
        if (self.episode.thumbnailURL == nil) {
            if isAudioOnly { return }
            let sourceURL = self.episode!.videoURL!
            let asset = AVAsset(url: URL(fileURLWithPath: sourceURL))
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            let time = CMTimeMake(value: 1, timescale: 1)
            let imageRef = try! imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = NSImage(cgImage: imageRef, size: NSSize(width: imageRef.width, height: imageRef.height))
            _ = self.applicationDataDirectory().appendingPathComponent("thumbnails")
            do {try FileManager.default.createDirectory(at: self.applicationDataDirectory().appendingPathComponent("thumbnails"), withIntermediateDirectories: true, attributes: nil)
            } catch {print(error)}
            let destinationURL = self.applicationDataDirectory().appendingPathComponent("thumbnails").appendingPathComponent("\(NSUUID().uuidString).png")
            let result = thumbnail.pngWrite(to: destinationURL)
            print("Writing thumbnail: \(result)")
            self.episode.thumbnailURL = destinationURL.path
        }
    }

    func saveTXTToDisk(_ sender: Any) {
        Saver.saveEpisodeToDisk(self.episode, type: .txt)
    }
    
    func saveSRTToDisk(_ sender: Any) {
        Saver.saveEpisodeToDisk(self.episode, type: .srt)
    }
    
    func saveFCPXMLToDisk(_ sender: Any) {
        Saver.saveEpisodeToDisk(self.episode, type: .fcpXML)
    }

    func saveASSToDisk(_ sender: Any) {
        Saver.saveEpisodeToDisk(self.episode, type: .ass)
    }

    func dismantleSetTimelineLengthToZero() {
        self.timelineOverallView.setFrameSize(NSSize(width: 0, height: self.timelineOverallView.frame.size.height))
    }

    func dismantleOldMovieVC() {
        self.timeLabel.stringValue = "00:00:00,000"
        welcomingLabel.stringValue = "Welcome to\nQuick Caption"
        guidanceLabel.stringValue = "To create captions, click on the       button on the toolbar to open an existing video or audio file."
        dismantleSetTimelineLengthToZero()
        openFileOrRelinkButton.image = NSImage(named: "import")
        customHintContainerView.isHidden = false
        AppDelegate.setCurrentEpisodeTitle(nil)
        AppDelegate.mainWindow()?.relinkMode = false
        captionBottomConstraint.constant = 14
        self.captionPreviewLabel.stringValue = ""
        self.playerView.player?.safelyRemoveObserver(self, forKeyPath: "status")
        volumeSlider.floatValue = 1
        speedSlider.floatValue = 1
        self.videoPreviewContainerView.guid = nil
        //        if accumulatedMainQueueTasks != nil {
        //            for task in accumulatedMainQueueTasks {
        //            print("Cancelling \(task)")
        //            task.cancel()
        //            }
        //        }
        //        if accumulatedBackgroundQueueTasks != nil {
        //            for task in accumulatedBackgroundQueueTasks {
        //            print("Cancelling \(task)")
        //            task.cancel()
        //            }
        //        }
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
        for view in waveformPreviewContainerBox.contentView!.subviews {
            if (view != nil && view.tag != -1) {
                view.removeFromSuperview()
            }
        }
        self.cachedCaptionViews = [:]
        self.subtitleTrackContainerView.subviews = []
        self.videoPreviewContainerView.subviews = []
        //        self.waveformPreviewContainerBox.subviews = []
        self.progressView.setFrameOrigin(NSPoint(x: 0, y: self.progressView.frame.origin.y))
    }

    func setupForRelinkVideo() {
        AppDelegate.mainWindow()?.relinkMode = true
        openFileOrRelinkButton.image = NSImage(named: "link")
        welcomingLabel.stringValue = "Relinking Is\nRequired"
        guidanceLabel.stringValue = "To relink your video, click on the       button on the toolbar. Then, you will be able to continue working on the project."
    }

    func handleRelinkVideo() {
        Helper.displayInteractiveSheet(title: "Video deleted or moved", text: "The video associated with this captioning project cannot be found. It may have been deleted or moved. Please relink the video.", firstButtonText: "Relink Video", secondButtonText: "Cancel") { (shouldRelink) in
            if (shouldRelink) {
                Helper.displayOpenFileDialog(callback: { (hasSelected, fileURL, filePath) in
                    guard let newURL = fileURL else {return}
                    self.episode.videoURL = newURL.path
                    if FileManager.default.fileExists(atPath: newURL.path) {
                        self.playVideo(newURL)
                    } else {
                        Helper.displayInformationalSheet(title: "Relinking failed", text: "Unable to relink to your newly selected media.")
                    }
                })
            }
        }
    }

    func configurateMovieVC() {
        if self.episode == nil {
            return
        }
        self.episode.modifiedDate = NSDate()
        NotificationCenter.default.addObserver(self, selector: #selector(frameDidChangeNotification(_:)), name: NSView.frameDidChangeNotification, object: self.playerView)

        if let url = self.episode.videoURL {
            if FileManager.default.fileExists(atPath: url) {
                self.playVideo(URL(fileURLWithPath: url))
            } else {
                setupForRelinkVideo()
            }
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
        // return timelineScrollView.frame.height / 3
        return 64
    }

    // MARK: - Custom Timeline
    func configureOverallScrollView() {
        self.timelineOverallView.setFrameSize(NSSize(width: timelineLengthPixels + 100, height: self.timelineOverallView.frame.size.height))
    }

    private static var textTrackContext = 0
    private static var fontPreviewTrackContext = 1
    private static var playerPlayrateContext = 5
    private static var playerReadinessContext = 6

    func configureTextTrack() {
        self.subtitleTrackContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.subtitleTrackContainerView.frame.size.height))
        // self.subtitleTrackContainerView.layer?.backgroundColor = NSColor.purple.cgColor
        if (episode == nil || episode!.arrayForCaption == nil) { return }
        for captionLine in (episode!.arrayForCaption?.array as! [CaptionLine]) {
            self.addObserverForCaptionLine(captionLine)
        }
        episode.addObserver(self, forKeyPath: "arrayForCaption", options: [.initial, .new], context: &MovieViewController.textTrackContext)
        // print(self.subtitleTrackContainerView.bounds)
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
        //        print(location)
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

                // let diffNextStartThisEnd = (captionLineNext.startingTime - captionLine.endingTime)

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
                    // return (captionLine, nil, .selection)
                    // print(".passing, diffStarting:\(diffStarting), diffEnding: \(diffEnding)")
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
        // case selection
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
        guard context == &MovieViewController.textTrackContext || context == &MovieViewController.fontPreviewTrackContext || context == &MovieViewController.playerPlayrateContext || context == &MovieViewController.playerReadinessContext else {
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
        } else if context == &MovieViewController.playerReadinessContext {
            guard let player = self.playerView.player else {return}
            if player.status == .readyToPlay {
                self.updateLoadVideo()
                // episode.player?.play()
            }
        }
    }

    func observeFontStyleChangedValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        refreshFontToReflectStyleChanges()
    }

    func observeMovieCaptionTextValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?) {
        for aChange in change ?? [:] {
            // print("The change key: \(aChange.key), value: \(aChange.value)")
            if let indexSet = aChange.value as? NSIndexSet {
                // print("The NSIndexSet is: \(indexSet)")
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

    var audioImageSlicePerSeconds: Double = 15
    var nudgingOffsetForNonLastSegment: Double = 1
    var waveformTrackCacheRoot = ("~/Library/Caches/com.dim.Caption/audio_thumbnail" as NSString).expandingTildeInPath as String
    var videoThumbnailTrackCacheRoot = ("~/Library/Caches/com.dim.Caption/video_thumbnail" as NSString).expandingTildeInPath as String

    func configureWaveTrack() {
        let waveTrackCacheFolder = "\(waveformTrackCacheRoot)/\(self.episode.guidIdentifier ?? "unknown")"
        let urlForCreation = URL(fileURLWithPath: waveTrackCacheFolder, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: urlForCreation, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        let asset = self.episode.player?.currentItem?.asset
        self.waveformPreviewContainerBox.setFrameSize(NSSize(width: self.timelineLengthPixels, height: timeLineSegmentHeight))
        let audioTracks:[AVAssetTrack] = asset!.tracks(withMediaType: AVMediaType.audio)
        if isVideoOnly {
            return
        }
        let computedGUIDForTask = NSUUID().uuidString
        waveformPreviewContainerBox.guid = computedGUIDForTask
        let timeScale = self.episode.player?.currentItem?.asset.duration.timescale ?? 1
        guard let track: AVAssetTrack = audioTracks.first, let duration = self.episode.player?.currentItem?.asset.duration else {return}
        let durationSeconds = duration.seconds
        let numberOfSlicesDouble: Double = durationSeconds / audioImageSlicePerSeconds
        let numberOfSlicesInt: Int = Int(numberOfSlicesDouble)
        let timeInLastSlice = durationSeconds - Double(numberOfSlicesInt * Int(audioImageSlicePerSeconds))

        for i in 0...numberOfSlicesInt {
            var timeInThisSlice = self.audioImageSlicePerSeconds
            if i == numberOfSlicesInt {
                timeInThisSlice = timeInLastSlice
            }
            var nudgedDuration = timeInThisSlice
            if i != numberOfSlicesInt {
                nudgedDuration += self.nudgingOffsetForNonLastSegment
            }
            let pointOffsetXStart = CGFloat((Double(i) * self.audioImageSlicePerSeconds) / durationSeconds) * self.timelineLengthPixels
            let pointWidth = CGFloat(nudgedDuration / durationSeconds) * self.timelineLengthPixels

            if FileManager.default.fileExists(atPath: "\(waveTrackCacheFolder)/\(i).png") {
                let imageRect = NSRect(x: pointOffsetXStart, y: 0, width: pointWidth, height: self.timeLineSegmentHeight)
                let imageView = NSImageView(frame: imageRect)
                imageView.image = NSImage.init(contentsOfFile: "\(waveTrackCacheFolder)/\(i).png")
                imageView.tag = 5
                self.waveformPreviewContainerBox.addSubWaveformView(capturedGUID: computedGUIDForTask, imageView: imageView)
            } else {
                let bgTask = DispatchWorkItem {
                    let timeRange = CMTimeRangeMake(start: CMTime(seconds: Double(i) * self.audioImageSlicePerSeconds, preferredTimescale: timeScale), duration: CMTime(seconds: nudgedDuration, preferredTimescale: timeScale))
                    let cachedBounds = CGSize(width: pointWidth, height: self.timeLineSegmentHeight)
                    let width = Int(pointWidth)
                    SamplesExtractor.samples(audioTrack: track, timeRange: timeRange, desiredNumberOfSamples: width, onSuccess: { s, sMax, _ in
                        let sampling = (samples: s, sampleMax: sMax)
                        let configuration = WaveformConfiguration(size: cachedBounds, color: WaveColor(calibratedRed: 77 / 255, green: 103 / 255, blue: 143 / 255, alpha: 1), backgroundColor: WaveColor.clear, style: .gradient, position: .middle, scale: 1, borderWidth: 0, borderColor: WaveColor.clear)
                        if let imageDrawn = WaveFormDrawer.image(with: sampling, and: configuration) {
                            imageDrawn.saveAsFile(with: .png, withName: "\(waveTrackCacheFolder)/\(i).png")
                            let task = DispatchWorkItem {
                                let imageRect = NSRect(x: pointOffsetXStart, y: 0, width: pointWidth, height: self.timeLineSegmentHeight)
                                let imageView = NSImageView(frame: imageRect)
                                imageView.image = imageDrawn
                                imageView.tag = 5
                                self.waveformPreviewContainerBox.addSubWaveformView(capturedGUID: computedGUIDForTask, imageView: imageView)
                            }
                            // self.accumulatedMainQueueTasks.append(task)
                            DispatchQueue.main.async(execute: task)
                        }
                    }, onFailure: { error, id in
                        print("\(id ?? "") \(error)")
                    })
                }
                //                accumulatedBackgroundQueueTasks.append(bgTask)
                DispatchQueue.global(qos: .userInteractive).async(execute: bgTask)
            }

        }

    }

    let thumbnailPerSeconds: Float64 = 2

    // var accumulatedMainQueueTasks: [DispatchWorkItem] = []
    // var accumulatedBackgroundQueueTasks: [DispatchWorkItem] = []

    func configureVideoThumbnailTrack() {
        if isAudioOnly {
            return
        }
        let computedGUIDForTask = NSUUID().uuidString
        videoPreviewContainerView.guid = computedGUIDForTask
        self.videoPreviewContainerView.setFrameSize(NSSize(width: timelineLengthPixels, height: self.videoPreviewContainerView.frame.size.height))
        guard let asset = self.episode.player?.currentItem?.asset else {return}

        let videoThumbnailTrackCacheFolder = "\(videoThumbnailTrackCacheRoot)/\(self.episode.guidIdentifier ?? "unknown")"
        let urlForCreation = URL(fileURLWithPath: videoThumbnailTrackCacheFolder, isDirectory: true)
        do { try FileManager.default.createDirectory(at: urlForCreation, withIntermediateDirectories: true, attributes: nil) }catch { print(error) }

        guard let duration = self.episode.player?.currentItem?.asset.duration else { return }

        let totalSeconds = CMTimeGetSeconds(duration)
        var secondIndex: Float64 = 1
        var imageIndex: Int = 0
        if (totalSeconds.isNaN) {
            return
        }
        let numberOfThumbnails = Int(totalSeconds / self.thumbnailPerSeconds)
        let widthOfThumbnail = self.timelineLengthPixels / CGFloat(numberOfThumbnails)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.maximumSize = CGSize(width: 320, height: 240);

        while (secondIndex < totalSeconds) {
            let screenshotTime = CMTime(seconds: Double(secondIndex), preferredTimescale: 1)
            let capturedIndex = imageIndex
            let tentativePath = "\(videoThumbnailTrackCacheFolder)/\(capturedIndex).jpg"
            if FileManager.default.fileExists(atPath: tentativePath) {
                let taskToLoadImage = DispatchWorkItem {
                    let loadedImage = NSImage.init(contentsOfFile: tentativePath)
                    let taskToPlaceIntoView = DispatchWorkItem {
                        let imageView = VideoPreviewImageView(frame: NSRect(x: widthOfThumbnail * CGFloat(capturedIndex), y: 0, width: widthOfThumbnail, height: self.timeLineSegmentHeight))
                        imageView.imageScaling = .scaleProportionallyUpOrDown
                        imageView.imageFrameStyle = .grayBezel
                        imageView.image = loadedImage
                        self.videoPreviewContainerView.addSubImageView(capturedGUID: computedGUIDForTask, imageView: imageView)
                    }
                    // if taskToPlaceIntoView != nil && self.accumulatedMainQueueTasks != nil {
                    //      self.accumulatedMainQueueTasks.append(taskToPlaceIntoView)
                    // }
                    DispatchQueue.main.async(execute: taskToPlaceIntoView)
                }
                //                self.accumulatedBackgroundQueueTasks.append(taskToLoadImage)
                DispatchQueue.global(qos: .userInitiated).async(execute: taskToLoadImage)
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: screenshotTime)], completionHandler: { (time1, image, time2, result, error) in
                            if result == .succeeded {
                                let image = NSImage(cgImage: image!, size: NSSize(width: image!.width, height: image!.height))
                                let taskToSave = DispatchWorkItem {
                                    image.saveAsFile(with: .jpeg, withName: tentativePath)
                                }
                                //                                self.accumulatedBackgroundQueueTasks.append(taskToSave)
                                DispatchQueue.global(qos: .userInitiated).async(execute: taskToSave)
                                let task = DispatchWorkItem {
                                    let imageView = VideoPreviewImageView(frame: NSRect(x: widthOfThumbnail * CGFloat(capturedIndex), y: 0, width: widthOfThumbnail, height: self.timeLineSegmentHeight))
                                    imageView.imageScaling = .scaleProportionallyUpOrDown
                                    imageView.imageFrameStyle = .grayBezel
                                    imageView.image = image
                                    self.videoPreviewContainerView.addSubImageView(capturedGUID: computedGUIDForTask, imageView: imageView)
                                }
                                //                                self.accumulatedMainQueueTasks.append(task)
                                DispatchQueue.main.async(execute: task)
                            } else {
                                print("Failed with: \(String(describing: error))")
                            }
                        })
                    } catch {print("Error: \(error)")}

                }
                // self.accumulatedBackgroundQueueTasks.append(taskToGenerateImage)
                // DispatchQueue.global(qos: .userInitiated).async(execute: taskToGenerateImage)
            }
            secondIndex += self.thumbnailPerSeconds
            imageIndex += 1
        }
    }


    let offsetPixelInScrollView: CGFloat = 8
    let redBarOffsetInScrollView: CGFloat = 8

    func configurateRedBar() {
        let interval = CMTime(value: 1, timescale: 30)
        self.episode.player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using: { (progressTime) in
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

            let rightHandSideInView = self.progressView.frame.origin.x > self.timelineScrollView.contentView.bounds.origin.x + self.timelineScrollView.contentView.bounds.size.width
            let leftHandSideInView = self.progressView.frame.origin.x < self.timelineScrollView.contentView.bounds.origin.x

            if !self.timelineOverallView.scrollViewIsScrolling && (rightHandSideInView || leftHandSideInView) {
                #if DEBUG
                // print("The playhead is no longer in view. self.timelineScrollView.bounds:\(self.timelineScrollView.bounds), self.progressView.frame:\(self.progressView.frame), self.timelineScrollView.contentView.bounds: \(self.timelineScrollView.contentView.bounds)")
                #endif
                // Time to scroll to make the new timestamp visible!
                var targetFrame = self.progressView.frame
                if (self.progressBarPanGestureRecongnizer.state == .began || self.progressBarPanGestureRecongnizer.state == .changed) {
                    // We only scrub a little to make the playhead visible if the user is manually dragging the playhead
                    targetFrame.size.width = 2 * (self.progressView.frame.size.width)
                    targetFrame.origin.x -= self.offsetPixelInScrollView
                    self.timelineScrollView.contentView.scrollToVisible(targetFrame)
                } else {
                    if let stopTime = self.timelineOverallView.lastEndManualScrollTime {
                        let differenceBetweenScrollerEndtimeAndCurrentTime = Date().timeIntervalSince1970 - stopTime
                        if differenceBetweenScrollerEndtimeAndCurrentTime < 3 {
                            // Bailing auto-scrolling since user just initiated manual scroll gesture. This gives them an opportunity to manually change the playhead position.
                            return
                        } else {
                            // Once the 3 second grace period expires, we re-enable auto scrolling.
                            self.timelineOverallView.lastEndManualScrollTime = nil
                        }
                    }
                    // We scrub to populate more of the timeline when video playback naturally led the playhead to progress
                    targetFrame.size.width = self.timelineScrollView.frame.width
                    targetFrame.origin.x -= self.offsetPixelInScrollView
                    self.timelineScrollView.scroll(to: targetFrame.origin, animationDuration: 0.15)
                }
            } else {
                 // print("The playhead is in view. self.timelineScrollView.bounds:\(self.timelineScrollView.bounds), self.progressView.frame:\(self.progressView.frame), self.timelineScrollView.contentView.bounds: \(self.timelineScrollView.contentView.bounds)")
            }
        })
    }

    @IBAction func clickedOnNewTimelineIndex(_ sender: NSClickGestureRecognizer) {
        handleNewTimelineLocation(sender: sender)
    }

    var shouldResumePlayingAfterPanEnds = false

    @IBOutlet weak var progressBarPanGestureRecongnizer: NSPanGestureRecognizer!
    @IBOutlet weak var timelineClickGestureRecongnizer: NSClickGestureRecognizer!

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
            progressViewColorLineBox.needsDisplay = true
        } else {
            progressViewColorLineBox.fillColor = NSColor.red
            progressViewColorLineBox.needsDisplay = true
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


    // MARK: - Buttons in the middle HUD

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
        if let _ = self.episode.player?.currentItem?.duration, let currentTime = self.episode.player?.currentTime().seconds {
            let value = currentTime + seconds
            let timeScale = self.episode.player?.currentItem?.asset.duration.timescale ?? 1
            let exactTime = CMTime(seconds: value, preferredTimescale: timeScale)
            self.episode.player!.seek(to: exactTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
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

    // MARK: - Right HUD toolset

    @IBAction func revealInSubtitleEditor(_ sender: Any) {
    }

    @IBAction func joinTwoCaptions(_ sender: Any) {
    }

    @IBAction func deleteSelectedCaptions(_ sender: Any) {
    }

    @IBAction func trimRight(_ sender: Any) {
    }

    @IBAction func trimLeft(_ sender: Any) {
    }

    @IBAction func bladeInMiddle(_ sender: Any) {
    }

}


