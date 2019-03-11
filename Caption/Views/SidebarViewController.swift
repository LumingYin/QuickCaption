//
//  SidebarViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/10/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableView: NSTableView!
    var episodeProjects: [EpisodeProject] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }

    override func viewDidAppear() {
        if (episodeProjects.count == 0) {
            addNewProject()
            updateSelectRow(index: 0)
        }
    }

    func addNewProject() {
        episodeProjects.append(EpisodeProject())
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SidebarEpisodeTableCellView"), owner: self) as? SidebarEpisodeTableCellView {
            view.videoFileNameTextField.stringValue = "Some Name"
            view.lastModifiedDateTextField.stringValue = "Some Time"
            return view
        }
        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateSelectRow(index: tableView.selectedRow)
    }

    func updateSelectRow(index: Int) {
        if index < 0 {
            return
        }
        let project = episodeProjects[index]
        AppDelegate.movieVC()?.episode = project
        AppDelegate.subtitleVC()?.episode = project
        AppDelegate.subtitleVC()?.configurateSubtitleVC()
        print("Selected: \(project)")
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if row < 0 {
            return false
        }
        return true
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return episodeProjects.count
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 66
    }

    
    
}
