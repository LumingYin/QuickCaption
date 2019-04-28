//
//  ComboColorWell.swift
//  Tasty Testy
//
//  Created by Ernesto Giannotta on 16-08-18.
//  Copyright © 2018 Apimac. All rights reserved.
//

import Cocoa

/**
 A control to pick a color.
 It has the look & feel of the color control of Apple apps like Pages, Numbers etc.
 */
class ComboColorWell: NSControl {
    
    // MARK: - public vars
    
    /**
     The color currently represented by the control.
     */
    @IBInspectable var color: NSColor {
        get {
            return comboColorWellCell.color
        }
        set {
            comboColorWellCell.color = newValue
        }
    }
    
    /**
     Set this to false if you don't want the popover to show the clear color in the grid.
     */
    @IBInspectable var allowClearColor: Bool {
        get {
            return comboColorWellCell.allowClearColor
        }
        set {
            comboColorWellCell.allowClearColor = newValue
        }
    }
    
    // MARK: - private vars

    /**
     The action cell that will do the heavy lifting for the us.
     */
    private var comboColorWellCell: ComboColorWellCell {
        guard let cell = cell as? ComboColorWellCell else { fatalError("ComboColorWellCell not valid") }
        return cell
    }
    
    // MARK: - Overridden functions
    
    override func resignFirstResponder() -> Bool {
        comboColorWellCell.state = .off
        return super.resignFirstResponder()
    }

    // MARK: - init & private functions
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        doInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        doInit()
    }
    
    private func doInit() {
        cell = ComboColorWellCell()
    }
    
}

extension ComboColorWell: NSColorChanging {
    func changeColor(_ sender: NSColorPanel?) {
        if let sender = sender {
            comboColorWellCell.colorAction(sender)
        }
    }
}

/**
 The action cell that will do the heavy lifting for the ComboColorWell control.
 */
class ComboColorWellCell: NSActionCell {
    /**
     Enumerate sensible areas of the control cell.
     */
    enum ControlArea {
        case nothing
        case color
        case button
    }
    /**
     Enumerate possible mouse states.
     */
    enum MouseState {
        case outside
        case over(ControlArea)
        case down(ControlArea)
        case up(ControlArea)
    }
    
    // MARK: - public vars
    
    /**
     The color we're representing.
     */
    var color = NSColor.black {
        didSet {
            controlView?.needsDisplay = true
        }
    }
    /**
     Set this to false if you don't want the popover to show the clear color in the grid.
     */
    var allowClearColor = true

    // MARK: - public functions
    
    func mouseEntered(with event: NSEvent) {
        if isEnabled {
            mouseMoved(with: event)
        }
    }
    
    func mouseExited(with event: NSEvent) {
        if isEnabled {
            mouseState = .outside
        }
    }
    
    func mouseMoved(with event: NSEvent) {
        if isEnabled {
            mouseState = .over(controlArea(for: event))
        }
    }
    
    /**
     The standard objc action function to handle color change messages from the Color panel and Color popover.
     */
    @objc func colorAction(_ sender: ColorProvider) {
        action(for: sender.color)
    }
    
    /**
     The function that will propagate the control action message to the control target.
     */
    private func action(for color: NSColor) {
        self.color = color
        if let control = controlView as? NSControl {
            control.sendAction(control.action, to: control.target)
        }
    }

    // MARK: - private vars
    
    /**
     A NSResponder to handle mouse events.
     */
    private lazy var mouseTracker = {
        return MouseTracker(mouseEntered: { self.mouseEntered(with: $0) },
                            mouseExited: { self.mouseExited(with: $0) },
                            mouseMoved: { self.mouseMoved(with: $0) })
    }()
    
    /**
     The current mouse state.
     */
    private var mouseState = MouseState.outside {
        didSet {
            if mouseState != oldValue {
                handleMouseState(mouseState)
                controlView?.needsDisplay = true
            }
        }
    }
    
    /**
     Keep track of the colors popover visibility.
     */
    private var colorsPopoverVisible = false

    /**
     How much we want to inset the images (down arrow and color wheel) in the control.
     */
    private let imageInset = CGFloat(3.5)

    // MARK: - overrided vars

    override var controlView: NSView? {
        didSet {
            // add a tracking area to let our mouse tracker handle significant events
            controlView?.addTrackingArea(NSTrackingArea(rect: NSZeroRect,
                                                        options: [.mouseEnteredAndExited,
                                                                  .mouseMoved,
                                                                  .activeInKeyWindow,
                                                                  .inVisibleRect],
                                                        owner: mouseTracker,
                                                        userInfo: nil))
        }
    }
    
