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
        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            vc.openFile(self)
        }
    }
    
    @IBAction func saveSRTFile(_ sender: NSMenuItem) {
        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            vc.saveToDisk(.srt)
        }
    }
    @IBAction func saveTXTFile(_ sender: Any) {
        if let vc = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            vc.saveToDisk(.txt)
        }
    }
    
}


