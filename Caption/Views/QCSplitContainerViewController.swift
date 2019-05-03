//
//  QCSplitContainerViewController.swift
//  Quick Caption
//
//  Created by blue on 5/2/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class QCSplitContainerViewController: NSViewController, NSSplitViewDelegate {
    @IBOutlet weak var splitView: NSSplitView!
    var sidebarVC: SidebarViewController!
    var movieVC: MovieViewController!
    var fontVC: SideTabViewController!
    var lastWidth: [Int : CGFloat] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.delegate = self
        
        let mainStoryboard = NSStoryboard(name: "Main", bundle: nil)
        sidebarVC = mainStoryboard.instantiateController(withIdentifier: "SidebarViewController") as! SidebarViewController
        movieVC = mainStoryboard.instantiateController(withIdentifier: "MovieViewController") as! MovieViewController
        fontVC = mainStoryboard.instantiateController(withIdentifier: "SideTabViewController") as! SideTabViewController

        splitView.addArrangedSubview(sidebarVC.view)
        splitView.addArrangedSubview(movieVC.view)
        splitView.addArrangedSubview(fontVC.view)
    }
    
    func collapseExpandSubview(subVC: NSViewController, dividerIndex: Int) {
        if (self.splitView.isSubviewCollapsed(subVC.view)) {
            collapseSubview(subVC: subVC, dividerIndex: dividerIndex)
        } else {
            expandSubview(subVC: subVC, dividerIndex: dividerIndex)
        }
    }
    
    func collapseSubview(subVC: NSViewController, dividerIndex: Int) {
        if let width = lastWidth[dividerIndex] {
            self.splitView.setPosition(width, ofDividerAt: dividerIndex)
        }
        self.splitView.layoutSubtreeIfNeeded()
    }
    
    func expandSubview(subVC: NSViewController, dividerIndex: Int) {
        lastWidth[dividerIndex] = subVC.view.frame.size.width
        self.splitView.setPosition(0, ofDividerAt: dividerIndex)
        self.splitView.layoutSubtreeIfNeeded()
    }
    
}
