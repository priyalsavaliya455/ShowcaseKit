//
//  File.swift
//  ShowcaseKit
//
//  Created by priyal on 28/05/26.
//

import Foundation
import UIKit

public class ShowcaseOverlayView: UIView, ShowcaseControllerDelegate {

    // MARK: - Public
    private var lastIndex: Int = 0
    public weak var controller: ShowcaseController? {
        didSet { controller?.delegate = self }
    }

    // MARK: - Subviews

    private let cutoutLayer  = CutoutLayer()
    private let tooltipView  = TooltipCardView()
    private let tapOutsideView = UIView()

    // MARK: - Init

    public init(controller: ShowcaseController) {
        super.init(frame: UIScreen.main.bounds)
        self.controller = controller
        controller.delegate = self
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupViews() {
        isUserInteractionEnabled = true
        backgroundColor = .clear

        tapOutsideView.backgroundColor = .clear
        tapOutsideView.frame = bounds
        tapOutsideView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let tap = UITapGestureRecognizer(target: self, action: #selector(tappedOutside))
        tapOutsideView.addGestureRecognizer(tap)
        addSubview(tapOutsideView)

        cutoutLayer.frame = bounds
        layer.addSublayer(cutoutLayer)

        tooltipView.alpha = 0
        addSubview(tooltipView)
    }

    @objc private func tappedOutside() {
        // Intentionally do nothing — navigation is button-only.
        // Optional: pulse the tooltip so the user knows to use the buttons.
        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values   = [1.0, 1.04, 0.97, 1.0]
        pulse.keyTimes = [0, 0.3, 0.7, 1.0]
        pulse.duration = 0.35
        tooltipView.layer.add(pulse, forKey: "pulse")
    }

    // MARK: - ShowcaseControllerDelegate

    public func showcaseController(_ controller: ShowcaseController,
                                   didMoveTo index: Int,
                                   item: ShowcaseItem) {
        isHidden = false

        let isForward  = index >= lastIndex
        lastIndex      = index
        let slideOut: CGFloat = isForward ? -30 : 30   // exit direction
        let slideIn:  CGFloat = isForward ?  30 : -30  // enter direction

        // --- Animate OLD tooltip out ---
        UIView.animate(withDuration: 0.18, delay: 0,
                       options: .curveEaseIn) {
            self.tooltipView.alpha = 0
            self.tooltipView.transform = CGAffineTransform(translationX: slideOut, y: 0)
        } completion: { _ in

            // --- Reset and configure NEW content ---
            self.tooltipView.transform = CGAffineTransform(translationX: slideIn, y: 0)
            self.tooltipView.alpha = 0

            self.cutoutLayer.update(frame: item.frame, shape: item.shape, padding: 8)
            self.tooltipView.configure(item: item, controller: controller)
            self.layoutTooltip(item: item)

            // --- Animate NEW tooltip in ---
            UIView.animate(withDuration: 0.32, delay: 0,
                           usingSpringWithDamping: 0.75,
                           initialSpringVelocity: 0.2) {
                self.tooltipView.alpha = 1
                self.tooltipView.transform = .identity
            }
        }
    }

    public func showcaseControllerDidDismiss(_ controller: ShowcaseController) {
        UIView.animate(withDuration: 0.22) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.alpha    = 1
            self.removeFromSuperview()
        }
    }

    // MARK: - Tooltip positioning

    private func layoutTooltip(item: ShowcaseItem) {
        let screen   = UIScreen.main.bounds
        let sidePad: CGFloat = 16
        let arrowH:  CGFloat = 10
        let cutPad:  CGFloat = 8
        let gap:     CGFloat = 6
        let tooltipW = screen.width - sidePad * 2

        // Give the tooltip its width so intrinsicCardHeight() can measure correctly
        tooltipView.bounds.size.width = tooltipW

        let spaceAbove = item.frame.minY - cutPad - gap
        let spaceBelow = screen.height - (item.frame.maxY + cutPad + gap)
        let showAbove  = spaceAbove >= spaceBelow && spaceAbove > 100

        // FIX: call setArrow BEFORE measuring height, so the arrow flag is correct
        // when layoutSubviews runs during intrinsicCardHeight().
        tooltipView.setArrow(showAbove: showAbove,
                             targetMidX: item.frame.midX,
                             tooltipWidth: tooltipW)

        // Now measure after arrow state is set — single layout pass, correct result
        let cardH  = tooltipView.intrinsicCardHeight()
        let totalH = arrowH + cardH

        let midX: CGFloat = {
            let ideal = item.frame.midX
            let half  = tooltipW / 2
            return min(max(ideal, half + sidePad), screen.width - half - sidePad)
        }()

        let midY: CGFloat = showAbove
            ? item.frame.minY - cutPad - gap - totalH / 2
            : item.frame.maxY + cutPad + gap + totalH / 2

        tooltipView.bounds.size = CGSize(width: tooltipW, height: totalH)
        tooltipView.center      = CGPoint(x: midX, y: midY)

        // Single explicit layout pass — no double-render
        tooltipView.setNeedsLayout()
        tooltipView.layoutIfNeeded()
    }

    // MARK: - Present helpers

    /// Present using an explicit item array (title/description/shape defined inline).
    public static func present(
        controller: ShowcaseController,
        items: [ShowcaseItem],
        completion: (() -> Void)? = nil
    ) {
        attach(controller: controller)
        controller.startShowcase(items: items, completion: completion)
    }

    /// Present using IDs only — title, description, and shape come from registerShowcase().
    /// Use this when all views have already called registerShowcase(). No repeated data.
    public static func present(
        controller: ShowcaseController,
        orderedIDs: [String],
        completion: (() -> Void)? = nil
    ) {
        attach(controller: controller)
        controller.startShowcase(orderedIDs: orderedIDs, completion: completion)
    }

    /// Attaches the overlay to the key window. Shared by both present() overloads.
    @discardableResult
    private static func attach(controller: ShowcaseController) -> ShowcaseOverlayView? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return nil }