    override var state: NSControl.StateValue {
        didSet {
            // handle the new state
            handleStateChange()
        }
    }
    
    // MARK: - overrided functions
    
    override func setNextState() {
        // disable next state default setting, called mainly by the default cell mouse tracking
        return
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        // helper functions
        
        /**
         Fill the passed path with the passed color.
         */
        func fill(path: NSBezierPath, withColor color: NSColor = .controlColor) {
            color.setFill()
            path.fill()
        }

        /**
         Fill the passed path with the passed gradient.
        */
        func fill(path: NSBezierPath, withGradient gradient: NSGradient) {
            gradient.draw(in: path, angle: 90.0)
        }
        
        // hard coded colors and gradients
        let buttonGradient: NSGradient = {
            NSGradient(starting: NSColor(red: 17, green: 103, blue: 255),
                       ending: NSColor(red: 95, green: 165, blue: 255))!
        }()
        
        NSColor.black.withAlphaComponent(0.25).setStroke()

        // give some space to the control rect for anti aliasing
        let smoothRect = NSInsetRect(cellFrame, 0.5, 0.5)
        
        // the bezier path defining the control
        let path = NSBezierPath(roundedRect: smoothRect, xRadius: 6.0, yRadius: 6.0)
        path.lineWidth = 0.0
        
        if state == .on {
            // on state always draws a selected button
            fill(path: path, withGradient: buttonGradient)
        } else {
            switch mouseState {
            case .outside,
                 .up:
                fill(path: path)
            case let .over(controlArea):
                switch controlArea {
                case .button:
                    // mouse over button draws a darker background
                    fill(path: path, withColor: NSColor.lightGray.withAlphaComponent(0.25))
                default:
                    fill(path: path)
                }
            case let .down(controlArea):
                switch controlArea {
                case .button:
                    // clicked button draws selected
                    fill(path: path, withGradient: buttonGradient)
                default:
                    fill(path: path)
                }
            }
        }
        
        #imageLiteral(resourceName: "ColorWheel").draw(in: NSInsetRect(buttonArea(withFrame: cellFrame, smoothed: true), imageInset, imageInset))

        // clip to fill the color area
        NSBezierPath.clip(colorArea(withFrame: cellFrame))

        if color == .clear {
            // want a diagonal black & white split
            // start filling all white
            fill(path: path, withColor: .white)
            // get the color area
            let area = colorArea(withFrame: cellFrame)
            // get an empty bezier path to draw the black portion
            let blackPath = NSBezierPath()
            // get the origin point of the color area
            var point = area.origin
            // set it the starting point of the black path
            blackPath.move(to: point)
            // draw a line to opposite diagonal
            point = NSPoint(x: area.width, y: area.height)
            blackPath.line(to: point)
            // draw a line back to origin x
            point.x = area.origin.x
            blackPath.line(to: point)
            // close the triangle
            blackPath.close()
            // add clip with the control shape
            path.addClip()
            // finally draw the black portion
            fill(path: blackPath, withColor: .black)
        } else {
            fill(path: path, withColor: color)
        }
        
        // reset the clipping area
        path.setClip()
        // draw the control border
        path.stroke()

        if !isEnabled {
            fill(path: path, withColor: NSColor(calibratedWhite: 1.0, alpha: 0.25))
        }

        switch mouseState {
        case let .over(controlArea),
             let .down(controlArea):
            switch controlArea {
            case .color:
                #imageLiteral(resourceName: "CircledDownArrow").draw(in: popoverButtonArea(withFrame: cellFrame, smoothed: true))
            default:
                break
            }
        default:
            break
        }
        
    }
    
    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        switch controlArea(for: startPoint, in: controlView) {
        case .color:
//            print("color click")
            mouseState = .down(.color)
        case .button:
//            print("button click")
            mouseState = .down(.button)
        default:
//            print("nothing click")
            mouseState = .outside
        }
        return true
    }
    
    override func stopTracking(last lastPoint: NSPoint, current stopPoint: NSPoint, in controlView: NSView, mouseIsUp flag: Bool) {
        if !flag {
//            print("dragging outside")
            mouseState = .outside
            return
        }
        switch controlArea(for: stopPoint, in: controlView) {
        case .color:
//            print("color up")
            mouseState = .up(.color)
        case .button:
//            print("button up")
            mouseState = .up(.button)
        default:
//            print("nothing up")
            mouseState = .up(.nothing)
       }
    }
    
    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) -> Bool {
        mouseState = .down(controlArea(for: currentPoint, in: controlView))
        
        return true
    }
    
    // MARK: - private functions

    /**
     Handle mpuse state here, currently we're only interested in mouse ups.
     */
    private func handleMouseState(_ state: MouseState) {
        switch state {
//        case .outside:
//            print("outside")
//        case let .over(controlArea):
//            switch controlArea {
//            case .color:
//                print("over color")
//            case .button:
//                print("over button")
//            default:
//                print("over nothing")
//            }
//        case let .down(controlArea):
//            switch controlArea {
//            case .color:
//                print("down color")
//            case .button:
//                print("down button")
//            default:
//                print("down nothing")
//            }
        case let .up(controlArea):
//            switch controlArea {
//            case .color:
//                print("up color")
//            case .button:
//                print("up button")
//            default:
//                print("up nothing")
//            }
            handleMouseUp(in: controlArea)
            mouseState = .over(controlArea)
        default:
            break
       }
    }

    /**
     Handle mouse up clicks here.
     */
    private func handleMouseUp(in controlArea: ControlArea) {
        switch controlArea {
        case .button:
            // toggle on and of state
            state = (state == .on ? .off : .on)
        case .color:
            // switch state off
            state = .off
            if colorsPopoverVisible {
                // popover already visible, just bail out
                return
            }
            // we need the control view to show the popove relative to it
            guard let view = controlView else { break }
            // create a popover
            let popover = NSPopover()
            popover.animates = false
            popover.behavior = .semitransient
            // make ourself its delegate
            popover.delegate = self
            // create a Color grid and set it as the popover content
            popover.contentViewController = ColorGridController(color: color,
                                                                target: self,
                                                                action: #selector(colorAction(_:)),
                                                                allowClearColor: allowClearColor)
            // show the popover
            popover.show(relativeTo: popoverButtonArea(withFrame: view.bounds), of: view, preferredEdge: .minY)
            // update the visible flag
            colorsPopoverVisible = true
        default:
            mouseState = .over(controlArea)
        }
    }
    
    /**
     Handle state change here.
     */
    private func handleStateChange() {
        let colorPanel = NSColorPanel.shared
        switch state {
        case .off:
            if colorPanel.isVisible,
                colorPanel.delegate === self {
                colorPanel.delegate = nil
            }
        case .on:
            if let window = controlView?.window,
                window.makeFirstResponder(controlView) {
                colorPanel.delegate = self
                colorPanel.showsAlpha = allowClearColor
                colorPanel.color = color
                colorPanel.orderFront(self)
            }
        default:
            break
        }
    }
    
    /**
     Get the rect of the control that displays the selected color.
     */
    private func colorArea(withFrame cellFrame: NSRect, smoothed: Bool = false) -> NSRect {
        var rect = smoothed ? NSInsetRect(cellFrame, 0.5, 0.5) : cellFrame
        rect.size.width -= rect.size.height
        return rect
    }

    /**
     Get the rect of the control that displays the color panel button.
     */
    private func buttonArea(withFrame cellFrame: NSRect, smoothed: Bool = false) -> NSRect {
        var rect = smoothed ? NSInsetRect(cellFrame, 0.5, 0.5) : cellFrame
        rect.origin.x += (rect.width - rect.height)
        rect.size.width = rect.height
        return rect
    }
    
    /**
     Get the rect of the control where a down arrow button should be drawn.
     */
    private func popoverButtonArea(withFrame cellFrame: NSRect, smoothed: Bool = false) -> NSRect {
        let buttonSize = CGFloat(15.0)
        let rect = colorArea(withFrame: cellFrame, smoothed: smoothed)
        return NSRect(x: rect.width - (buttonSize + imageInset),
                      y: ceil((rect.height - buttonSize) / 2),
                      width: buttonSize, height: buttonSize)
    }

    /**
     Get the area of the control where a mouse event has occurred.
     */
    private func controlArea(for event: NSEvent) -> ControlArea {
        guard let controlView = controlView else { return .nothing }
        return controlArea(for: controlView.convert(event.locationInWindow, from: nil), in: controlView)
    }
    
    /**
     Get the area of the control where a point lies.
     */
    private func controlArea(for point: NSPoint, in controlView: NSView) -> ControlArea {
        if colorArea(withFrame: controlView.bounds).contains(point) {
            return .color
        } else if buttonArea(withFrame: controlView.bounds).contains(point) {
            return .button
        } else {
            return .nothing
        }
    }
    
}

