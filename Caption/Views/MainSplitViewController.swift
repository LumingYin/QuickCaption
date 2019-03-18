//
//  MainSplitViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {

    var minimumPaneWidths: [CGFloat] = [85, 450, 450]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }

    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        return NSZeroRect
    }

//    override func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        var widthUpToSubview: CGFloat = 0
//        for pane in splitView.subviews {
//            let paneWidth: CGFloat = pane.frame.size.width
//            widthUpToSubview += paneWidth
//        }
//        let minAllowedWidth: CGFloat = widthUpToSubview + minimumPaneWidths[dividerIndex]
//        return proposedMinimumPosition < minAllowedWidth ? minAllowedWidth : proposedMinimumPosition
//
//    }
//
//    override func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
//        var widthDownToSubview: CGFloat = 0
//        var i = splitView.subviews.count - 1
//        while i > dividerIndex + 1 {
//            let pane = splitView.subviews[i]
//            let paneWidth: CGFloat = pane.frame.size.width
//            widthDownToSubview += paneWidth
//            i -= 1
//        }
//        let splitViewWidth: CGFloat = splitView.frame.size.width
//        let minPaneWidth = minimumPaneWidths[dividerIndex + 1]
//        let maxAllowedWidth: CGFloat = splitViewWidth - (widthDownToSubview + minPaneWidth)
//        return proposedMaximumPosition > maxAllowedWidth ? maxAllowedWidth : proposedMaximumPosition
//    }
    
    
}
