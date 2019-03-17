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

//    property frameSizeList : {"1280 x 720", "1920 x 1080", "2048 x 1024", "2048 x 1080", "2048 x 1152", "2048 x 1536", "2048 x 1556", "3048 x 2160", "4096 x 2048", "4096 x 2160", "4096 x 2304", "4096 x 3112", "5120 x 2160", "5120 x 2560", "5120 x 2700"}
//    property ffFormatList : {"FFVideoFormat1080p2398", "FFVideoFormat1080p24", "FFVideoFormat1080p25", "FFVideoFormat1080p2997", "FFVideoFormat1080p30", "FFVideoFormat1080p50", "FFVideoFormat1080p5994", "FFVideoFormat1080p60"}

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
        let frameDurationSeconds = 1 / fps
        let totalDurationSeconds = CMTimeGetSeconds(totalDuration)

        // test
        let templateName = "FFVideoFormat1080p2997" //replace
        let fpsDouble = Double(fps)
        var fpsFCPXValue = ""
        for (doub, str) in fpsToFrameDuration {
            if fpsDouble.checkIsEqual(toDouble: doub, includingNumberOfFractionalDigits: 3) {
                fpsFCPXValue = str
            }
        }
//        let durationString = "\(Int(totalDurationSeconds * 3600))/3600s"
        let durationString = "36000/3600s"
        let headerUUID = NSUUID().uuidString

        let templateA = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <!DOCTYPE fcpxml>

        <fcpxml version="1.3">
        <project name="cap" uid="\(headerUUID)">
        <resources>
        <format id="r1" name="\(templateName)" frameDuration="\(fpsFCPXValue)s" width="1920" height="1080"></format>
        <effect id="fx2" name="TextUp" uid="/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Spherico/Standard Subtitles/TextUp/TextUp/TextUp.moti"></effect>
        </resources>
        <sequence duration="\(durationString)" format="r1" tcStart="0s" tcFormat="DF" audioLayout="stereo" audioRate="48k">
        <spine>
        <gap offset="0s" name="Master" duration="2182180/30000s" start="0s">
        """

        var templateB = ""

        for i in 0..<arrayForCaption.count {
            let line = arrayForCaption[i]
            if let str: String = line.caption {
                if str.count > 0 {

                    let titleOffset = "\(Int(line.startingTime * 30000))/30000s"
                    let titleDuration = "\(Int((line.endingTime - line.startingTime) * 30000))/30000s"
                    let noteUUID = NSUUID().uuidString

                    templateB += """
                    <!--Title No. \(i + 1) +++++++++++++++++++++-->
                    <title name="\(str) - TextUp" lane="1" offset="\(titleOffset)" duration="\(titleDuration)" ref="fx2" role="titles.English_en">
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
                    <note>\(noteUUID)</note>
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

//    static func generateFCPXMLFromArray(player: AVPlayer?, arrayForCaption: [CaptionLine]) -> String {
//        guard let totalDuration = player?.currentItem?.asset.duration, let asset = player?.currentItem?.asset else {
//            return ""
//        }
//        let tracks = asset.tracks(withMediaType: .video)
//        guard let fps = tracks.first?.nominalFrameRate else {
//            return ""
//        }
//        let frameDurationSeconds = 1 / fps
//        let totalDurationSeconds = CMTimeGetSeconds(totalDuration)
//        let templateA = """
//        <?xml version="1.0" encoding="UTF-8"?>
//        <!DOCTYPE fcpxml>
//
//        <fcpxml version="1.8">
//        <resources>
//        <format id="r1" name="FFVideoFormat1080p30" frameDuration="\(frameDurationSeconds)s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
//        <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
//        </resources>
//        <library location="file:///Volumes/Data/Movies/Library.fcpbundle/">
//        <event name="2-16-19" uid="70DAF714-AC1D-4046-BEBC-0D778C57B48E">
//        <project name="Caption 1080p 30fps" uid="2E89EF28-11F8-4AD8-8196-0C86E95EACD5" modDate="2019-02-16 18:17:23 -0500">
//        <sequence duration="\(totalDurationSeconds)s" format="r1" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
//        <spine>
//        <gap name="Gap" offset="0s" duration="\(totalDurationSeconds)s" start="0s">
//        <spine lane="1" offset="0s">
//
//        """
//
//        var templateB = ""
//
//        for i in 0..<arrayForCaption.count {
//            let line = arrayForCaption[i]
//            if let str: String = line.caption {
//                if str.count > 0 {
//                    templateB += """
//                    <title name="\(str)" offset="0s" ref="r2" duration="\(line.durationTimeSecondsString)" start="\(line.startingTimeSecondsString)">
//                    <param name="Position" key="9999/999166631/999166633/1/100/101" value="0.5 -370.516"/>
//                    <param name="Flatten" key="9999/999166631/999166633/2/351" value="1"/>
//                    <param name="Alignment" key="9999/999166631/999166633/2/354/999169573/401" value="1 (Center)"/>
//                    <param name="Wrap Mode" key="9999/999166631/999166633/5/999166635/21/25/5" value="1 (Repeat)"/>
//                    <param name="Opacity" key="9999/999166631/999166633/5/999166635/21/26" value="0.6097"/>
//                    <param name="Distance" key="9999/999166631/999166633/5/999166635/21/27" value="4"/>
//                    <param name="Blur" key="9999/999166631/999166633/5/999166635/21/75" value="1.12 1.12"/>
//                    <text>
//                    <text-style ref="ts\(i + 1)">\(str)</text-style>
//                    </text>
//                    <text-style-def id="ts\(i + 1)">
//                    <text-style font="Helvetica" fontSize="45" fontFace="Regular" fontColor="1 1 1 1" shadowColor="0 0 0 0.6097" shadowOffset="4 315" shadowBlurRadius="2.24" alignment="center"/>
//                    </text-style-def>
//                    </title>
//                    """
//                }
//            }
//        }
//
//
//        let templateC = """
//                    </spine>
//
//                        </gap>
//                    </spine>
//                </sequence>
//            </project>
//        </event>
//        <smart-collection name="Projects" match="all">
//            <match-clip rule="is" type="project"/>
//        </smart-collection>
//        <smart-collection name="All Video" match="any">
//            <match-media rule="is" type="videoOnly"/>
//            <match-media rule="is" type="videoWithAudio"/>
//        </smart-collection>
//        <smart-collection name="Audio Only" match="all">
//            <match-media rule="is" type="audioOnly"/>
//        </smart-collection>
//        <smart-collection name="Stills" match="all">
//            <match-media rule="is" type="stills"/>
//        </smart-collection>
//        <smart-collection name="Favorites" match="all">
//            <match-ratings value="favorites"/>
//        </smart-collection>
//    </library>
//</fcpxml>
//"""
//
//        return "\(templateA)\(templateB)\(templateC)"
//    }

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

