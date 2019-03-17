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
    @IBOutlet var contextMenu: NSMenu!


    @IBAction func duplicateClicked(_ sender: Any) {
    }

    @IBAction func deleteClicked(_ sender: Any) {
        let row = tableView.clickedRow
        let project = episodeProjects[row]
        var newRow = row + 1
        if newRow > episodeProjects.count - 1 {
            newRow = row - 1
        }
        if newRow < 0 || episodeProjects.count <= 0 {
            addNewProject()
            newRow = 0
        }
        tableView.selectRowIndexes(IndexSet(integer: newRow), byExtendingSelection: false)
        Helper.context?.delete(project)
        tableView.removeRows(at: IndexSet(integer: row), withAnimation: .slideDown)
    }

    @IBAction func exportFCPXMLClicked(_ sender: Any) {
        let row = tableView.clickedRow
        let project = episodeProjects[row]
        
    }

    @IBAction func exportSRTClicked(_ sender: Any) {
    }

    @IBAction func exportTXTClicked(_ sender: Any) {
    }

    @IBOutlet weak var duplicateClicked: NSMenuItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDBData()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsEmptySelection = false
    }

    func fetchDBData() {
        do {
            let fetchRequest: NSFetchRequest<EpisodeProject> = EpisodeProject.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
            episodeProjects = try Helper.context!.fetch(fetchRequest)
        } catch {
            print("Can't fetch persistence store with: \(error)")
        }
        for episode in episodeProjects {
            if episode.guidIdentifier == nil {
                episode.guidIdentifier = NSUUID().uuidString
            }
            episode.addObserver(self, forKeyPath: "videoURL", options: [.new], context: nil)
            episode.addObserver(self, forKeyPath: "thumbnailURL", options: [.new], context: nil)
            episode.addObserver(self, forKeyPath: "videoDescription", options: [.new], context: nil)
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let project = object as? EpisodeProject, let index = episodeProjects.firstIndex(of: project) {
            tableView.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 0))
        }
    }

    override func viewDidAppear() {
        if (episodeProjects.count == 0) {
            addNewProject()
            updateSelectRow(index: 0)
        }
    }

    func addNewProject() {
        let episode = EpisodeProject(context: Helper.context!)
        episode.guidIdentifier = NSUUID().uuidString
        episode.creationDate = NSDate()
        episode.modifiedDate = NSDate()
        episodeProjects.append(episode)
        fetchDBData()
        tableView.insertRows(at: IndexSet(integer: 0), withAnimation: .slideDown)
        tableView.reloadData(forRowIndexes: IndexSet(integer: 0), columnIndexes: IndexSet(integer: 0))
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SidebarEpisodeTableCellView"), owner: self) as? SidebarEpisodeTableCellView {
            let episode = episodeProjects[row]
            view.videoFileNameTextField.stringValue = episode.videoDescription ?? "Video Clip"
            let formatter = DateFormatter.init()
            formatter.dateFormat = "MMM dd, yyyy"
            if let date = episode.modifiedDate as Date? {
                view.lastModifiedDateTextField.stringValue = formatter.string(from: date)
            }
            if let url = episode.thumbnailURL, let image = NSImage(contentsOf: url) {
                view.episodePreview?.image = image
            } else {
                view.episodePreview?.image = NSImage(named: "bunny")
            }
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
        for project in episodeProjects {
            if let player = project.player {
                player.pause()
            }
        }
//        AppDelegate.rebuildMovieAndSubVC()
        AppDelegate.subtitleVC()?.dismantleSubtitleVC()
        let project = episodeProjects[index]
        AppDelegate.movieVC()?.dismantleOldMovieVC()
        AppDelegate.movieVC()?.episode = project
        AppDelegate.movieVC()?.configurateMovieVC()
        AppDelegate.subtitleVC()?.episode = project
        AppDelegate.subtitleVC()?.configurateSubtitleVC()
        AppDelegate.fontVC()?.dismantleOldFontVC()
        AppDelegate.fontVC()?.episode = project
        AppDelegate.fontVC()?.configurateFontVC()
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
