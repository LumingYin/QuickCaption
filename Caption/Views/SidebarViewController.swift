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

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        // Do view setup here.
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 15
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 66
    }

    
    
}
