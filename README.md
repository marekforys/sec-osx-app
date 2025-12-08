# sec-osx-app

A macOS application focused on monitoring and displaying security aspects of your macOS system.

## Features

This app provides a comprehensive security dashboard that monitors:

- **Firewall Status** - Network firewall protection status
- **Gatekeeper Status** - Application security verification status
- **FileVault Status** - Disk encryption status
- **System Integrity Protection (SIP)** - SIP status monitoring
- **System Updates** - Software update availability

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.9 or later

## Building the App

### Using Xcode

1. Open the project in Xcode:
   ```bash
   open sec-osx-app.xcodeproj
   ```

2. Select your development team in the Signing & Capabilities section

3. Build and run (⌘R)

### Using Swift Package Manager

```bash
swift build
swift run
```

## Project Structure

```
sec-osx-app/
├── sec-osx-app/
│   ├── sec_osx_appApp.swift    # Main app entry point
│   ├── ContentView.swift        # Main UI views
│   ├── SecurityManager.swift    # Security status checking logic
│   └── Info.plist              # App configuration
├── Package.swift                # Swift Package Manager configuration
└── README.md                    # This file
```

## Security Features Monitored

### Firewall
Monitors the macOS Application Firewall status using `socketfilterfw`.

### Gatekeeper
Checks Gatekeeper status using `spctl` to verify if app security verification is enabled.

### FileVault
Monitors FileVault disk encryption status using `fdesetup`.

### System Integrity Protection (SIP)
Checks SIP status using `csrutil`. Note: SIP status can only be checked when booted from Recovery Mode, so this may show as unknown in normal operation.

### System Updates
Checks for available software updates using `softwareupdate`.

## Permissions

Some security checks may require administrator privileges. The app will attempt to check status without requiring elevated permissions where possible.

## License

See LICENSE file for details.
