//
//  AppDelegate.swift
//  Caption
//
//  Created by Bright on 7/29/17.
//  Copyright © 2017 Bright. All rights reserved.
//

import Cocoa
//import LetsMove
//import Sparkle
//import AppCenter
//import AppCenterAnalytics
//import AppCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var darkMenuItem: NSMenuItem!
    @IBOutlet weak var lightMenuItem: NSMenuItem!
    @IBOutlet weak var followSystemMenuItem: NSMenuItem!
    @IBOutlet weak var openOrRelinkMenuItem: NSMenuItem!

    static func mainStoryboard() -> NSStoryboard? {
        if #available(OSX 10.13, *) {
            return NSStoryboard.main
        } else {
            return NSStoryboard(name: "Main", bundle: nil)
        }
    }

    static func openOrRelinkMenuItem() -> NSMenuItem? {
        if let delegate = NSApp.delegate as? AppDelegate {
            return delegate.openOrRelinkMenuItem
        }
        return nil
    }

    static func setCurrentEpisodeTitle(_ title: String?) {
        if let window = NSApp.mainWindow?.windowController as? CaptionWindowController {
            window.currentTitle.stringValue = title ?? "Quick Caption"
        }
    }

    static func mainWindow() -> CaptionWindowController? {
        return NSApp.mainWindow?.windowController as? CaptionWindowController
    }

    static func rebuildMovieAndSubVC() {
        if let splitVC = NSApp.mainWindow?.contentViewController as? MainSplitViewController,
            let movieVC = AppDelegate.mainStoryboard()?.instantiateController(withIdentifier: "MovieViewController")  as? MovieViewController {
            splitVC.splitViewItems[1].viewController = movieVC
        }
        if let tabVC = AppDelegate.sideTabVC(), let subVC = AppDelegate.mainStoryboard()?.instantiateController(withIdentifier: "SubtitlesViewController") as? SubtitlesViewController {
            tabVC.tabViewItems[0].viewController = subVC
        }
    }

    static func sourceListVC() -> SidebarViewController? {
        if let splitVC = NSApp.mainWindow?.contentViewController as? MainSplitViewController, let sourceListVC = splitVC.splitViewItems[0].viewController as? SidebarViewController {
            return sourceListVC
        }
        return nil
    }

    static func movieVC() -> MovieViewController? {
        if let splitVC = NSApp.mainWindow?.contentViewController as? MainSplitViewController, let movieVC = splitVC.splitViewItems[1].viewController as? MovieViewController {
            return movieVC
        }
        return nil
    }

    static func sideTabVC() -> SideTabViewController? {
        if let splitVC = NSApp.mainWindow?.contentViewController as? MainSplitViewController, let tabVC = splitVC.splitViewItems[2].viewController as? SideTabViewController {
            return tabVC
        }
        return nil
    }

    static func subtitleVC() -> SubtitlesViewController? {
        if let tabVC = AppDelegate.sideTabVC(), let subVC = tabVC.tabViewItems[0].viewController as? SubtitlesViewController {
            return subVC
        }
        return nil
    }

    static func fontVC() -> FontViewController? {
        if let tabVC = AppDelegate.sideTabVC(), let fontVC = tabVC.tabViewItems[1].viewController as? FontViewController {
            return fontVC
        }
        return nil
    }

    @IBOutlet weak var dividerAboveAppearance: NSMenuItem!
    @IBOutlet weak var appearanceSubmenu: NSMenuItem!

    func applicationWillFinishLaunching(_ notification: Notification) {
        if #available(OSX 10.14, *) {
            if let pref = UserDefaults.standard.value(forKey: "AppearancePreference") as? Int {
                if pref == 0 {
                    useDarkAppearance(self)
                } else if pref == 1 {
                    useLightAppearance(self)
                } else if pref == 2 {
                    followSystemAppearance(self)
                }
            } else {
                useDarkAppearance(self)
            }
        } else {
            dividerAboveAppearance.isHidden = true
            appearanceSubmenu.isHidden = true
        }
    }

    @IBAction func installFCPXExtras(_ sender: Any) {
        Helper.installFCPXCaptionFiles(callback: nil)
    }

    @objc func saveAll() {
        self.saveEverything(self)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(saveAll), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // UserDefaults.standard.set(true, forKey: "SUAutomaticallyUpdate")

        do {
            let fetchRequest: NSFetchRequest<EpisodeProject> = EpisodeProject.fetchRequest()
            let episodeProjects = try Helper.context!.fetch(fetchRequest)
            for proj in episodeProjects {
                if proj.videoURL == nil {
                    Helper.context!.delete(proj)
                }
            }
        } catch {
            print(error)
        }

        saveEverything(self)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag == false {
            
            for window in sender.windows {
                if (window.delegate?.isKind(of: CaptionWindowController.self)) == true {
                    window.makeKeyAndOrderFront(self)
                }
            }
        }
        
        return true

    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func openNewWindow(_ sender: Any) {
        AppDelegate.sourceListVC()?.addNewProject()
    }

    @IBAction func openVideoFile(_ sender: NSMenuItem) {
        AppDelegate.movieVC()?.openFile(self)
    }
    
    @IBAction func saveSRTFile(_ sender: NSMenuItem) {
        AppDelegate.movieVC()?.saveSRTToDisk(self)
    }
    
    @IBAction func saveTXTFile(_ sender: Any) {
        AppDelegate.movieVC()?.saveTXTToDisk(self)
    }

    @IBAction func saveFCPXMLFile(_ sender: Any) {
        AppDelegate.movieVC()?.saveFCPXMLToDisk(self)
    }


    @IBAction func saveEverything(_ sender: Any) {
        saveAction(nil)
    }

    @IBAction func useDarkAppearance(_ sender: Any) {
        if #available(OSX 10.14, *) {
            NSApp.appearance = NSAppearance(named: .darkAqua)
            UserDefaults.standard.setValue(0, forKey: "AppearancePreference")
            darkMenuItem.state = .on
            lightMenuItem.state = .off
            followSystemMenuItem.state = .off
        }
    }

    @IBAction func useLightAppearance(_ sender: Any) {
        if #available(OSX 10.14, *) {
            NSApp.appearance = NSAppearance(named: .aqua)
            UserDefaults.standard.setValue(1, forKey: "AppearancePreference")
            darkMenuItem.state = .off
            lightMenuItem.state = .on
            followSystemMenuItem.state = .off
        }
    }

    @IBAction func followSystemAppearance(_ sender: Any) {
        if #available(OSX 10.14, *) {
            NSApp.appearance = nil
            UserDefaults.standard.setValue(2, forKey: "AppearancePreference")
            darkMenuItem.state = .off
            lightMenuItem.state = .off
            followSystemMenuItem.state = .on
        }
    }


    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Test.OldCoreData" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("Caption")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Caption", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }

        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.appendingPathComponent("CocoaAppCD.storedata")
            do {
                try coordinator!.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: nil)
            } catch {
                failError = error as NSError
            }
        }

        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.shared.presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.

        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }

        if !managedObjectContext.hasChanges {
            return .terminateNow
        }

        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }

            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)

            let answer = alert.runModal()
            if answer == NSApplication.ModalResponse.alertFirstButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

    // MARK: - Menu Bar Items
    @IBAction func togglePlaybackPausing(_ sender: Any) {
        AppDelegate.movieVC()?.playPauseClicked(sender)
    }

    @IBAction func bladeClicked(_ sender: Any) {

    }

    @IBAction func joinCaptionClicked(_ sender: Any) {
    }

    @IBAction func trimStartClicked(_ sender: Any) {
    }

    @IBAction func trimEndClicked(_ sender: Any) {
    }

    @IBAction func deleteCaptionClicked(_ sender: Any) {
    }

    @IBAction func revealCaptionInEditorClicked(_ sender: Any) {
    }

    @IBAction func revealCaptionInTimelineClicked(_ sender: Any) {
    }

    @IBAction func revealVideoInFinderClicked(_ sender: Any) {
        AppDelegate.sourceListVC()?.showActiveVideoInFinderClicked(self)
    }

    var email: String {
        get {
            return ["lu", "mi", "ng", "yin", "-", "ho", "tm", "ai", "l.", "co", "m"].joined().replacingOccurrences(of: "-", with: "@")
        }
    }

    @IBAction func contactSupportClicked(_ sender: Any) {
        sendEmail(emailType: "Contact Support")
    }

    @IBAction func provideFeedbackClicked(_ sender: Any) {
        sendEmail(emailType: "Provide Feedback")
    }

    func sendEmail(emailType: String) {
        let info = GBDeviceInfo.deviceInfo()?.description
        let emailBody = """
        Briefly describe the issue you're experiencing or provide feedback:


        -----
        \(info ?? "")
        """
        let emailService =  NSSharingService.init(named: NSSharingService.Name.composeEmail)!
        emailService.recipients = [email]
        emailService.subject = "Quick Caption: \(emailType)"

        if emailService.canPerform(withItems: [emailBody]) {
            emailService.perform(withItems: [emailBody])
        } else {
            Helper.displayInformationalSheet(title: "\(emailType)", text: "To \(emailType), send an email to \(email).")
        }
    }

    @IBAction func displayAcknowledgements(_ sender: Any) {
        if let bundleURL = Bundle.main.url(forResource: "QuickCaption_Acknowledgements", withExtension: "pdf") {
            NSWorkspace.shared.open(bundleURL)
        }
    }

    @IBAction func projectNavigatorClicked(_ sender: Any) {
        AppDelegate.mainWindow()?.toggleSidebarList(self)
    }

    @IBAction func captionEditorClicked(_ sender: Any) {
        AppDelegate.mainWindow()?.contentSettingsSidebarHandler(index: 0)
    }

    @IBAction func styleEditorClicked(_ sender: Any) {
        AppDelegate.mainWindow()?.contentSettingsSidebarHandler(index: 1)
    }

    @IBAction func focusOnPlayer(_ sender: Any) {
        NSApp.mainWindow?.makeFirstResponder(AppDelegate.movieVC())
    }

    @IBAction func replaceCaptionsWithSRT(_ sender: Any) {
    }

    @IBAction func checkForUpdates(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "macappstore://itunes.apple.com/us/app/quick-caption/id1363610340?mt=12")!)
    }

}


