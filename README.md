# Currency Exchange iOS Application

A real-time currency exchange app built with UIKit, following MVVM architecture with strict separation of concerns and programmatic UI throughout.

## Project Overview

- **Platform**: iOS 14.0+
- **Language**: Swift 5.x
- **UI Framework**: UIKit — programmatic layout, no Storyboards or XIBs
- **Architecture**: MVVM — one ViewModel per ViewController, no shared state via delegates
- **Lifecycle**: UIKit App Delegate + Scene Delegate

---

## Features

### Core Functionality

- Multi-currency account starting with 1,000 USD
- Real-time exchange rates from the CurrencyFreaks API
- 1% commission fee per exchange, deducted from the sell balance
- Prevents negative balances and same-currency exchanges
- Auto-refreshes exchange rates every 5 minutes
- Full transaction history per currency

### UI/UX

- Scrollable balance cards on the root screen — each card is tappable
- Balance detail screen showing available balance, an exchange button, and per-currency transaction history grouped by date
- Exchange modal with a phone-style numpad, live receive-amount preview, and currency search
- Sell currency is locked to the balance you opened — only the receive currency is selectable
- Currency picker includes a live search bar for fast filtering

---

## Project Structure

```text
CurrencyExchangeExam/
├── Models/
│   ├── Currency.swift               # Account, Rate, ExchangeRates, ExchangeTransaction
│   └── AppError.swift               # Typed error enum with user-facing descriptions
├── Services/
│   ├── NetworkClient.swift          # NetworkClient protocol + URLSessionNetworkClient
│   ├── ExchangeRateService.swift    # Rate fetching — injects NetworkClient
│   └── CurrencyExchangeManager.swift# Account state, exchange logic, rate cache
├── ViewModels/
│   ├── CurrencyExchangeViewModel.swift # ExchangeViewModel — powers ExchangeViewController
│   ├── BalancesViewModel.swift      # Powers BalancesViewController; factory for child VMs
│   └── BalanceDetailViewModel.swift # Powers BalanceDetailViewController; factory for ExchangeViewModel
├── Views/
│   ├── BalancesViewController.swift       # Root screen: scrollable balance cards
│   ├── BalanceCardView.swift              # Individual tappable balance card
│   ├── BalanceDetailViewController.swift  # Detail: balance + exchange button + history
│   ├── ExchangeViewController.swift       # Exchange modal: numpad, currency picker, submit
│   └── CurrencyPickerViewController.swift # Currency selection sheet with search bar
├── Helpers/
│   └── AlertPresenter.swift         # Injectable alert presentation
├── Extensions/
│   └── UIViewController+Extensions.swift
└── Resources/
    └── Constants.swift              # API config, account defaults, UI constants
```

---

## Architecture

### MVVM — one ViewModel per ViewController

Each ViewController owns a single, dedicated ViewModel. There is no shared ViewModel passed across the navigation stack.

| ViewController | ViewModel | Delegate Protocol |
| --- | --- | --- |
| `BalancesViewController` | `BalancesViewModel` | `BalancesViewModelDelegate` |
| `BalanceDetailViewController` | `BalanceDetailViewModel` | none (pull-only reads) |
| `ExchangeViewController` | `ExchangeViewModel` | `ExchangeViewModelDelegate` |

`BalancesViewModel` exposes `makeDetailViewModel()` to create a `BalanceDetailViewModel` for navigation. `BalanceDetailViewModel` exposes `makeExchangeViewModel()` for the exchange modal. This keeps ViewControllers decoupled from the shared `CurrencyExchangeManager`.

### Network Layer

`NetworkClient` is a protocol that abstracts HTTP transport. `URLSessionNetworkClient` is the production implementation. `ExchangeRateService` accepts a `NetworkClient` in its initializer — swapping it out for a mock in tests requires no subclassing.

