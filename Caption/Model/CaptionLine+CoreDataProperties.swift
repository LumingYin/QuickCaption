//
//  CaptionLine+CoreDataProperties.swift
//  Quick Caption
//
//  Created by Blue on 3/12/19.
//  Copyright © 2019 Bright. All rights reserved.
//
//

import Foundation
import CoreData


extension CaptionLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CaptionLine> {
        return NSFetchRequest<CaptionLine>(entityName: "CaptionLine")
    }
    
    @NSManaged public var guidIdentifier: String?
    @NSManaged public var caption: String?
    @NSManaged public var startingTime: Float
    @NSManaged public var endingTime: Float
    @NSManaged public var episodeProject: EpisodeProject?

}
