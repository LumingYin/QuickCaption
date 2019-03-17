//
//  CaptionWindowController.swift
//  Quick Caption
//
//  Created by Blue on 2/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class CaptionWindowController: NSWindowController, NSWindowDelegate {
    weak var splitViewController: MainSplitViewController!

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        shouldCascadeWindows = true
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        shouldCascadeWindows = true
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        self.window?.delegate = self
        shouldCascadeWindows = true
        if let svc = contentViewController as? MainSplitViewController {
            self.splitViewController = svc
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if let vc = self.contentViewController as? MovieViewController {
            if (vc.episode.player != nil) {
                let response = Helper.dialogTwoButton(question: "Save Captions?", text: "Would you like to save your captions before closing?")
                print(response)
                if response {
                    vc.saveToDisk(.srt)
                }
            }
        }
        return true
    }

    @IBAction func toggleSidebarList(_ sender: Any) {
        splitViewController.splitViewItems[0].isCollapsed = !splitViewController.splitViewItems[0].isCollapsed
    }

    @IBAction func addNewProjectClicked(_ sender: Any) {
        AppDelegate.sourceListVC()?.addNewProject()
    }

    @IBAction func importVideoFootageClicked(_ sender: Any) {
        let movieVC = splitViewController.splitViewItems[1].viewController as! MovieViewController
        movieVC.openFile(self)
    }

    @IBAction func shareResultsButtonClicked(_ sender: NSButton) {
        if let vc = storyboard?.instantiateController(withIdentifier: "ExportCaptions") as? NSViewController {
            self.contentViewController?.present(vc, asPopoverRelativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY, behavior: .transient)
        }
    }

    @IBAction func contentSettingsSidebarClicked(_ sender: NSSegmentedControl) {
        if sender.selectedSegment < 2 {
            AppDelegate.sideTabVC()?.tabView.selectTabViewItem(at: sender.indexOfSelectedItem)
        }
    }

}