        let overlay = ShowcaseOverlayView(controller: controller)
        overlay.frame = window.bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(overlay)
        return overlay
    }
}

// MARK: - CutoutLayer

private class CutoutLayer: CALayer {

    private let maskLayer = CAShapeLayer()

    override init() {
        super.init()
        backgroundColor = UIColor.black.withAlphaComponent(0.72).cgColor
        mask = maskLayer
        maskLayer.fillRule = .evenOdd
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(frame highlightFrame: CGRect, shape: ShowcaseShape, padding: CGFloat) {
        let screenPath = UIBezierPath(rect: UIScreen.main.bounds)
        let cutRect    = highlightFrame.insetBy(dx: -padding, dy: -padding)

        let cutPath: UIBezierPath
        if shape.isCircle {
            let size = max(cutRect.width, cutRect.height)
            let circleRect = CGRect(
                x: cutRect.midX - size / 2,
                y: cutRect.midY - size / 2,
                width: size, height: size
            )
            cutPath = UIBezierPath(ovalIn: circleRect)
        } else {
            cutPath = UIBezierPath(roundedRect: cutRect, cornerRadius: shape.cornerRadius)
        }

        screenPath.append(cutPath)

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.35)
        maskLayer.path = screenPath.cgPath
        CATransaction.commit()
    }
}

// MARK: - TooltipCardView

private class TooltipCardView: UIView {

    private let arrowView    = TriangleView()
    private let cardView     = UIView()
    private let dotsStack    = UIStackView()
    private let counterLabel = UILabel()
    private let titleLabel   = UILabel()
    private let descLabel    = UILabel()
    private let backButton   = UIButton(type: .system)
    private let skipButton   = UIButton(type: .system)
    private let nextButton   = UIButton(type: .system)

    private weak var controller: ShowcaseController?

    private var showArrowAbove = false
    private var arrowOffset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build UI

    private func buildUI() {
        isUserInteractionEnabled = true

        addSubview(arrowView)

        cardView.layer.cornerRadius  = 16
        cardView.clipsToBounds       = false
        cardView.layer.shadowColor   = UIColor.black.withAlphaComponent(0.45).cgColor
        cardView.layer.shadowRadius  = 20
        cardView.layer.shadowOpacity = 1
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 6)
        addSubview(cardView)

        let pad = ShowcaseTooltipStyle.default.padding

        dotsStack.axis      = .horizontal
        dotsStack.spacing   = 5
        dotsStack.alignment = .center

        counterLabel.font      = UIFont.preferredFont(forTextStyle: .caption2)
        counterLabel.textColor = UIColor.white.withAlphaComponent(0.45)

        let dotsRow = UIStackView(arrangedSubviews: [dotsStack, UIView(), counterLabel])
        dotsRow.axis      = .horizontal
        dotsRow.spacing   = 4
        dotsRow.alignment = .center

        titleLabel.font          = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor     = .white
        titleLabel.numberOfLines = 0

        descLabel.font          = UIFont.preferredFont(forTextStyle: .subheadline)
        descLabel.textColor     = UIColor.white.withAlphaComponent(0.8)
        descLabel.numberOfLines = 0

        styleBackButton()
        styleSkipButton()
        styleNextButton()

        let buttonRow = UIStackView(arrangedSubviews: [backButton, UIView(), skipButton, nextButton])
        buttonRow.axis      = .horizontal
        buttonRow.spacing   = 8
        buttonRow.alignment = .center

