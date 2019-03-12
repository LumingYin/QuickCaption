//
//  CaptionLine+CoreDataClass.swift
//  Quick Caption
//
//  Created by Blue on 3/12/19.
//  Copyright © 2019 Bright. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CaptionLine)
public class CaptionLine: NSManagedObject {

    var startingTimeSecondsString: String {
        return "\(startingTime)s"
    }

    var endingTimeSecondsString: String {
        let en = endingTime
        return "\(en)s"
    }

    var durationTimeSecondsString: String {
        let st = startingTime
        let en = endingTime
        return "\(en - st)s"
    }


    var startingTimeString: String {
        return secondFloatToString(float: Float64(startingTime))
    }

    var endingTimeString: String {
        return secondFloatToString(float: Float64(endingTime))
    }

    //    var fcpXMLSpineTitleDescription: String {
    //        guard let cap = caption, let start = startingTime, let end = endingTime else {
    //            return ""
    //        }
    //        return ""
    //    }

    override public var description: String {
        guard let cap = caption else {
            return ""
        }

        let stringStart = secondFloatToString(float: Float64(startingTime))
        let stringEnd = secondFloatToString(float: Float64(endingTime))

        return "\(stringStart) --> \(stringEnd)\n\(cap)"
    }

    func secondFloatToString(float: Float64) -> String {
        if float.isNaN {
            return ""
        }
        
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