// handle Color panel delegate events here.
extension ComboColorWellCell: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        state = .off
        controlView?.needsDisplay = true
    }
}

// handle Color popover delegate events here.
extension ComboColorWellCell: NSPopoverDelegate {
    func popoverWillClose(_ notification: Notification) {
        colorsPopoverVisible = false
    }
}

// removed the delegate approach
//extension ComboColorWellCell: ColorGridViewDelegate {
//    func colorGridView(_ colorGridView: ColorGridView, didChoose color: NSColor) {
//        doColorAction(color)
//    }
//}

/**
 An NSResponder subclass to handle mouse events.
 */
class MouseTracker: NSResponder {
    let mouseEnteredHandler: (_ : NSEvent) -> ()
    let mouseExitedHandler: (_ : NSEvent) -> ()
    let mouseMovedHandler: ((_ : NSEvent) -> ())?

    /**
     The designated initializer.
     Requires handlers for the entered and exited events.
     Moved event handler is optional.
     */
    init(mouseEntered enteredHandler: @escaping (_ event: NSEvent) -> (),
         mouseExited exitedHandler: @escaping (_ event: NSEvent) -> (),
         mouseMoved movedHandler: ((_ event: NSEvent) -> ())? = nil) {
        mouseEnteredHandler = enteredHandler
        mouseExitedHandler = exitedHandler
        mouseMovedHandler = movedHandler
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseEntered(with event: NSEvent) {
        mouseEnteredHandler(event)
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseExitedHandler(event)
    }
    
    override func mouseMoved(with event: NSEvent) {
        mouseMovedHandler?(event)
    }
    
}

/**
 A controller for a grid view to show and select colors.
 */
class ColorGridController: NSViewController {
    
