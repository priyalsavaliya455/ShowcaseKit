//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
import UIKit

public struct ShowcaseTitleStyle {
    public let font:  UIFont
    public let color: UIColor

    public init(font: UIFont, color: UIColor) {
        self.font  = font
        self.color = color
    }

    public static let `default` = ShowcaseTitleStyle(
        font:  UIFont.preferredFont(forTextStyle: .headline),
        color: .white
    )
}
