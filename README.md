# Currency Exchange iOS Application

A feature-rich iOS application for real-time currency exchange built with UIKit using MVVM architecture.

## Project Overview

- **Platform**: iOS  
- **Minimum Deployment Target**: iOS 14.0+  
- **Language**: Swift 5.x  
- **UI Framework**: UIKit (programmatic, no Storyboards/XIBs)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Lifecycle**: UIKit App Delegate + Scene Delegate

## Features

### Core Functionality
- ✅ Multi-currency account with 1000 EUR initial balance
- ✅ Real-time exchange rates from CurrencyFreaks API
- ✅ Currency exchange with automatic balance updates
- ✅ Prevents negative balances
- ✅ Auto-refresh exchange rates every 5 minutes
- ✅ Transaction history tracking
- ✅ Beautiful, responsive UI with Auto Layout

### Technical Features
- ✅ MVVM architecture with proper separation of concerns
- ✅ No third-party reactive libraries (native Swift)
- ✅ Dependency injection pattern
- ✅ Comprehensive error handling
- ✅ Unit tests with TDD approach
- ✅ URLSession for networking
- ✅ Codable for JSON decoding
- ✅ Main thread UI updates with DispatchQueue

## Project Structure

```
CurrencyExchangeExam/
├── Models/
│   ├── Currency.swift           # Data models
│   └── AppError.swift           # Error types
├── Services/
│   ├── ExchangeRateService.swift     # Network API calls
│   └── CurrencyExchangeManager.swift # Business logic
├── ViewModels/
│   └── CurrencyExchangeViewModel.swift # MVVM ViewModel
├── Views/
│   ├── BalanceCardView.swift         # Custom balance card
│   └── CurrencyPickerViewController.swift # Currency selector
├── Controllers/
│   └── CurrencyExchangeViewController.swift # Main view controller
├── Extensions/
│   └── UIViewController+Extensions.swift # Utilities
└── Resources/
    └── Constants.swift                 # App constants
```

## Installation & Setup

### Requirements
- Xcode 14.0 or later
- iOS 14.0 or later
- Swift 5.0+

### Steps

1. **Clone the repository**
   ```bash
   cd /path/to/CurrencyExchangeExam
   ```

2. **Open the project**
   ```bash
   open CurrencyExchangeExam.xcodeproj
   ```

3. **Configure Code Signing**
   - Select the project in Xcode
   - Select the target
   - Go to Signing & Capabilities
   - Select your development team

4. **Build and Run**
   - Select an iOS simulator or device
   - Press Cmd+R or select Product -> Run

## Usage

### Exchange Currency
1. Enter the amount you want to exchange
2. Select "From" currency (default: EUR)
3. Select "To" currency (default: USD)
4. The exchange rate and result will be displayed automatically
5. Tap "Exchange" to complete the transaction
6. Balances update immediately

### View Balances
- Current balances are displayed at the top
- Updated in real-time after each exchange

### Transaction History
- All completed exchanges are listed
- Shows amount, currencies, and exchange rate used
- Latest transactions appear first

### Refresh Rates
- Tap the "Refresh" button to manually fetch latest rates
- Rates auto-refresh every 5 minutes

## Architecture

### MVVM Pattern
- **Model**: `Currency.swift`, `AppError.swift` - data and error types
- **View**: `BalanceCardView.swift`, `CurrencyPickerViewController.swift` - UI components
- **ViewModel**: `CurrencyExchangeViewModel.swift` - business logic coordination
- **Controller**: `CurrencyExchangeViewController.swift` - UI presentation

### Services
- **ExchangeRateService**: Handles API calls with URLSession
- **CurrencyExchangeManager**: Manages accounts, exchanges, and rates

### Dependency Injection
- View models receive services in initializers
- Promotes testability and loose coupling

## API Integration

### CurrencyFreaks API
- **Endpoint**: `https://api.currencyfreaks.com/v2.0/rates/latest`
- **API Key**: Configured in Constants.swift
- **Cache**: Rates cached locally and refreshed every 5 minutes
- **Error Handling**: Network, decoding, and validation errors handled

## Testing

### Running Tests
1. Select Product > Scheme > CurrencyExchangeExamTests
2. Press Cmd+U or Product > Test

### Test Coverage
- **AccountTests**: Balance operations and exchange validation
- **ExchangeRatesTests**: Rate calculations and conversions
- **CurrencyExchangeManagerTests**: Full exchange workflow

### Test Types
- Unit tests for models and business logic
- Mock services for network testing
- Validation tests for error cases

## Error Handling

The app handles multiple error scenarios:
- Network failures with retry guidance
- Invalid exchange rates
- Insufficient funds
- Invalid amounts
- Same currency selection
- API key issues

Each error provides a user-friendly message and recovery suggestion.

## Code Quality

### Best Practices Implemented
- ✅ SOLID principles adhered to
- ✅ Separation of concerns maintained
- ✅ No force unwraps (uses guard/if-let)
- ✅ Private fields with appropriate access control
- ✅ Comprehensive comments explaining complexity
- ✅ Code is readable and maintainable
- ✅ Extensions organized with MARK comments

### Performance
- Efficient rate caching
- Main thread UI updates
- Background rate fetching
- Memory-efficient balance tracking

## Future Enhancements

Potential improvements for production:
- Persistent storage (CoreData/UserDefaults)
- Offline mode with cached rates
- Multiple account support
- Transaction export/sharing
- Rate chart visualization
- Favorites/preferred currencies
- Dark mode support
- Localization (multiple languages)

## Troubleshooting

### App Crashes on Launch
- Ensure Code Signing is configured
- Check iOS deployment target matches device

### Exchange Rates Not Loading
- Verify internet connection
- Check API key in Constants.swift
- Review CurrencyFreaks API status

### Tests Failing
- Clean build folder (Cmd+Shift+K)
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- Rebuild and re-run tests

## License

This project is provided as-is for educational purposes.

## Contact

For questions or issues, please refer to the project documentation or contact the development team.