    // MARK: - public vars
    
    /**
     The color we want to show as selected in the grid.
     */
    var color = NSColor.black {
        didSet {
            // try to select the color in the grid view.
            (view as? ColorGridView)?.selectColor(color)
        }
    }
    
    /**
     Set this to false if you don't want the popover to show the clear color in the grid.
     */
    var allowClearColor = true {
        didSet {
            // propagate setting to the grid view.
            (view as? ColorGridView)?.allowClearColor = allowClearColor
        }
    }

    // MARK: - private vars
    
    /**
     The target that will receive the action message, only it neither is nil, when color has been chosen.
     */
    private weak var target: AnyObject?
    /**
     The action that will be sent to the target, only it neither is nil, when color has been chosen.
     */
    private var action: Selector?
    /**
     The delegate that will be notified when color has been chosen.
     Deprecated approach.
     */
    private weak var delegate: ColorGridViewDelegate?
    
    // MARK: - init & overrided functions
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    convenience init(delegate: ColorGridViewDelegate) {
        self.init()
        self.delegate = delegate
    }
    
    convenience init(color: NSColor, target: AnyObject, action: Selector, allowClearColor: Bool = true) {
        self.init()
        self.color = color
        self.target = target
        self.action = action
        self.allowClearColor = allowClearColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        // create here our color grid
        let colorGrid = ColorGridView()
        view = colorGrid
        colorGrid.delegate = self
        colorGrid.allowClearColor = allowClearColor
        colorGrid.selectColor(color)
    }

}

// conform to the ColorGridViewDelegate protocol.
extension ColorGridController: ColorGridViewDelegate {
    /**
     Handle the color choice.
     */
    func colorGridView(_ colorGridView: ColorGridView, didChoose color: NSColor) {
        self.color = color
        view.window?.performClose(self)
        if let target = target,
            let action = action {
            let _ = target.perform(action, with: self)
        }
        delegate?.colorGridView(colorGridView, didChoose: color)
    }
}

/**
 Add ColorProvider conformance to NSPanel
 */
extension ColorGridController: ColorProvider {}

/**
 The protocol for a delegate to handle color choice.
 */
protocol ColorGridViewDelegate: AnyObject {
    func colorGridView(_ colorGridView: ColorGridView, didChoose color: NSColor)
}

/**
 A grid of selectable color view objects.
 */
class ColorGridView: NSGridView {
    // MARK: - public vars

