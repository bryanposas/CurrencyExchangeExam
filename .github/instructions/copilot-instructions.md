# GitHub Copilot Instructions

## Project Overview

- **Platform**: iOS  
- **Minimum Deployment Target**: iOS XX.X    
- **Language**: Swift 5.x  
- **UI Framework**: UIKit (no SwiftUI)  
- **Lifecycle**: UIKit App Delegate (`AppDelegate` \+ `SceneDelegate`)  
- **Architecture**: MVC  

## Project Structure

ProjectName/

├── README.md

├── AppDelegate.swift

├── SceneDelegate.swift

├── Controllers/        \# UIViewControllers

├── Views/              \# Custom UIView subclasses, XIBs

├── Models/             \# Data models and entities

├── Services/           \# Networking, persistence, business logic

├── Extensions/         \# Swift extensions

├── Resources/          \# Assets, fonts, plists

└── Supporting Files/   \# Info.plist, etc.

## Functional Requirements

### General

- The goal of this task is to develop an iOS application that allows users to exchange currencies using real-time exchange rates.  
- The project should demonstrate your ability to create a clear, maintainable, and well-structured solution focusing on functionality, code quality, and user experience.

### Objective / Task Description

- Create a simple one-page iOS application **Currency Exchanger** that allows users to exchange currencies in real time  
- The application should display the user’s multi-currency account with an initial balance of 1000 EUR  
- Users must be able to enter the amount they wish to convert, select the currency to sell, and select the currency to buy  
- After confirming the operation, the balances should update accordingly, ensuring that no balance becomes negative.  
- Please refer to the provided design in Figma for layout and user flow guidance: [Currency Exchange Task – Figma Design](https://www.figma.com/design/jDNrXiO2mNdk8QwAVTzyml/Currency-exchange-task?node-id=0-1&t=crqZJ2YaoIwFuMXz-1)  
  - The design is for reference only — an exact visual match is not required, but the core functionality and flow should remain consistent.  
- Currency exchange rates must be retrieved from the provided public API and refreshed automatically at regular intervals  
- The interface should clearly show the user’s balances and provide an intuitive and responsive experience.

## Technical Requirements

### General

- Must be implemented purely in Swift  
- The development environment is Test Driven Development which means that business logics and functions must have corresponding unit tests to ensure reliability and stability  
- The code must be readable, scalable, maintainable, and extendable. Must include comments to document how it became scalable and maintainable  
- The system should be **maintainable and extendable**:  
1. clear relationship between parts of the code  
2. code is simple, readable, and easy to understand  
3. new functionality can be added without rewriting existing components  
4. adding new currencies should be straightforward  
- Should follow best practices and ensure separation of concerns with regard to MVVM as the   
- Must adhere to MVVM but without the help of third party libraries offering reactive programming functionalities and it must follow the best practices and ensure separation of concerns  
- 

## API & Data Handling

- The API to be used is [https://api.currencyfreaks.com/v2.0/rates/latest?apikey={API\_KEY](https://api.currencyfreaks.com/v2.0/rates/latest?apikey={API_KEY)}  
  - WHERE {API\_KEY} is ae277159399e4d0eadfb4903b20ca5aa

## Coding Conventions

### General

- Use Swift idioms: optionals, guard, result types  
- Prefer `final class` for view controllers unless subclassing is intended  
- Use `private` and `private(set)` to limit scope  
- Avoid force-unwraps (`!`); use `guard let` or `if let`  
- Use `// MARK: -` to organize code sections  
- Must follow the current best practices such as but not limited to, the SOLID principle, linting, and etc

### README

- Must provide clear instructions for setting up and running the project

### UI

- The **UI** should be user-friendly, responsive, and clearly indicate background operations such as data loading  
- The UI must be intuitive, responsive, and has visually clear implementation  
- The **layout** should be responsive and work across all device sizes, including iPads, using Auto Layout.

### UIViewController

- Set up UI in `viewDidLoad`  
- Do not hardcode strings — use constants or localizable strings  
- Prefer programmatic layout or Storyboards consistently (pick one per project)  
- Use `weak` references in delegates and closures to avoid retain cycles

### Networking

- Use `URLSession` for HTTP requests  
- Decode JSON using `Codable`  
- Handle errors explicitly; never silently swallow them

### Error Handling

- Provide proper **error handling** for network or data issues, ensuring stable app behavior in all cases.

### Naming

- ViewControllers: `HomeViewController`, `ProfileViewController`  
- Views: `UserCardView`, `LoadingView`  
- Delegates: `UserServiceDelegate`, `CartManagerDelegate`  
- Constants: use `enum` namespaces, e.g. `Constants.API.baseURL`

### Threading

- Always update UI on the main thread: `DispatchQueue.main.async { }`  
- Use `async/await` (Swift concurrency) for new async code where iOS version supports it

## Dependencies

- None yet  

## What to Avoid

- Do not use SwiftUI — this project is UIKit only  
- Do not use storyboard or xib files, the UI implementation must be purely programmatic which includes the auto-layout and the navigations  
- Do not introduce new third-party packages without noting them here  
- Avoid singleton abuse — prefer dependency injection

## Testing

- Unit test files go in `ProjectNameTests/`  
- UI test files go in `ProjectNameUITests/`  
- Use `XCTest`

