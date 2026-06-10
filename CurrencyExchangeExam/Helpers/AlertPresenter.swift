//
//  AlertPresenter.swift
//  CurrencyExchangeExam
//
//  Created by Macintosh HD on 6/10/26.
//

import UIKit

protocol AlertPresenting {
    func showAlert(on presenter: UIViewController, title: String, message: String)
    func showExchangeConfirmation(
        on presenter: UIViewController,
        sellAmount: Double,
        sellCurrency: String,
        receiveText: String,
        commission: Double,
        onConfirm: @escaping () -> Void
    )
}

struct AlertPresenter: AlertPresenting {

    func showAlert(on presenter: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        presenter.present(alert, animated: true)
    }

    func showExchangeConfirmation(
        on presenter: UIViewController,
        sellAmount: Double,
        sellCurrency: String,
        receiveText: String,
        commission: Double,
        onConfirm: @escaping () -> Void
    ) {
        let message = String(
            format: "Sell: %.2f %@\nReceive: %@\nCommission fee: %.2f %@\n\nDo you want to proceed?",
            sellAmount, sellCurrency,
            receiveText,
            commission, sellCurrency
        )

        let alert = UIAlertController(title: "Confirm Exchange", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in onConfirm() })
        presenter.present(alert, animated: true)
    }
}