    weak var delegate: ColorGridViewDelegate?
    
    /**
     An array of NSColor arrays, meant to be presented as columns in the grid.
     */
    var colorArrays: [[NSColor]] = [[NSColor(red: 72, green: 179, blue: 255),
                                NSColor(red: 18, green: 141, blue: 254),
                                NSColor(red: 12, green: 96, blue: 172),
                                NSColor(red: 7, green: 59, blue: 108),
                                .white],
                               [NSColor(red: 102, green: 255, blue: 228),
                                NSColor(red: 36, green: 228, blue: 196),
                                NSColor(red: 20, green: 154, blue: 140),
                                NSColor(red: 14, green: 105, blue: 99),
                                NSColor(red: 205, green: 203, blue: 203)],
                               [NSColor(red: 122, green: 255, blue: 62),
                                NSColor(red: 83, green: 212, blue: 42),
                                NSColor(red: 32, green: 166, blue: 3),
                                NSColor(red: 13, green: 97, blue: 2),
                                NSColor(red: 128, green: 128, blue: 128)],
                               [NSColor(red: 255, green: 255, blue: 85),
                                NSColor(red: 249, green: 222, blue: 40),
                                NSColor(red: 245, green: 173, blue: 9),
                                NSColor(red: 253, green: 128, blue: 8),
                                NSColor(red: 76, green: 76, blue: 76)],
                               [NSColor(red: 253, green: 129, blue: 122),
                                NSColor(red: 251, green: 76, blue: 62),
                                NSColor(red: 230, green: 0, blue: 14),
                                NSColor(red: 164, green: 0, blue: 2),
                                .black],
                               [NSColor(red: 252, green: 116, blue: 185),
                                NSColor(red: 232, green: 67, blue: 151),
                                NSColor(red: 189, green: 14, blue: 104),
                                NSColor(red: 133, green: 1, blue: 76),
                                .clear]] {
        didSet {
            setupGrid()
        }
    }
    
    /**
     Set this to false if you don't want the popover to show the clear color in the grid.
     */
    var allowClearColor = true {
        didSet {
            if let colorView = colorView(for: .clear) {
                colorView.isHidden = !allowClearColor
            }
        }
    }
    
    // MARK: - public functions

    /**
     Try to select the element in the grid that represents the passed color.
     */
    @discardableResult func selectColor(_ color: NSColor) -> Bool {
        if let colorView = colorView(for: color) {
            colorView.selected = true
            return true
        }
        return false
    }

    // MARK: - init & overrided functions
    
    init() {
        super.init(frame: NSZeroRect)
        
        rowSpacing = 1.0
        columnSpacing = 1.0
        
        setupGrid()
        
    }
    
    convenience init(in view: NSView) {
        self.init()
        
        // make sure to disable autoresizing mask translations
        translatesAutoresizingMaskIntoConstraints = false
        
        // add the grid view programmatically (macOS 10.12 doesn't play well with IB instantiated grids)
        view.addSubview(self)
        
        // hook the borders of the grid to the parent view
        view.addConstraints([NSLayoutConstraint(equalAttribute: .top, for: (self, view)),
                             NSLayoutConstraint(equalAttribute: .bottom, for: (self, view)),
                             NSLayoutConstraint(equalAttribute: .trailing, for: (self, view)),
                             NSLayoutConstraint(equalAttribute: .leading, for: (self, view))])
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private functions

    /**
     Build the colors grid here.
     */
    private func setupGrid() {
        // start with an empty grid
        (0..<numberOfRows).forEach { removeRow(at: $0) }
        
        // get colors as arrays of ColorView objects
        let views = colorArrays.map {
            return $0.map { ColorView(color: $0, in: self) }
        }
        
        // Treat each array in views as a column of the grid
        views.forEach { addColumn(with: $0) }
        
        setPadding(5.0)
        
        // set grid elements size and placement
        (0..<numberOfColumns).forEach {
            let column = self.column(at: $0)
            column.width = 35
            column.xPlacement = .fill
        }
        
        (0..<numberOfRows).forEach {
            let row = self.row(at: $0)
            row.height = 20
            row.yPlacement = .fill
        }

    }
    
    /**
     Set top, bottom, left and right margins as padding.
     */
    private func setPadding(_ padding: CGFloat) {
        guard numberOfRows > 0 else { return }
        
        row(at: 0).topPadding = padding
        row(at: numberOfRows - 1).bottomPadding = padding
        
        guard numberOfColumns > 0 else { return }
        
        let firstCol = column(at: 0)
        let lastCol = column(at: numberOfColumns - 1)
        
        firstCol.leadingPadding = padding
        lastCol.trailingPadding = padding
        
    }
    
    /**
     Try to find the element in the grid that represents the passed color.
     */
    private func colorView(for color: NSColor) -> ColorView? {
        for (columnIndex, colorArray) in colorArrays.enumerated() {
            if let rowIndex = colorArray.firstIndex(of: color) {
                return column(at: columnIndex).cell(at: rowIndex).contentView as? ColorView
            }
        }
        return nil
    }
    
    /**
     User has selected a color, tell it to the delegate.
     */
    fileprivate func colorSelected(_ color: NSColor) {
        delegate?.colorGridView(self, didChoose: color)
    }
    
}

/**
 A view to represent a color in a grid.
 */
class ColorView: NSView {
    
