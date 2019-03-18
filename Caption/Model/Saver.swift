//
//  Saver.swift
//  Quick Caption
//
//  Created by Blue on 3/17/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Foundation

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
        } else if type == .txt {
            text = Exporter.generateTXTFromArray(arrayForCaption: copiedArray)
        } else if type == .fcpXML {
            text = Exporter.generateFCPXMLFromArray(episode: episode, arrayForCaption: copiedArray)
        }

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

        guard let newPath = episode.videoURL?.deletingLastPathComponent().appendingPathComponent(newSubtitleName) else {
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

}
