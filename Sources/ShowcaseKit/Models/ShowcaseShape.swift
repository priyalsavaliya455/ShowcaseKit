//
//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
public enum ShowcaseShape {
    case circle
    case rectangle(cornerRadius: CGFloat)

    public var isCircle: Bool {
        if case .circle = self { return true }
        return false
    }

    public var cornerRadius: CGFloat {
        if case .rectangle(let r) = self { return r }
        return 0
    }
}