    // MARK: - public vars
    
    let color: NSColor
    
    var selected = false {
        didSet {
            needsDisplay = true
        }
    }

    // MARK: - private vars
    
    private weak var colorGridView: ColorGridView?

    // MARK: - init & overrided functions
    
    init(color: NSColor, in colorGridView: ColorGridView) {
        self.color = color
        self.colorGridView = colorGridView
        super.init(frame: NSZeroRect) // NSRect(origin: NSPoint(x: 0, y: 0), size: NSSize(width: 50, height: 30)))
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if color == .clear {
            NSColor.white.setFill()
        } else {
            color.setFill()
        }
        
        context.fill(dirtyRect)
        
        if color == .clear {
            NSColor.red.setStroke()
            context.beginPath()
            context.move(to: dirtyRect.origin)
            context.addLine(to: CGPoint(x: dirtyRect.width, y: dirtyRect.height))
            context.strokePath()
        }
        
        if selected {
            NSColor.white.setStroke()
        } else {
            NSColor.gray.withAlphaComponent(0.5).setStroke()
        }

        context.stroke(dirtyRect, width: selected ? 2.0 : 1.0)
    }
    
    override func mouseDown(with event: NSEvent) {
        selected = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        selected = bounds.contains(point)
    }

    override func mouseUp(with event: NSEvent) {
        if selected {
            colorGridView?.colorSelected(color)
        }
    }

}

// MARK: - Protocols & Extensions

/**
 handy protocol for classes that have a color var
*/
@objc protocol ColorProvider {
    var color: NSColor { get set }
}

/**
 Add ColorProvider conformance to NSPanel
 */
extension NSColorPanel: ColorProvider {}

/**
 Add equatable conformance to MouseState enum
 */
extension ComboColorWellCell.MouseState: Equatable {
    static func == (lhs: ComboColorWellCell.MouseState, rhs: ComboColorWellCell.MouseState) -> Bool {
        switch lhs {
        case .outside:
            switch rhs {
            case .outside:
                return true
            default:
                return false
            }
        case let .over(leftArea):
            switch rhs {
            case let .over(rightArea):
                return leftArea == rightArea
            default:
                return false
            }
        case let .down(leftArea):
            switch rhs {
            case let .down(rightArea):
                return leftArea == rightArea
            default:
                return false
            }
        case let .up(leftArea):
            switch rhs {
            case let .up(rightArea):
                return leftArea == rightArea
            default:
                return false
            }
        }
    }
}

extension NSLayoutConstraint {
    public convenience init(equalAttribute: NSLayoutConstraint.Attribute,
                            for items: (NSView, NSView?),
                            multiplier: CGFloat = 1.0,
                            constant: CGFloat = 0.0) {
        
        self.init(item: items.0,
                  attribute: equalAttribute,
                  relatedBy: .equal,
                  toItem: items.1,
                  attribute: (items.1 != nil) ?
                    equalAttribute :
                    .notAnAttribute,
                  multiplier: multiplier,
                  constant: constant)
    }
}

extension NSColor {
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(calibratedRed: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: alpha)
    }
}

class myTextView: NSTextView {
//    override func changeColor(_ sender: Any?) {
//        if let colorPanel = sender as? NSColorPanel,
//            let _ = colorPanel.delegate as? ComboColorWellCell {
//            return
//        }
//        super.changeColor(sender)
//    }
}
