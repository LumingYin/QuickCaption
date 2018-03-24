//
//  CaptionLine.swift
//  Caption
//
//  Created by Numeric on 3/23/18.
//  Copyright © 2018 Bright. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation

class CaptionLine: CustomStringConvertible {
    var caption: String?
    var startingTime: CMTime?
    var endingTime: CMTime?
    
    init(caption: String?, startingTime: CMTime?, endingTime: CMTime?) {
        self.caption = caption
        self.startingTime = startingTime
        self.endingTime = endingTime
    }
    
    var startingTimeString: String {
        guard let start = startingTime else {
            return ""
        }
        let st = CMTimeGetSeconds(start)
        return secondFloatToString(float: st)
    }
    
    var endingTimeString: String {
        guard let end = endingTime else {
            return ""
        }
        let en = CMTimeGetSeconds(end)
        return secondFloatToString(float: en)
    }
    
    var description: String {
        guard let cap = caption, let start = startingTime, let end = endingTime else {
            return ""
        }
        
        let st = CMTimeGetSeconds(start)
        let en = CMTimeGetSeconds(end)
        
        let stringStart = secondFloatToString(float: st)
        let stringEnd = secondFloatToString(float: en)
        
        return "\(stringStart) --> \(stringEnd)\n\(cap)"
    }
    
    func secondFloatToString(float: Float64) -> String {
        var second = float
        
        var hours: Int = 0
        var minutes: Int = 0
        var seconds: Int = 0
        var milliseconds: Int = 0
        
        hours = Int(second / Float64(3600))
        second = second - Float64(hours * 3600)
        
        minutes = Int(second / Float64(60))
        second = second - Float64(minutes * 60)
        
        seconds = Int(second)
        second = second - Float64(seconds)
        
        milliseconds = Int(second * 1000)
        
        let string = NSString(format:"%.2d:%.2d:%.2d,%.3d", hours, minutes, seconds, milliseconds)
        return string as String
    }
    
    
}