```text
NetworkClient (protocol)
    └── URLSessionNetworkClient     ← production
    └── MockNetworkClient           ← tests

ExchangeRateService(networkClient:)   ← injects NetworkClient
CurrencyExchangeManager(rateService:) ← injects ExchangeRateService
BalancesViewModel(manager:)           ← injects CurrencyExchangeManager
```

### Dependency Injection Chain (SceneDelegate)

```swift
let manager   = CurrencyExchangeManager()
let viewModel = BalancesViewModel(manager: manager)
let rootVC    = BalancesViewController(viewModel: viewModel)
```

Child ViewModels are created by their parent's factory methods using the same `manager` instance, ensuring all screens operate on the same account state without singletons.

---

## Navigation Flow

```text
BalancesViewController
  │ (tap balance card)
  ▼
BalanceDetailViewController
  │ (tap "Exchange Currency")
  ▼
ExchangeViewController  (pageSheet modal)
  │ (tap receive currency)
  ▼
CurrencyPickerViewController  (pageSheet, with search bar)
```

After a successful exchange the `onExchangeCompleted` callback fires before the modal animates away, refreshing the detail screen's balance and transaction list immediately.

---

## Installation & Setup

### Requirements

- Xcode 14.0 or later
- iOS 14.0+ simulator or device
- Swift 5.0+

### Steps

1. Open the project

   ```bash
   open CurrencyExchangeExam.xcodeproj
   ```

2. Configure Code Signing — select your team under Signing & Capabilities.

3. Build and Run — Cmd+R.

---

## Usage

### Viewing Balances

The root screen shows all currencies with a non-zero balance as tappable cards.

### Balance Detail

Tap a card to see the available balance for that currency, an "Exchange Currency" button, and a chronological transaction history for that currency only.

### Exchanging Currency

1. Tap "Exchange Currency" on a balance detail screen.
2. The sell currency is pre-set to the balance you opened and cannot be changed.
3. Use the numpad to enter an amount. The receive amount updates live.
4. Tap the receive currency button (with chevron) to change where funds go — search by name or code.
5. Tap "Exchange" to review the confirmation, then "Confirm" to execute.
6. Balance and history refresh automatically when the modal closes.

### Commission

1% of the sell amount is charged as a fee. The fee is shown in the confirmation alert.

---

## API Integration

- **Provider**: CurrencyFreaks
- **Endpoint**: `https://api.currencyfreaks.com/v2.0/rates/latest`
- **API Key**: Stored in `Constants.swift`
- **Caching**: Rates cached in memory; refreshed every 5 minutes or on first load

---

## Testing

### Running Tests

- Unit tests: Cmd+U (or Product → Test)
- UI tests: select the `CurrencyExchangeExamUITests` scheme

### Test Coverage

| Suite | What it tests |
| --- | --- |
| `AccountTests` | Balance read/write and `canExchange` guard |
| `ExchangeRatesTests` | Rate lookup and cross-currency conversion |
| `CurrencyExchangeManagerTests` | Exchange workflow, commission, balance updates, transaction history |
| `AlertPresenterTests` | Alert presentation helpers |
| `CurrencyExchangeExamUITests` | End-to-end: balance cards → detail → exchange modal → confirm/cancel |

The `CurrencyExchangeManagerTests` use a `MockExchangeRateService` subclass that overrides `fetchExchangeRates`, preventing real network calls during unit tests.

---

## Error Handling

All errors are surfaced to the user via alerts:

| Error | Cause |
| --- | --- |
| Invalid Amount | Zero or non-numeric input |
| Insufficient Funds | Sell amount + commission exceeds balance |
| Same Currency | Sell and receive currencies match |
| Invalid Exchange Rate | Rates not yet loaded or currency not in feed |
| Network Error | No connection or API unreachable |

---

## Code Conventions

- UIKit only — no SwiftUI
- Programmatic layout — no Storyboards or XIBs
- `final class` for all concrete types
- `// MARK: -` sections throughout
- No force-unwraps — `guard`/`if let` throughout
- `weak` references in all closures and delegates
- Private `enum Strings`, `Colors`, `Layout` in each file for compile-time constants
- No third-party dependencies
