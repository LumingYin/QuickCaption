//
//  SubtitlesViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/10/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa
import AVKit

@objc class SubtitlesViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate, CaptionDetailTableCellViewDelegate {

    @IBOutlet weak var transcribeTextField: NSTextField!
    @IBOutlet weak var resultTableView: NSTableView!

    weak var episode: EpisodeProject! {
        didSet {
            episode.arrayForCaption?.enumerateObjects({ (obj, index, stop) in
                if let line = obj as? CaptionLine {
                    self.addObserverForCaptionLine(line: line)
                }
            })
        }
    }

    func addObserverForCaptionLine(line: CaptionLine) {
        line.addObserver(self, forKeyPath: "caption", options: [.new], context: nil)
        line.addObserver(self, forKeyPath: "endingTime", options: [.new], context: nil)
        line.addObserver(self, forKeyPath: "startingTime", options: [.new], context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        var matchedIndex: Int?
        if let captionLine = object as? CaptionLine {
            episode.arrayForCaption?.enumerateObjects({ (obj, index, stop) in
                if let captionMatch = obj as? CaptionLine {
                    if captionLine == captionMatch {
                        matchedIndex = index
                        stop.pointee = true
                    }
                }
            })
        }
        if let index = matchedIndex {
            self.resultTableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func configurateSubtitleVC() {
        self.resultTableView.delegate = self
        self.resultTableView.dataSource = self
        self.transcribeTextField.delegate = self
        self.resultTableView.reloadData()
        self.transcribeTextField.stringValue = ""
    }

    // MARK: - TextField Controls
    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        if (episode.player == nil) {
            return true
        }

        if (control == transcribeTextField) {
            episode.player?.pause()
            if let last = episode.arrayForCaption?.lastObject as? CaptionLine, let time = episode.player?.currentTime() {
                if (Float(CMTimeGetSeconds(time)) < last.startingTime) {
                    _ = Helper.dialogOKCancel(question: "Unable to add caption", text: "You can't add a caption with an ending time earlier than the starting time.")
                } else {
                    last.endingTime = Float(CMTimeGetSeconds(time))
                }
            }
        }
        return true
    }

    @IBAction func captionTextFieldDidChange(_ sender: NSTextField) {
        if (episode == nil || episode.player == nil) {
            sender.stringValue = ""
            _ = Helper.dialogOKCancel(question: "A video is required before adding captions.", text: "Please open a video first, then add captions to the video.")
            return
        }
        if (sender == transcribeTextField) {
            episode.player?.play()
            if sender.stringValue == "" {
                if let last = episode.arrayForCaption?.lastObject as? CaptionLine, let time = episode.player?.currentTime() {
                    last.startingTime = Float(CMTimeGetSeconds(time))
                }
            } else {
                if let last = episode.arrayForCaption?.lastObject as? CaptionLine {
                    last.caption = sender.stringValue
                }
                sender.stringValue = ""
                var new: CaptionLine!
                if let lastEndingTime = (episode.arrayForCaption?.lastObject as? CaptionLine)?.endingTime {
                    new = CaptionLine(context: Helper.context!)
                    new.guidIdentifier = NSUUID().uuidString
                    new.caption = ""
                    new.startingTime = lastEndingTime
                    new.endingTime = lastEndingTime // this is likely wrong, although better than 0 for integrity
                    self.addObserverForCaptionLine(line: new)
                } else {
                    new = CaptionLine(context: Helper.context!)
                    new.guidIdentifier = NSUUID().uuidString
                    new.caption = ""
                    new.startingTime = Float(CMTimeGetSeconds((episode.player?.currentTime())!))
                    new.endingTime = new.startingTime // this is likely wrong, although better than 0 for integrity
                    self.addObserverForCaptionLine(line: new)
                }
                episode.addToArrayForCaption(new)
            }
            self.resultTableView.reloadData()
            if resultTableView.numberOfRows > 0 {
                self.resultTableView.scrollRowToVisible(resultTableView.numberOfRows - 1)
            }
        }
    }

    // MARK: - Table View Delegate/Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return episode.arrayForCaption?.count ?? 0
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CaptionCell"), owner: self) as? CaptionDetailTableCellView {
            let correspondingCaption = episode.arrayForCaption?.object(at: row) as? CaptionLine
            cell.startTimeField?.stringValue = "\(correspondingCaption!.startingTimeString)"
            cell.endTimeField?.stringValue = "\(correspondingCaption!.endingTimeString)"
            if let cap = correspondingCaption!.caption {
                cell.captionContentTextField?.stringValue = cap
            } else {
                cell.captionContentTextField?.stringValue = ""
            }
            cell.captionContentTextField?.isEditable = true
            cell.delegate = self
            return cell
        }
        return nil
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 71
    }

    @IBAction func captionChanged(_ sender: NSTextField) {
        let row = resultTableView.row(for: sender)
        if let ep = episode.arrayForCaption?.object(at: row) as? CaptionLine {
            ep.caption = sender.stringValue
        }
    }

    func textFieldEdited(_ sender: Any) {
        if let cell = sender as? CaptionDetailTableCellView {
            let rowIndex = resultTableView.row(for: cell)
            if let cl = episode.arrayForCaption?.object(at: rowIndex) as? CaptionLine {
                cl.caption = cell.captionContentTextField.stringValue
            }
        }
    }

}
