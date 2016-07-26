//
//  NCursesGraphicsContext.swift
//  Nancy
//
//  Created by James Campbell on 7/25/16.
//  Copyright © 2016 Nancy. All rights reserved.
//

import Foundation

enum NCursesColor: Int32, Equatable {
    
    case Black
    case Red
    case Green
    case Yellow
    case Blue
    case Magenta
    case Cyan
    case White
    
    static func registerColorPairs() {
        colorPairs.enumerate().forEach { index, pair in
            init_pair(Int16(index), Int16(pair.1.ncursesValue), Int16(pair.0.ncursesValue))
        }
    }
    
    private static func ncursesPairForPair(pair: (backgroundColor: NCursesColor, foregroundColor: NCursesColor)) -> UInt32? {
        
        guard let colorPairID = pairIDForPair(pair) else {
            return nil
        }
        
        let colorPair = COLOR_PAIR(Int32(colorPairID))
        return UInt32(colorPair)
    }
    
    private static func pairIDForPair(pair: (backgroundColor: NCursesColor, foregroundColor: NCursesColor)) -> Int32? {
        
        guard let index = colorPairs.indexOf({ $0 == pair }) else {
            return nil
        }
        
        return Int32(index)
    }
    
    private var ncursesValue: Int32 {
        switch self {
        case .Black:
            return COLOR_BLACK
        case .Red:
            return COLOR_RED
        case .Green:
            return COLOR_GREEN
        case .Yellow:
            return COLOR_YELLOW
        case .Blue:
            return COLOR_BLUE
        case .Magenta:
            return COLOR_MAGENTA
        case .Cyan:
            return COLOR_CYAN
        case .White:
            return COLOR_WHITE
        }
    }
    
    private static var colorPairs: [(NCursesColor, NCursesColor)] = {
        
        let colors: [NCursesColor] = [
            .Black,
            .Red,
            .Green,
            .Yellow,
            .Blue,
            .Magenta,
            .Cyan,
            .White
        ]
        
        return colors.map {
            colorA in
            
            return colors.map {
                colorB in
                return (colorA, colorB)
            }
        }
        .reduce([], combine: +)
    }()
}
    
func == (lhs: NCursesColor, rhs: NCursesColor) -> Bool {
    return lhs.ncursesValue == rhs.ncursesValue
}

class NCursesGraphicsContext: NSObject {
    
    let borderCharacterCode: UInt32 = 42
    
    private var ncursesWindow: COpaquePointer
    
    var frame: NRect {
        didSet {
            wresize(ncursesWindow, frame.size.height, frame.size.width)
            mvwin(ncursesWindow,  frame.origin.y, frame.origin.x)
        }
    }
    
    init(frame: NRect) {
        ncursesWindow = newwin(frame.size.height, frame.size.width, frame.origin.x, frame.origin.y)
        leaveok(ncursesWindow, true)
        
       self.frame = frame
    }
    
    var foregroundColor: NCursesColor = .White
    var backgroundColor: NCursesColor = .Black
    var hasBorder: Bool = false
    
    func drawText(origin: NPoint, text: String) {
        mvwaddstr(ncursesWindow, origin.y, origin.x, text)
    }

    func clear() {
        wclear(ncursesWindow)
    }
    
    func flush() {
        applyPropertiesToWindow(ncursesWindow)
        wrefresh(ncursesWindow)
    }
    
    func drawToContext(context: NCursesGraphicsContext) {
        
        guard NRectIntersectsRect(frame, rectB:context.frame) else {
            return
        }
        
        let displayRect = NRectIntersection(frame, rectB:context.frame)
        
        let compositeWindow = newwin(displayRect.size.height, displayRect.size.width, displayRect.origin.y, displayRect.origin.x)
        
        let isClipping = !NRectContainsRect(context.frame, rectB:frame)
        
        if isClipping {
            copywin(ncursesWindow, compositeWindow, 0, 0, 0, 0, displayRect.size.height, displayRect.size.width, 1)
        } else {
            overlay(ncursesWindow, compositeWindow)
        }
        
        applyPropertiesToWindow(compositeWindow)

        wrefresh(compositeWindow)
        delwin(compositeWindow)
    }
    
    private func applyPropertiesToWindow(window: COpaquePointer) {
        
        if let colorPair = NCursesColor.ncursesPairForPair((backgroundColor: backgroundColor, foregroundColor: foregroundColor)) {
            wbkgd(window, colorPair)
        }
        
        if hasBorder {
            box(window, borderCharacterCode, borderCharacterCode)
        }
    }
}