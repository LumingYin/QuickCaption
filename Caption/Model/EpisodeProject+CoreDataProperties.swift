//
//  EpisodeProject+CoreDataProperties.swift
//  Quick Caption
//
//  Created by Blue on 3/12/19.
//  Copyright © 2019 Bright. All rights reserved.
//
//

import Foundation
import CoreData


extension EpisodeProject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EpisodeProject> {
        return NSFetchRequest<EpisodeProject>(entityName: "EpisodeProject")
    }

    @NSManaged public var guidIdentifier: String?
    @NSManaged public var videoDescription: String?
    @NSManaged public var videoURL: String?
    @NSManaged public var thumbnailURL: String?
    @NSManaged public var creationDate: NSDate?
    @NSManaged public var modifiedDate: NSDate?
    @NSManaged public var styleFontFamily: String?
    @NSManaged public var styleFontWeight: String?
    @NSManaged public var styleFontColor: String?
    @NSManaged public var styleFontSize: String?
    @NSManaged public var framerate: Float
    @NSManaged public var videoDuration: Float
    @NSManaged public var styleFontShadow: Int16
    @NSManaged public var arrayForCaption: NSOrderedSet?

}

// MARK: Generated accessors for arrayForCaption
extension EpisodeProject {

    @objc(insertObject:inArrayForCaptionAtIndex:)
    @NSManaged public func insertIntoArrayForCaption(_ value: CaptionLine, at idx: Int)

    @objc(removeObjectFromArrayForCaptionAtIndex:)
    @NSManaged public func removeFromArrayForCaption(at idx: Int)

    @objc(insertArrayForCaption:atIndexes:)
    @NSManaged public func insertIntoArrayForCaption(_ values: [CaptionLine], at indexes: NSIndexSet)

    @objc(removeArrayForCaptionAtIndexes:)
    @NSManaged public func removeFromArrayForCaption(at indexes: NSIndexSet)

    @objc(replaceObjectInArrayForCaptionAtIndex:withObject:)
    @NSManaged public func replaceArrayForCaption(at idx: Int, with value: CaptionLine)

    @objc(replaceArrayForCaptionAtIndexes:withArrayForCaption:)
    @NSManaged public func replaceArrayForCaption(at indexes: NSIndexSet, with values: [CaptionLine])

    @objc(addArrayForCaptionObject:)
    @NSManaged public func addToArrayForCaption(_ value: CaptionLine)

    @objc(removeArrayForCaptionObject:)
    @NSManaged public func removeFromArrayForCaption(_ value: CaptionLine)

    @objc(addArrayForCaption:)
    @NSManaged public func addToArrayForCaption(_ values: NSOrderedSet)

    @objc(removeArrayForCaption:)
    @NSManaged public func removeFromArrayForCaption(_ values: NSOrderedSet)

}
