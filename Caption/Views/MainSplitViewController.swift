//
//  MainSplitViewController.swift
//  Quick Caption
//
//  Created by Blue on 3/11/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

class MainSplitViewController: NSSplitViewController {

//    var minimumPaneWidths: [CGFloat] = [85, 450, 450]

    override func viewDidLoad() {
        super.viewDidLoad()
        let leftPane = self.splitViewItems[0].viewController.view
        let midPane = self.splitViewItems[1].viewController.view
        let rightPane = self.splitViewItems[2].viewController.view

//        leftPane.addConstraint(NSLayoutConstraint(item: leftPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 220))
//        self.splitView.addConstraint(NSLayoutConstraint(item: leftPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.splitView, attribute: .width, multiplier: 0.2, constant: 0))
        
//        midPane.addConstraint(NSLayoutConstraint(item: midPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 500))
//        self.splitView.addConstraint(NSLayoutConstraint(item: midPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.splitView, attribute: .width, multiplier: 0.3, constant: 0))

//        rightPane.addConstraint(NSLayoutConstraint(item: rightPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 295))
//        self.splitView.addConstraint(NSLayoutConstraint(item: rightPane, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: self.splitView, attribute: .width, multiplier: 0.19, constant: 0))

//        [leftPane addConstraint:[NSLayoutConstraint constraintWithItem:leftPane attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:200]];
//        [parentView addConstraint:[NSLayoutConstraint constraintWithItem:leftPane attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:parentView attribute:NSLayoutAttributeWidth multiplier:1./3. constant:0]];

        // Do view setup here.
    }

//    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
//        return NSZeroRect
//    }

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
