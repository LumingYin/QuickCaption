//
//  Helper.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa
import AVKit

class Helper: NSObject {

    static func conform(time: Double, toFrameDuration frameDuration: CMTime) -> CMTime {
        let numberOfFrames = time / frameDuration.seconds
        let numberOfFramesRounded = floor(Double(numberOfFrames))
        let conformedTime = CMTimeMake(value: Int64(numberOfFramesRounded * Double(frameDuration.value)), timescale: frameDuration.timescale)

        return conformedTime
    }


    static func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }


    static func dialogTwoButton(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }

    static var context: NSManagedObjectContext? {
        get {
            if let context = (NSApp.delegate as? AppDelegate)?.persistentContainer.viewContext {
                return context
            } else {
                return nil
            }
        }
    }

}

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .png, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}

extension Double {
    /// Compares the receiver (Double) with annother Double considering a defined
    /// number of fractional digits.
    func checkIsEqual(toDouble pDouble : Double, includingNumberOfFractionalDigits : Int) -> Bool {

        let denominator         : Double = pow(10.0, Double(includingNumberOfFractionalDigits))
        let maximumDifference   : Double = 1.0 / denominator
        let realDifference      : Double = fabs(self - pDouble)

        if realDifference >= maximumDifference {
            return false
        } else {
            return true
        }
    }
}

