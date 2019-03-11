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

class Exporter {
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
        let templateA = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE fcpxml>

        <fcpxml version="1.8">
        <resources>
        <format id="r1" name="FFVideoFormat1080p30" frameDuration="\(frameDurationSeconds)s" width="1920" height="1080" colorSpace="1-1-1 (Rec. 709)"/>
        <effect id="r2" name="Basic Title" uid=".../Titles.localized/Bumper:Opener.localized/Basic Title.localized/Basic Title.moti"/>
        </resources>
        <library location="file:///Volumes/Data/Movies/Library.fcpbundle/">
        <event name="2-16-19" uid="70DAF714-AC1D-4046-BEBC-0D778C57B48E">
        <project name="Caption 1080p 30fps" uid="2E89EF28-11F8-4AD8-8196-0C86E95EACD5" modDate="2019-02-16 18:17:23 -0500">
        <sequence duration="\(totalDurationSeconds)s" format="r1" tcStart="0s" tcFormat="NDF" audioLayout="stereo" audioRate="48k">
        <spine>
        <gap name="Gap" offset="0s" duration="\(totalDurationSeconds)s" start="0s">
        <spine lane="1" offset="0s">

        """

        var templateB = ""

        for i in 0..<arrayForCaption.count {
            let line = arrayForCaption[i]
            if let str: String = line.caption {
                if str.count > 0 {
                    templateB += """
                    <title name="\(str)" offset="0s" ref="r2" duration="\(line.durationTimeSecondsString)" start="\(line.startingTimeSecondsString)">
                    <param name="Position" key="9999/999166631/999166633/1/100/101" value="0.5 -370.516"/>
                    <param name="Flatten" key="9999/999166631/999166633/2/351" value="1"/>
                    <param name="Alignment" key="9999/999166631/999166633/2/354/999169573/401" value="1 (Center)"/>
                    <param name="Wrap Mode" key="9999/999166631/999166633/5/999166635/21/25/5" value="1 (Repeat)"/>
                    <param name="Opacity" key="9999/999166631/999166633/5/999166635/21/26" value="0.6097"/>
                    <param name="Distance" key="9999/999166631/999166633/5/999166635/21/27" value="4"/>
                    <param name="Blur" key="9999/999166631/999166633/5/999166635/21/75" value="1.12 1.12"/>
                    <text>
                    <text-style ref="ts\(i + 1)">\(str)</text-style>
                    </text>
                    <text-style-def id="ts\(i + 1)">
                    <text-style font="Helvetica" fontSize="45" fontFace="Regular" fontColor="1 1 1 1" shadowColor="0 0 0 0.6097" shadowOffset="4 315" shadowBlurRadius="2.24" alignment="center"/>
                    </text-style-def>
                    </title>
                    """
                }
            }
        }


        let templateC = """
                    </spine>

                        </gap>
                    </spine>
                </sequence>
            </project>
        </event>
        <smart-collection name="Projects" match="all">
            <match-clip rule="is" type="project"/>
        </smart-collection>
        <smart-collection name="All Video" match="any">
            <match-media rule="is" type="videoOnly"/>
            <match-media rule="is" type="videoWithAudio"/>
        </smart-collection>
        <smart-collection name="Audio Only" match="all">
            <match-media rule="is" type="audioOnly"/>
        </smart-collection>
        <smart-collection name="Stills" match="all">
            <match-media rule="is" type="stills"/>
        </smart-collection>
        <smart-collection name="Favorites" match="all">
            <match-ratings value="favorites"/>
        </smart-collection>
    </library>
</fcpxml>
"""

        return "\(templateA)\(templateB)\(templateC)"
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

