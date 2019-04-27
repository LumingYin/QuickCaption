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

    static func removeFilesUnderURL(urlPath: String) {
        let cacheURL = (urlPath as NSString).expandingTildeInPath as String

        guard let url = URL(string: cacheURL) else {return}
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: cacheURL)
        } catch {
            print(error)
        }
    }

    static func installFCPXCaptionFiles() -> Bool {
        let fileMgr = FileManager.default
        // let userDocumentURL = fileMgr.urls(for: .documentDirectory, in: .userDomainMask).first!
        let urlForCreation = URL(fileURLWithPath: "/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Captions", isDirectory: true)
        let urlForCopy = URL(fileURLWithPath: "/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Captions/Caption", isDirectory: true)
        if let bundleURL = Bundle.main.url(forResource: "Caption", withExtension: "") {
            do {
                try fileMgr.createDirectory(at: urlForCreation, withIntermediateDirectories: true, attributes: nil)
                try fileMgr.copyItem(at: bundleURL, to: urlForCopy)
                return true
            } catch let error as NSError { // Handle the error
                print("copy failed! Error:\(error.localizedDescription)")
                return false
            }
        } else {
            print("Folder doesn't not exist in bundle folder")
            return false
        }
    }

    static func secondFloatToString(float: Float64) -> String {
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


    static func conform(time: Double, toFrameDuration frameDuration: CMTime) -> CMTime {
        let numberOfFrames = time / frameDuration.seconds
        let numberOfFramesRounded = floor(Double(numberOfFrames))
        let conformedTime = CMTimeMake(value: Int64(numberOfFramesRounded * Double(frameDuration.value)), timescale: frameDuration.timescale)

        return conformedTime
    }

    static let movieTypes = ["mp4", "mpeg4", "m4v", "ts", "mpg", "mpeg", "mp3", "mpeg3", "m4a", "mov"]

    static func displayOpenFileDialog(callback: @escaping ((_ selectedFile: Bool, _ fileURL: URL?, _ filePath: String?)-> ())) {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a video file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes = movieTypes

        dialog.beginSheetModal(for: NSApp.mainWindow!) { (result) in
            if result != .OK {
                callback(false, nil, nil)
            } else {
                if let result = dialog.url, let path = dialog.url?.path {
                    AppSandboxFileAccess().persistPermissionPath(path)
                    callback(true, result, path)
                }
            }
        }
    }

    static func displaySaveFileDialog(_ fileName: String, callback: @escaping ((_ selectedFile: Bool, _ fileURL: URL?, _ filePath: String?)-> ())) {
        let dialog = NSSavePanel()
        dialog.title = "Save created caption file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canCreateDirectories = true
        dialog.nameFieldStringValue = fileName

//        dialog.allowedFileTypes = movieTypes

        dialog.beginSheetModal(for: NSApp.mainWindow!) { (result) in
            if result != .OK {
                callback(false, nil, nil)
            } else {
                if let result = dialog.url, let path = dialog.url?.path {
                    callback(true, result, path)
                }
            }
        }
    }


    static func displayInformationalSheet(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "OK")
        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
        } else {
            alert.runModal()
        }
    }

    static func displayInteractiveSheet(title: String, text: String, dropdownOptions: [String], preferredIndex: Int, firstButtonText: String, secondButtonText: String, callback: @escaping ((_ fisrtButtonReturn: Bool, _ selectedItemIndex: Int)-> ())) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.alertStyle = NSAlert.Style.warning

        var dropdown: NSPopUpButton?

        if (dropdownOptions.count > 0) {
            dropdown = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 300, height: 25))
            dropdown?.addItems(withTitles: dropdownOptions)
            if preferredIndex >= 0 && preferredIndex < dropdownOptions.count {
                dropdown?.selectItem(at: preferredIndex)
            } else {
                dropdown?.selectItem(at: 0)
            }
            alert.accessoryView = dropdown
        }

        alert.addButton(withTitle: firstButtonText)
        alert.addButton(withTitle: secondButtonText)
        if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window) { (response) in
                callback(response == NSApplication.ModalResponse.alertFirstButtonReturn, dropdown?.indexOfSelectedItem ?? 0)
            }
        } else {
            let first = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
            callback(first, dropdown?.indexOfSelectedItem ?? 0)
        }

    }

    static func displayInteractiveSheet(title: String, text: String, dropdownOptions: [String], firstButtonText: String, secondButtonText: String, callback: @escaping ((_ fisrtButtonReturn: Bool, _ selectedItemIndex: Int)-> ())) {
        displayInteractiveSheet(title: title, text: text, dropdownOptions: dropdownOptions, preferredIndex: 0, firstButtonText: firstButtonText, secondButtonText: secondButtonText, callback: callback)
    }

    static func displayInteractiveSheet(title: String, text: String, firstButtonText: String, secondButtonText: String, callback: @escaping ((_ fisrtButtonReturn: Bool)-> ())) {
        Helper.displayInteractiveSheet(title: title, text: text, dropdownOptions: [], firstButtonText: firstButtonText, secondButtonText: secondButtonText) { (firstButton, _) in
            callback(firstButton)
        }
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


extension String {
    var withoutFileExtension: String {
        get {
            var components = self.components(separatedBy: ".")
            guard components.count > 1 else { return self }
            components.removeLast()
            return components.joined(separator: ".")
        }
    }
}
