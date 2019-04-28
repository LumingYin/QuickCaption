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

        guard URL(string: cacheURL) != nil else {return}
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: cacheURL)
        } catch {
            print(error)
        }
    }

    static func fcpxTemplateAlreadyInstalled() -> Bool {
        let path = "/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Captions/Caption/Caption.moti"
        let pathB = "/Library/Application Support/Final Cut Pro/Templates.localized/Titles/Captions/Caption/Caption.moti"
        let pathC = "/Library/Application Support/Final Cut Pro/Templates/Titles/Captions/Caption/Caption.moti"
        let pathD = "/Library/Application Support/Final Cut Pro/Templates/Titles.localized/Captions/Caption/Caption.moti"

        if FileManager.default.fileExists(atPath: path) || FileManager.default.fileExists(atPath: pathB) || FileManager.default.fileExists(atPath: pathC) || FileManager.default.fileExists(atPath: pathD) {
            return true
        }
        return false
    }

//    static func installFCPXCaptionFiles(callback: (()->Void)?) {
//        let firstLevelPath = "/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Captions"
//        let secondLevelPath = "/Library/Application Support/Final Cut Pro/Templates.localized/Titles.localized/Captions/Caption"
//        let fileMgr = FileManager.default
//        let urlForCreation = URL(fileURLWithPath: firstLevelPath, isDirectory: true)
//        let urlForCopy = URL(fileURLWithPath: secondLevelPath, isDirectory: true)
//        if let bundleURL = Bundle.main.url(forResource: "Caption", withExtension: "") {
//            AppSandboxFileAccess()?.accessFileURL(urlForCopy, persistPermission: true, with: {
//                do {
//                    try fileMgr.createDirectory(at: urlForCreation, withIntermediateDirectories: true, attributes: nil)
//                    try fileMgr.copyItem(at: bundleURL, to: urlForCopy)
//                    Helper.displayInteractiveSheet(title: "Template successfully installed", text: "You have successfully installed Final Cut Pro X caption template on this Mac. Exported captions should now work correctly in Final Cut Pro X.\n\nIf Final Cut Pro X is unable to process your imported captions, please contact support with \"Contact → Contact Support\".\n\nTo import captions onto another Mac, install Quick Caption on your other Mac, and click on \"Help → Install Final Cut Pro X Caption Template\".", firstButtonText: "OK", secondButtonText: "", callback: { (clicked) in
//                        callback?()
//                    })
//                } catch let error as NSError { // Handle the error
//                    print("Returned file access code: \(error.code)")
//                    if error.code == 513 {
//                        let command = #"sudo mkdir -p /Library/Application\ Support/Final\ Cut\ Pro/Templates.localized/Titles.localized;sudo chmod -R 777 /Library/Application\ Support/Final\ Cut\ Pro/Templates.localized/Titles.localized"#
//                        let text = """
//Unable to install template. \n\nYou need to install Final Cut Pro X and run it at least once before installing the caption template.\n\nIf you are still unable to install the template after installing Final Cut Pro X, manually paste the following command into the Terminal app and press return, then try to install the caption package again. You will be prompted to enter your login password, and it is normal that your password will not be visible as you type. Your password will not be sent to anywhere.\n\n\(command)
//"""
//                        Helper.displayInteractiveSheet(title: "You need to install Final Cut Pro X first", text: text, firstButtonText: "Copy Command and Open Terminal", secondButtonText: "Cancel", callback: { (allowed) in
//                            if (allowed) {
//                                NSWorkspace.shared.launchApplication("Terminal")
//                                let pb = NSPasteboard.general
//                                pb.declareTypes([.string], owner: nil)
//                                pb.setString(command, forType: .string)
//                            }
//                        })
//                    } else if error.code == 516 {
//                        Helper.displayInteractiveSheet(title: "Template already successfully installed", text: "You have already installed Final Cut Pro X caption template on this Mac. Exported captions should now work correctly in Final Cut Pro X.\n\nIf Final Cut Pro X is unable to process your imported captions, please contact support with \"Contact → Contact Support\".\n\nTo import captions onto another Mac, install Quick Caption on your other Mac, and click on \"Help → Install Final Cut Pro X Caption Template\".", firstButtonText: "OK", secondButtonText: "", callback: { (clicked) in
//                            callback?()
//                        })
//                    } else {
//                        Helper.displayInformationalSheet(title: "Failed to install template", text: "Unable to install template. \n\n\(error.localizedDescription).\n\nPlease contact support with Contact → Contact Support.\n\n")
//                        print("Copy failed! Error: \(error.localizedDescription)")
//                    }
//                }
//            })
//        } else {
//            print("Folder doesn't not exist in bundle folder")
//        }
//    }

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

        dialog.beginSheetModal(for: Helper.appWindow()) { (result) in
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

    static func appWindow() -> NSWindow {
        if let mainWindow = NSApp.mainWindow {
            return mainWindow
        }
        for window in NSApp.windows {
            if let typed = window as? QuickCaptionWindow {
                return typed
            }
        }
        fatalError("Unable to find a window.")
    }

    static func displaySaveFileDialog(_ fileName: String, directoryPath: URL, callback: @escaping ((_ selectedFile: Bool, _ fileURL: URL?, _ filePath: String?)-> ())) {
        let dialog = NSSavePanel()
        dialog.directoryURL = directoryPath
        dialog.title = "Save created caption file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canCreateDirectories = true
        dialog.nameFieldStringValue = fileName
        dialog.isExtensionHidden = true
        dialog.canSelectHiddenExtension = false
        dialog.allowedFileTypes = [fileName.fileExtension]

//        dialog.allowedFileTypes = movieTypes

        dialog.beginSheetModal(for: Helper.appWindow()) { (result) in
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
        if secondButtonText.count > 0 {
            alert.addButton(withTitle: secondButtonText)
        }
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
            if let context = (NSApp.delegate as? AppDelegate)?.managedObjectContext {
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

    var fileExtension: String {
        get {
            let components = self.components(separatedBy: ".")
            guard components.count > 1 else { return "" }
            return components.last ?? ""
        }
    }
}
