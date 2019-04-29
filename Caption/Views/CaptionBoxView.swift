//
//  CaptionBoxView.swift
//  Quick Caption
//
//  Created by Blue on 3/16/19.
//  Copyright © 2019 Bright. All rights reserved.
//

import Cocoa

enum CaptionManipulationState {
    case normal
    case dragging
    case hovering
    case placeholder
}

class CaptionBoxView: NSView {
    var captionText: String = ""
    var state: CaptionManipulationState = .normal

    lazy var layoutManager: NSLayoutManager = {
        var layoutManager = NSLayoutManager()
        layoutManager.typesetterBehavior = .behavior_10_2_WithCompatibility
        return layoutManager
    }()

    func renderText(_ string:String, x: CGFloat, y: CGFloat, numberOfLines: Int, withColor color:NSColor) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 11)
        let textHeight = layoutManager.defaultLineHeight(for: font) * CGFloat(numberOfLines)
        let textRect = CGRect(x: x, y: y, width: self.bounds.width - 2 * CaptionBoxView.horizontalPadding, height: textHeight - 2 * CaptionBoxView.verticalPadding)
        string.draw(in: textRect, withAttributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color])
        return textHeight
    }

    static let horizontalPadding: CGFloat = 5
    static let verticalPadding: CGFloat = 15

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if captionText.count == 0 {
            NSColor(calibratedRed: 24 / 255, green: 15 / 255, blue: 41 / 255, alpha: 1.0).setFill()
//            NSColor(red: 24 / 255, green: 15 / 255, blue: 41 / 255, alpha: 1.0).setFill()
        } else {
            NSColor(calibratedRed: 63 / 255, green: 34 / 255, blue: 114 / 255, alpha: 1.0).setFill()
        }
        let path = NSBezierPath(roundedRect: self.bounds, xRadius: 6, yRadius: 6)
        path.fill()

        NSColor.white.withAlphaComponent(0.6).setStroke()
        let smallerRectForFraming = self.bounds.insetBy(dx: 1, dy: 1)
        let smallPath = NSBezierPath(roundedRect: smallerRectForFraming, xRadius: 5, yRadius: 5)
        smallPath.stroke()

        if (state == .dragging) {
            let smallerRectForFraming = self.bounds.insetBy(dx: 2, dy: 2)
            let smallPath = NSBezierPath(roundedRect: smallerRectForFraming, xRadius: 5, yRadius: 5)
            smallPath.lineWidth = 2
            NSColor.yellow.withAlphaComponent(0.6).setStroke()
            smallPath.stroke()
        } else if (state == .hovering) {
            let smallerRectForFraming = self.bounds.insetBy(dx: 2, dy: 2)
            let smallPath = NSBezierPath(roundedRect: smallerRectForFraming, xRadius: 5, yRadius: 5)
            smallPath.lineWidth = 2
            NSColor.red.withAlphaComponent(0.6).setStroke()
            smallPath.stroke()
        }

        let textColor = NSColor(calibratedRed: 179 / 255, green: 152 / 255, blue: 233 / 255, alpha: 1.0)
        _ = renderText(captionText, x: CaptionBoxView.horizontalPadding, y: CaptionBoxView.verticalPadding, numberOfLines: 5, withColor: textColor)
//        (captionText as NSString).drawLeftAligned(in: bounds, withAttributes: [.foregroundColor: textColor])
        // Drawing code here.
    }
    
}
