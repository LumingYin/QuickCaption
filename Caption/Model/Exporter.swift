//
//  Exporter.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Foundation
import AVKit

enum FileType {
    case srt
    case txt
    case fcpXML
}

@objc class Exporter : NSObject {
    // MARK: - Persistence
    static func generateSRTFromArray(arrayForCaption: [CaptionLine]) -> String {
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

    static let fpsToTemplateName: [Double : String] =  [23.976: "FFVideoFormat1080p2398",
                                                         24: "FFVideoFormat1080p24",
                                                         25: "FFVideoFormat1080p25",
                                                         29.97: "FFVideoFormat1080p2997",
                                                         30: "FFVideoFormat1080p30",
                                                         50: "FFVideoFormat1080p50",
                                                         59.94: "FFVideoFormat1080p5994",
                                                         60: "FFVideoFormat1080p60"]

    static let fpsToFrameDuration: [Double : String] =  [23.976: "1001/24000",
                                                  24: "100/2400",
                                                  25: "100/2500",
                                                  29.97: "1001/30000",
                                                  30: "100/3000",
                                                  50: "100/5000",
                                                  59.94: "1001/60000",
                                                  60: "100/60000"]


    static func generateFCPXMLFromArray(player: AVPlayer?, arrayForCaption: [CaptionLine]) -> String {
        guard let totalDuration = player?.currentItem?.asset.duration, let asset = player?.currentItem?.asset else {
            return ""
        }
        let tracks = asset.tracks(withMediaType: .video)
        guard let fps = tracks.first?.nominalFrameRate else {
            return ""
        }

        // test
        let fpsDouble = Double(fps)
        var fpsFCPXValue = ""
        var templateName = ""
        for (doub, str) in fpsToFrameDuration {
            if fpsDouble.checkIsEqual(toDouble: doub, includingNumberOfFractionalDigits: 3) {
                fpsFCPXValue = str
            }
        }
        for (doub, str) in fpsToTemplateName {
            if fpsDouble.checkIsEqual(toDouble: doub, includingNumberOfFractionalDigits: 3) {
                templateName = str
            }
        }

        if fpsFCPXValue.count == 0 {
            _ = Helper.dialogOKCancel(question: "Unable to export FCPXML", text: "FCPXML export only supports videos with the following framerates: 23.976, 24, 25, 29.97, 30, 50, 59.94, and 60fps. Export into an SRT, and re-encode the caption into your video clip using ffmpeg instead.")
            return ""
        }

        let durationString = "36000/3600s"
        let headerUUID = NSUUID().uuidString

        let cmTime = fpsFCPXValue.split(separator: "/")
        let frameDuration = CMTimeMake(value: Int64(cmTime[0])!, timescale: Int32(cmTime[1])!)
        let overallLength = conform(time: totalDuration.seconds, toFrameDuration: frameDuration)

        var tcFormat = "NDF"
        if fpsDouble.checkIsEqual(toDouble: 23.976, includingNumberOfFractionalDigits: 3) {
            tcFormat = "DF"
        }
        let templateA = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <!DOCTYPE fcpxml>

        <fcpxml version="1.3">
            <project name="cap" uid="\(headerUUID)">
                <resources>
                    <format id="r1" name="\(templateName)" frameDuration="\(fpsFCPXValue)s" width="1920" height="1080"></format>
                    <effect id="fx2" name="TextUp" uid="/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Spherico/Standard Subtitles/TextUp/TextUp/TextUp.moti"></effect>
                </resources>
                <sequence duration="\(durationString)" format="r1" tcStart="0s" tcFormat="\(tcFormat)" audioLayout="stereo" audioRate="48k">
                    <spine>
                        <gap offset="0s" name="Master" duration="\(overallLength.value)/\(overallLength.timescale)s" start="0s">

        """

        var templateB = ""

        for i in 0..<arrayForCaption.count {
            let line = arrayForCaption[i]
            if let str: String = line.caption {
                if str.count > 0 {
                    let conformedTitleOffset = conform(time: Double(line.startingTime), toFrameDuration: frameDuration)
                    let conformedTitleDuration = conform(time: Double(line.endingTime - line.startingTime), toFrameDuration: frameDuration)

                    let noteUUID = NSUUID().uuidString

                    templateB += """
                                <!--Title No. \(i + 1) +++++++++++++++++++++-->
                                <title name="\(str) - TextUp" lane="1" offset="\(conformedTitleOffset.value)/\(conformedTitleOffset.timescale)s" duration="\(conformedTitleDuration.value)/\(conformedTitleDuration.timescale)s" ref="fx2" role="titles.English_en">
                                        <param name="Background Color" key="9999/24742/24860/24776/3/24789/2" value="0 0 0 1"></param>
                                        <param name="Background Opacity" key="9999/24742/24860/1/200/202" value="0"></param>
                                        <param name="Padding" key="9999/24999/100/25000/2/100" value="0.066666666667"></param>
                                        <param name="Title Safe" key="9999/25169/100/25170/2/100" value="0 (Standard 80% 80%)"></param>
                                        <text>
                                            <text-style ref="xs\(i + 1)-1">\(str)</text-style>
                                        </text>
                                        <text-style-def id="xs\(i + 1)-1">
                                            <text-style font="Arial" fontSize="53" fontColor="1 1 1 1" alignment="center"></text-style>
                                        </text-style-def>
                                        <note>en - \(noteUUID)</note>
                                </title>

                    """
                }
            }
        }


        let templateC = """
                </gap>
            </spine>
        </sequence>
    </project>
</fcpxml>
"""

        return "\(templateA)\(templateB)\(templateC)"
    }

    static func conform(time: Double, toFrameDuration frameDuration: CMTime) -> CMTime {
        let numberOfFrames = time / frameDuration.seconds
        let numberOfFramesRounded = floor(Double(numberOfFrames))
        let conformedTime = CMTimeMake(value: Int64(numberOfFramesRounded * Double(frameDuration.value)), timescale: frameDuration.timescale)

        return conformedTime
    }


    static func generateTXTFromArray(arrayForCaption: [CaptionLine]) -> String {
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


}

