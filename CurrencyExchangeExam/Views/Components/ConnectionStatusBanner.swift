//
//  ConnectionStatusBanner.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//
//  A banner that pushes content downward when shown — it does NOT overlay.
//
//  Setup (do this once in the VC's layout method):
//    1. Add the banner to the view hierarchy BEFORE the content view.
//    2. Constrain the banner's top/leading/trailing to the safe area / parent edges.
//    3. Pin the content view's topAnchor to banner.bottomAnchor.
//    The banner starts with height 0. When shown, it expands and content shifts down.
//
//  Usage:
//    banner.show(message: "…")         // shows after a 3-second delay (default)
//    banner.show(message: "…", delay: 0) // shows immediately
//    banner.hide()                      // collapses immediately, cancels pending show

import UIKit

// MARK: - ConnectionStatusBanner

final class ConnectionStatusBanner: UIView {

    // MARK: - UI

    private let iconView = UIImageView()
    private let messageLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    // MARK: - State

    private(set) var isExpanded = false
    private var heightConstraint: NSLayoutConstraint!
    private var pendingShow: DispatchWorkItem?

    static let expandedHeight: CGFloat = 52

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContent()
        // Height starts at 0; content is clipped so nothing is visible when collapsed.
        clipsToBounds = true
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    // MARK: - Public

    /// Schedules the banner to expand after `delay` seconds (default 3).
    /// Calling again before the delay fires replaces the pending request.
    /// Call with `delay: 0` to expand immediately.
    func show(message: String, delay: TimeInterval = 3.0) {
        messageLabel.text = message
        pendingShow?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.expand() }
        pendingShow = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    /// Cancels any pending show and immediately collapses the banner.
    func hide() {
        pendingShow?.cancel()
        pendingShow = nil
        collapse()
    }

    // MARK: - Private

    private func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        heightConstraint.constant = Self.expandedHeight
        UIView.animate(
            withDuration: 0.4,
            delay: 0,
            usingSpringWithDamping: 0.82,
            initialSpringVelocity: 0,
            options: .curveEaseOut
        ) {
            self.superview?.layoutIfNeeded()
        }
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false
        heightConstraint.constant = 0
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseIn) {
            self.superview?.layoutIfNeeded()
        }
    }

    @objc private func closeTapped() {
        hide()
    }

    // MARK: - Setup

    private func setupContent() {
        backgroundColor = UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        iconView.image = UIImage(systemName: "wifi.slash", withConfiguration: iconConfig)
        iconView.tintColor = .black
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        messageLabel.font = .systemFont(ofSize: 13, weight: .medium)
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 2

        let closeConfig = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        closeButton.accessibilityLabel = "Dismiss"

        let stack = UIStackView(arrangedSubviews: [iconView, messageLabel, closeButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }
}
