//
//  AppDelegate.swift
//  Caption
//
//  Created by Bright on 7/29/17.
//  Copyright © 2017 Bright. All rights reserved.
//

import Cocoa
import LetsMove
import Sparkle
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

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

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if DEBUG
        #else
        PFMoveToApplicationsFolderIfNecessary()
        #endif
        SUUpdater.shared()?.checkForUpdatesInBackground()
        UserDefaults.standard.set(true, forKey: "SUAutomaticallyUpdate")
        MSAppCenter.start("c5be1193-d482-4d0e-99a9-b5901f40d6f3", withServices:[
            MSAnalytics.self,
            MSCrashes.self,
            ])
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        UserDefaults.standard.set(true, forKey: "SUAutomaticallyUpdate")
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
        if #available(OSX 10.13, *) {
            guard let captionWindowController = NSStoryboard.main?.instantiateController(withIdentifier: "mainWindow") as? CaptionWindowController else {
                return
            }
            captionWindowController.shouldCascadeWindows = true
            captionWindowController.showWindow(self)
        } else {
        }
    }

    @IBAction func openNewTab(_ sender: Any) {
        if #available(OSX 10.13, *) {
            guard let captionWindowController = NSStoryboard.main?.instantiateController(withIdentifier: "mainWindow") as? CaptionWindowController else {
                return
            }
            NSApplication.shared.mainWindow?.addTabbedWindow(captionWindowController.window!, ordered: .above)
            captionWindowController.shouldCascadeWindows = true
            captionWindowController.showWindow(self)
        } else {
        }
    }


    @IBAction func openVideoFile(_ sender: NSMenuItem) {
        AppDelegate.movieVC()?.openFile(self)
    }
    
    @IBAction func saveSRTFile(_ sender: NSMenuItem) {
        AppDelegate.movieVC()?.saveToDisk(.srt)
    }
    
    @IBAction func saveTXTFile(_ sender: Any) {
        AppDelegate.movieVC()?.saveToDisk(.txt)
    }


    // MARK: - Core Data

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Caption")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }

        if !context.hasChanges {
            return .terminateNow
        }

        do {
            try context.save()
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
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

    
}


