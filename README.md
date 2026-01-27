# Buffet Indicator Mobile

A Flutter mobile app for financial stock screening based on value investor criteria. Evaluate companies against the investment philosophies of Warren Buffett, Charlie Munger, Benjamin Graham, and other legendary investors.

## Features

- **Multi-Profile Analysis**: Evaluate stocks against 6 investor profiles (Buffett, Munger, Graham, Burry, Greenblatt, Lynch)
- **Key Metrics**: FCF Yield, Operating Margin, Net Margin, Leverage (Net Debt/EBITDA)
- **Letter Grading**: A-F grades based on how many criteria are met
- **Actionable Prescriptions**: Specific recommendations on what needs to improve
- **Analysis History**: Track and review past analyses
- **Dark Mode Support**: Automatic theme switching

## Prerequisites

Before running this app, you need to set up your development environment.

---

## Android Development Setup (Windows)

### Step 1: Install Android Studio

1. **Download Android Studio** from: https://developer.android.com/studio

2. **Run the installer** and follow the setup wizard:
   - Select "Standard" installation type
   - Accept all license agreements
   - Wait for components to download (this may take a while)

3. **First Launch Setup**:
   - Open Android Studio
   - Go to `More Actions` > `SDK Manager` (or `Tools` > `SDK Manager` if a project is open)
   - Under **SDK Platforms** tab, ensure **Android 14 (API 34)** is checked
   - Under **SDK Tools** tab, ensure these are checked:
     - Android SDK Build-Tools
     - Android SDK Command-line Tools
     - Android Emulator
     - Android SDK Platform-Tools
   - Click "Apply" to install

### Step 2: Install Flutter SDK

1. **Download Flutter SDK** from: https://docs.flutter.dev/get-started/install/windows

2. **Extract** to a location like `C:\flutter` (avoid paths with spaces)

3. **Add Flutter to PATH**:
   - Open Windows Search > "Edit environment variables"
   - Under "User variables", find `Path` and click "Edit"
   - Click "New" and add `C:\flutter\bin`
   - Click "OK" to save

4. **Verify installation** (open a NEW terminal):
   ```bash
   flutter --version
   flutter doctor
   ```

### Step 3: Configure Android Emulator

This is the key part for running/testing your app.

#### Option A: Using Android Studio (Recommended for beginners)

1. **Open Android Studio**

2. **Open Device Manager**:
   - Click `More Actions` > `Virtual Device Manager`
   - Or go to `Tools` > `Device Manager`

3. **Create a Virtual Device**:
   - Click `Create Device`
   - Select a phone (e.g., **Pixel 7** or **Pixel 8**)
   - Click "Next"

4. **Select System Image**:
   - Choose **Recommended** tab
   - Select **UpsideDownCake** (Android 14, API 34) or **Tiramisu** (Android 13, API 33)
   - If not downloaded, click the download icon next to it
   - Click "Next"

5. **Configure AVD**:
   - Name: `Pixel_7_API_34` (or similar)
   - **Graphics**: Select "Hardware - GLES 2.0" for best performance
   - Click "Show Advanced Settings":
     - RAM: 2048 MB (or more if you have RAM to spare)
     - VM heap: 512 MB
     - Internal Storage: 2048 MB
   - Click "Finish"

6. **Launch the Emulator**:
   - In Device Manager, click the **Play button** (triangle icon) next to your AVD
   - Wait for the emulator to boot (first boot takes longer)

#### Option B: Using Command Line

```bash
# List available system images
sdkmanager --list | findstr "system-images"

# Install a system image
sdkmanager "system-images;android-34;google_apis;x86_64"

# Create an AVD
avdmanager create avd -n Pixel7_API34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_7"

# List AVDs
emulator -list-avds

# Start emulator
emulator -avd Pixel7_API34
```

### Step 4: Enable Hardware Acceleration (Important for Performance)

Android Emulator needs hardware acceleration for acceptable performance.

#### Check if Virtualization is Enabled:

1. Open Task Manager (Ctrl+Shift+Esc)
2. Go to "Performance" tab
3. Look for "Virtualization: Enabled" at the bottom

#### If Virtualization is Disabled:

1. Restart your computer and enter BIOS/UEFI (usually F2, F12, Del, or Esc during boot)
2. Find "Intel VT-x" or "AMD-V" option and enable it
3. Save and exit BIOS

#### Install HAXM (Intel CPUs) or Hyper-V (AMD CPUs):

**For Intel CPUs:**
```bash
# In Android Studio SDK Manager > SDK Tools
# Check "Intel x86 Emulator Accelerator (HAXM installer)"
```

**For AMD CPUs or Windows Hyper-V:**
1. Open "Turn Windows features on or off"
2. Enable "Windows Hypervisor Platform"
3. Restart your computer

### Step 5: Run Flutter Doctor

Verify everything is configured:

```bash
flutter doctor -v
```

You should see checkmarks for:
- [✓] Flutter
- [✓] Android toolchain
- [✓] Android Studio

---

## Running the App

### Using Command Line

```bash
# Navigate to project directory
cd C:\Dev\buffet-indicator-mobile

# Get dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on emulator (must be running)
flutter run

# Run with hot reload enabled
flutter run --debug
```

### Using Android Studio

1. Open Android Studio
2. Click "Open" and select `C:\Dev\buffet-indicator-mobile`
3. Wait for Gradle sync to complete
4. Select your emulator from the device dropdown (top toolbar)
5. Click the green "Run" button (or press Shift+F10)

### Using VS Code

1. Install the "Flutter" extension
2. Open the project folder
3. Select a device from the bottom status bar
4. Press F5 to run with debugging

---

## Troubleshooting

### "No connected devices"

```bash
# Check if emulator is running
flutter devices

# If empty, start emulator first:
# Option 1: From Android Studio Device Manager
# Option 2: Command line
emulator -avd Pixel7_API34
```

### "Emulator is very slow"

- Enable hardware acceleration (see Step 4)
- Use x86_64 system image instead of arm64
- Increase RAM allocation in AVD settings
- Close other heavy applications

### "INSTALL_FAILED_INSUFFICIENT_STORAGE"

- Increase Internal Storage in AVD settings (to 4096 MB)
- Or wipe AVD data: Device Manager > Right-click AVD > Wipe Data

### "Gradle build failed"

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### "License not accepted"

```bash
flutter doctor --android-licenses
# Accept all licenses by typing 'y'
```

---

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   └── financial_data.dart    # Data models (inputs, metrics, profiles)
├── providers/
│   └── analysis_provider.dart # State management
├── screens/
│   ├── home_screen.dart       # Bottom navigation host
│   ├── analyze_screen.dart    # Main analysis input/output
│   ├── history_screen.dart    # Past analyses
│   └── settings_screen.dart   # Profile selection, thresholds
├── services/
│   └── analysis_service.dart  # Financial calculations
├── utils/
│   └── theme.dart             # App theming
└── widgets/
    ├── grade_card.dart        # Grade display widget
    ├── metric_card.dart       # Individual metric display
    └── prescription_card.dart # Recommendations display
```

---

## Running Tests

```bash
flutter test
```

---

## Building for Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output will be in `build/app/outputs/`.

---

## Related Projects

- [buffet-indicator](https://github.com/Siyan-Dimitrov/Buffet_indicator) - Original Python/Streamlit web application

## License

MIT License
