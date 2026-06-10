//
//  CircleIconView.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

final class CircleIconView: UIView {

    init(color: UIColor, arrowUp: Bool) {
        super.init(frame: .zero)
        backgroundColor = color
        layer.cornerRadius = 20
        clipsToBounds = true

        let symbolName = arrowUp ? "arrow.up" : "arrow.down"
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let imageView = UIImageView(image: UIImage(systemName: symbolName, withConfiguration: config))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }
}
