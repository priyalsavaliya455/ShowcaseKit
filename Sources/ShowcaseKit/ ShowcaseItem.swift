//
//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
import UIKit

public struct ShowcaseItem {
    public let id:                String
    public var frame:             CGRect
    public let title:             String
    public let description:       String
    public let shape:             ShowcaseShape
    public let tooltipPosition:   TooltipPosition
    public let titleStyle:        ShowcaseTitleStyle
    public let tooltipStyle:      ShowcaseTooltipStyle
    public let actionButtonTitle: String?
    public let onTargetTap:       (() -> Void)?

    public init(
        id:                String,
        frame:             CGRect             = .zero,
        title:             String,
        description:       String,
        shape:             ShowcaseShape       = .rectangle(cornerRadius: 12),
        tooltipPosition:   TooltipPosition     = .auto,
        titleStyle:        ShowcaseTitleStyle  = .default,
        tooltipStyle:      ShowcaseTooltipStyle = .default,
        actionButtonTitle: String?             = nil,
        onTargetTap:       (() -> Void)?       = nil
    ) {
        self.id                = id
        self.frame             = frame
        self.title             = title
        self.description       = description
        self.shape             = shape
        self.tooltipPosition   = tooltipPosition
        self.titleStyle        = titleStyle
        self.tooltipStyle      = tooltipStyle
        self.actionButtonTitle = actionButtonTitle
        self.onTargetTap       = onTargetTap
    }
}

public enum TooltipPosition {
    case auto, above, below
}
