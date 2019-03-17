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
        }
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
        let episode = EpisodeProject(context: Helper.context!)
        episode.guidIdentifier = NSUUID().uuidString
        episodeProjects.append(episode)
        episodeProjects.sort { (ep1, ep2) -> Bool in
            if let d1 = ep1.modifiedDate as Date?, let d2 = ep2.modifiedDate as Date? {
                return d1 > d2
            }
            return false
        }
        tableView.reloadData()
//        tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
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
        let project = episodeProjects[index]
        AppDelegate.movieVC()?.dismantleOldMovieVC()
        AppDelegate.movieVC()?.episode = project
        AppDelegate.movieVC()?.configurateMovieVC()
        AppDelegate.subtitleVC()?.episode = project
        AppDelegate.subtitleVC()?.configurateSubtitleVC()
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
