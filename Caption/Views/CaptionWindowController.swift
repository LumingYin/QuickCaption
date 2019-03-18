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
    @IBOutlet weak var currentTitle: NSTextField!
    @IBOutlet weak var contentSettingsSegmentedControl: NSSegmentedControl!

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

//    func windowShouldClose(_ sender: NSWindow) -> Bool {
//        return true
//    }

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
        contentSettingsSidebarHandler(index: sender.selectedSegment)
    }

    func contentSettingsSidebarHandler(index: Int) {
        if index < 2 {
            if let tabView = AppDelegate.sideTabVC()?.tabView, let selected = tabView.selectedTabViewItem {
                if tabView.indexOfTabViewItem(selected) == index {
                    // collapse sidebar
                    splitViewController.splitViewItems[2].isCollapsed = !splitViewController.splitViewItems[2].isCollapsed
                    if (splitViewController.splitViewItems[2].isCollapsed) {
                        contentSettingsSegmentedControl.setSelected(false, forSegment: 0)
                        contentSettingsSegmentedControl.setSelected(false, forSegment: 1)
                    }
                } else {
                    AppDelegate.sideTabVC()?.tabView.selectTabViewItem(at: index)
                    splitViewController.splitViewItems[2].isCollapsed = false
                    contentSettingsSegmentedControl.setSelected(true, forSegment: index)
                }
            }
        }
    }

}