        let contentStack = UIStackView(arrangedSubviews: [dotsRow, titleLabel, descLabel, buttonRow])
        contentStack.axis    = .vertical
        contentStack.spacing = 8
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: pad.top),
            contentStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: pad.left),
            contentStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -pad.right),
            contentStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -pad.bottom),
        ])
    }

    private func styleBackButton() {
        backButton.setTitle("← Back", for: .normal)
        backButton.titleLabel?.font   = UIFont.systemFont(ofSize: 13, weight: .medium)
        backButton.setTitleColor(UIColor.white.withAlphaComponent(0.75), for: .normal)
        backButton.backgroundColor    = UIColor.white.withAlphaComponent(0.12)
        backButton.layer.cornerRadius = 14
        backButton.contentEdgeInsets  = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    private func styleSkipButton() {
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font  = UIFont.systemFont(ofSize: 13)
        skipButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
        skipButton.backgroundColor   = .clear
        skipButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    private func styleNextButton() {
        nextButton.titleLabel?.font   = UIFont.systemFont(ofSize: 13, weight: .semibold)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.backgroundColor    = ShowcaseTooltipStyle.default.buttonColor
        nextButton.layer.cornerRadius = 16
        nextButton.contentEdgeInsets  = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }

    // MARK: - Configure (data only — no layout calls)

    func configure(item: ShowcaseItem, controller: ShowcaseController) {
        self.controller = controller

        cardView.backgroundColor    = item.tooltipStyle.backgroundColor
        cardView.layer.cornerRadius = item.tooltipStyle.cornerRadius
        titleLabel.font             = item.titleStyle.font
        titleLabel.textColor        = item.titleStyle.color
        titleLabel.text             = item.title
        descLabel.font              = item.tooltipStyle.descriptionFont
        descLabel.textColor         = item.tooltipStyle.descriptionColor
        descLabel.text              = item.description
        nextButton.backgroundColor  = item.tooltipStyle.buttonColor
        nextButton.setTitleColor(item.tooltipStyle.buttonTextColor, for: .normal)

        // Step dots
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for i in 0..<controller.totalSteps {
            let dot = UIView()
            dot.layer.cornerRadius = 3
            let isActive = i == controller.currentIndex
            dot.backgroundColor = isActive
                ? item.tooltipStyle.buttonColor
                : UIColor.white.withAlphaComponent(0.25)
            let w: CGFloat = isActive ? 18 : 6
            dot.widthAnchor.constraint(equalToConstant: w).isActive  = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
            dotsStack.addArrangedSubview(dot)
        }

        counterLabel.text   = "\(controller.currentIndex + 1)/\(controller.totalSteps)"
        backButton.isHidden = controller.isFirst

        let nextTitle = controller.isLast
            ? (item.actionButtonTitle ?? "Done ✓")
            : (item.actionButtonTitle ?? "Next →")
        nextButton.setTitle(nextTitle, for: .normal)

        // FIX: No setNeedsLayout() / layoutIfNeeded() here.
        // The caller (ShowcaseOverlayView.layoutTooltip) owns the layout cycle.
    }

    // MARK: - Arrow positioning

    func setArrow(showAbove: Bool, targetMidX: CGFloat, tooltipWidth: CGFloat) {
        showArrowAbove     = showAbove
        arrowView.pointsUp = !showAbove

        let halfW    = tooltipWidth / 2
        let sidePad: CGFloat = 16
        let clampedCenter = min(max(targetMidX, halfW + sidePad),
                                UIScreen.main.bounds.width - halfW - sidePad)
        arrowOffset = targetMidX - clampedCenter
    }

    // MARK: - Layout (called once, after configure + setArrow)

    override func layoutSubviews() {
        super.layoutSubviews()

        let arrowH: CGFloat = 10
        let cardH = cardView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        if showArrowAbove {
            cardView.frame  = CGRect(x: 0, y: 0, width: bounds.width, height: cardH)
            arrowView.frame = CGRect(x: bounds.width / 2 - 10 + arrowOffset,
                                     y: cardH,
                                     width: 20, height: arrowH)
        } else {
            arrowView.frame = CGRect(x: bounds.width / 2 - 10 + arrowOffset,
                                     y: 0,
                                     width: 20, height: arrowH)
            cardView.frame  = CGRect(x: 0, y: arrowH, width: bounds.width, height: cardH)
        }

        arrowView.color = cardView.backgroundColor ?? ShowcaseTooltipStyle.default.backgroundColor
    }

    func intrinsicCardHeight() -> CGFloat {
        let cardH = cardView.systemLayoutSizeFitting(
            CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return cardH + 10 // + arrowH
    }

    // MARK: - Actions

    @objc private func backTapped() { controller?.previous() }
    @objc private func skipTapped() { controller?.dismiss() }
    @objc private func nextTapped() { controller?.next() }
}

// MARK: - TriangleView

private class TriangleView: UIView {

    var pointsUp: Bool = true { didSet { setNeedsDisplay() } }
    var color: UIColor = ShowcaseTooltipStyle.default.backgroundColor { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        if pointsUp {
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
        path.close()
        color.setFill()
        path.fill()
    }
}
