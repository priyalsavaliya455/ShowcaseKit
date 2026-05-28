//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
import UIKit

public struct ShowcaseTooltipStyle {
    public let backgroundColor:  UIColor
    public let cornerRadius:     CGFloat
    public let padding:          UIEdgeInsets
    public let descriptionFont:  UIFont
    public let descriptionColor: UIColor
    public let buttonColor:      UIColor
    public let buttonTextColor:  UIColor

    public init(
        backgroundColor:  UIColor   = UIColor(red: 0.13, green: 0.13, blue: 0.18, alpha: 1),
        cornerRadius:     CGFloat   = 16,
        padding:          UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
        descriptionFont:  UIFont    = UIFont.preferredFont(forTextStyle: .subheadline),
        descriptionColor: UIColor   = UIColor.white.withAlphaComponent(0.8),
        buttonColor:      UIColor   = .systemIndigo,
        buttonTextColor:  UIColor   = .white
    ) {
        self.backgroundColor  = backgroundColor
        self.cornerRadius     = cornerRadius
        self.padding          = padding
        self.descriptionFont  = descriptionFont
        self.descriptionColor = descriptionColor
        self.buttonColor      = buttonColor
        self.buttonTextColor  = buttonTextColor
    }

    public static let `default` = ShowcaseTooltipStyle()
}
