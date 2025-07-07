# Hookaba LED Bag Control

A Flutter application for controlling LED bags using Bluetooth Low Energy (BLE) technology. The app follows Clean Architecture principles and uses modern Flutter development practices.

## Features

- BLE device scanning and connection
- LED pattern control
- Clean Architecture implementation
- State management using Cubit
- Modern Material Design 3 UI

## Project Structure

```
lib/
├── core/                      # Core functionality and shared components
│   ├── error/                 # Error handling classes
│   ├── injection_container/   # Dependency injection setup
│   ├── routes/               # App routing configuration
│   ├── shared/               # Shared widgets and utilities
│   ├── usecases/            # Base use case classes
│   └── utils/               # Utility functions and BLE service
├── features/                 # Feature modules
│   ├── dashboard/           # Main dashboard screen
│   ├── onboarding/         # User onboarding flow
│   ├── program_list/       # LED program management
│   ├── quick_actions/      # Quick control actions
│   ├── settings/           # App settings
│   └── split_screen/       # Split screen functionality
└── main.dart               # Application entry point
```

## Dependencies

### Core
- **State Management**: 
  - flutter_bloc: ^8.1.4
  - equatable: ^2.0.5

- **Dependency Injection**: 
  - get_it: ^7.6.7
  - injectable: ^2.3.2

- **Routing**: 
  - go_router: ^13.2.0

- **BLE**: 
  - flutter_blue_plus: ^1.31.15
  - permission_handler: ^11.3.0

### Utils
- dartz: ^0.10.1
- freezed_annotation: ^2.4.1
- json_annotation: ^4.8.1
- logger: ^2.0.2+1

### UI
- google_fonts: ^6.1.0
- flutter_svg: ^2.0.10+1
- cached_network_image: ^3.3.1

### Development
- build_runner: ^2.4.8
- injectable_generator: ^2.4.1
- freezed: ^2.4.7
- json_serializable: ^6.7.1
- mockito: ^5.4.4

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Development Status

Currently in initial development phase with:
- Basic project structure set up
- BLE service implementation for device communication
- Onboarding screen implementation
- Clean Architecture foundation
- Dependency injection setup
- Routing configuration

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
