//
//  Saver.swift
//  Quick Caption
//
//  Created by Blue on 3/17/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class Saver {

    static func saveEpisodeToDisk(_ episode: EpisodeProject?, type: FileType) {
        guard let episode = episode else {
            return
        }

        guard var copiedArray = (episode.arrayForCaption?.array as? [CaptionLine]) else { return }

        copiedArray.sort(by: { (this, that) -> Bool in
            return this.startingTime < that.startingTime
        })

        var text = "Export is unsuccessful."

        if type == .srt {
            text = Exporter.generateSRTFromArray(arrayForCaption: copiedArray)
            writeFileToDisk(type: type, text: text, episode: episode)
        } else if type == .txt {
            text = Exporter.generateTXTFromArray(arrayForCaption: copiedArray)
            writeFileToDisk(type: type, text: text, episode: episode)
        } else if type == .fcpXML {
            Exporter.generateFCPXMLFromArray(episode: episode, arrayForCaption: copiedArray, callback: { (success, resultingText) in
                text = resultingText
                writeFileToDisk(type: type, text: resultingText, episode: episode)
            })
        }


    }

    static func writeFileToDisk(type: FileType, text: String, episode: EpisodeProject) {
        if text.count == 0 {
            return
        }

        guard let origonalVideoName = episode.videoURL?.lastPathComponent else {
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

        guard let directoryPath = episode.videoURL?.deletingLastPathComponent() else {
            return
        }
        
        let newPath = directoryPath.appendingPathComponent(newSubtitleName)

        Helper.displaySaveFileDialog(newSubtitleName, directoryPath: directoryPath, callback: { (success, url, string) in
            if success {
                do {
                    try text.write(to: url!, atomically: true, encoding: String.Encoding.utf8)
                    Helper.displayInteractiveSheet(title: "Saved successfully!", text: "Subtitle saved as \(newSubtitleName) under \(newPath.deletingLastPathComponent()).", firstButtonText: "Show in Finder", secondButtonText: "Dismiss") { (firstButtonReturn) in
                        if firstButtonReturn == true {
                            NSWorkspace.shared.activateFileViewerSelecting([newPath])
                        }
                    }
                } catch {
                    Helper.displayInformationalSheet(title: "Save failed!", text: "Save has failed. \(error)")
                }
            }
        })
    }

}
