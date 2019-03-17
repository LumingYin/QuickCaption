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
        return Helper.secondFloatToString(float: float)
    }


}
