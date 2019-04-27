//
//  FileCoordinator.swift
//  Quick Caption
//
//  Created by Numeric on 3/24/18.
//  Copyright © 2018 Bright. All rights reserved.
//
import Cocoa

class FileData: NSObject {
    var filePath: String
    var ext = "srt"
    
    init(path: String) {
        filePath = path
    }
}

// MARK: - NSFilePresenter
extension FileData: NSFilePresenter {
    var presentedItemURL: URL? {
        let range = filePath.range(of: ".", options:NSString.CompareOptions.backwards)
        let baseName = String(filePath[..<range!.lowerBound])
        
        let altFilePath = baseName + "." + ext
        return URL(fileURLWithPath: altFilePath)
    }
    
    var primaryPresentedItemURL: URL? {
        return URL(fileURLWithPath: filePath)
    }
    
    var presentedItemOperationQueue: OperationQueue {
        return OperationQueue.main
    }
}

