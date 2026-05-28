//
//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
import UIKit

// MARK: - ShowcaseTarget (helper attached to each registered UIView)
// Mirrors: struct ShowcaseTargetModifier: ViewModifier

private class ShowcaseTarget {
    weak var view: UIView?
    let item: ShowcaseItem
    weak var controller: ShowcaseController?

    init(view: UIView, item: ShowcaseItem, controller: ShowcaseController) {
        self.view       = view
        self.item       = item
        self.controller = controller
    }

    /// Convert the view's bounds to global (window) coordinates — mirrors geo.frame(in: .global)
    func currentGlobalFrame() -> CGRect {
        guard let view = view,
              let window = view.window else { return .zero }
        return view.convert(view.bounds, to: window)
    }

    /// Push the current frame into the controller — mirrors registerFrame + refreshHighlight
    func syncFrame() {
        let frame = currentGlobalFrame()
        guard frame != .zero else { return }
        controller?.registerFrame(id: item.id, frame: frame)
        controller?.refreshHighlight(for: item.id, frame: frame)
    }
}

// MARK: - Associated object key

private var showcaseTargetKey: UInt8 = 0

// MARK: - UIView extension
// Mirrors: View.showcase(...) modifier

public extension UIView {

    /// Register this view as a showcase target.
    /// Call after the view has been added to the hierarchy (viewDidLoad or later).
    func registerShowcase(
        id: String,
        title: String,
        description: String,
        shape: ShowcaseShape = .rectangle(cornerRadius: 12),
        tooltipPosition: TooltipPosition = .auto,
        titleStyle: ShowcaseTitleStyle = .default,
        tooltipStyle: ShowcaseTooltipStyle = .default,
        actionButtonTitle: String? = nil,
        onTargetTap: (() -> Void)? = nil,
        controller: ShowcaseController
    ) {
        let item = ShowcaseItem(
            id: id,
            frame: .zero,               // will be filled in syncFrame()
            title: title,
            description: description,
            shape: shape,
            tooltipPosition: tooltipPosition,
            titleStyle: titleStyle,
            tooltipStyle: tooltipStyle,
            actionButtonTitle: actionButtonTitle,
            onTargetTap: onTargetTap
        )

        let target = ShowcaseTarget(view: self, item: item, controller: controller)
        // Store strongly on the view so it lives as long as the view does
        objc_setAssociatedObject(self, &showcaseTargetKey, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        controller.registerItem(item)

        // Initial frame sync — safe to call immediately if view is already in hierarchy
        DispatchQueue.main.async { target.syncFrame() }

        // Re-sync on every layout pass — mirrors .onChange(of: geo.frame(in: .global))
        observeLayoutChanges(target: target)
    }

    // MARK: - Private: layout observation

    private func observeLayoutChanges(target: ShowcaseTarget) {
        // Use a no-op CADisplayLink-free approach:
        // Swizzle layoutSubviews is heavy; instead we add a zero-size
        // invisible subview whose layoutSubviews fires whenever the parent relays out.
        let observer = LayoutObserverView(target: target)
        observer.frame = .zero
        observer.isUserInteractionEnabled = false
        addSubview(observer)
    }
}

// MARK: - LayoutObserverView
// A transparent 0×0 subview whose layoutSubviews fires whenever the parent relays out.
// Mirrors: .onChange(of: geo.frame(in: .global)) in SwiftUI

private class LayoutObserverView: UIView {
    private let target: ShowcaseTarget

    init(target: ShowcaseTarget) {
        self.target = target
        super.init(frame: .zero)
        backgroundColor = .clear
        isHidden        = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        target.syncFrame()
    }
}
