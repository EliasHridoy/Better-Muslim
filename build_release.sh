#!/bin/bash
# Better Muslim - Production Build Script
# Run from: /home/lord-elias/flutter_workspace/better_muslim

set -e

echo "🔥 Better Muslim Production Build"
echo "================================="

# 1. Clean previous builds
echo "🧹 Cleaning..."
flutter clean

# 2. Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# 3. Run code generation (for Hive)
echo "⚙️  Running code generation..."
dart run build_runner build --delete-conflicting-outputs

# 4. Build Android APK (for direct distribution)
echo "📱 Building Android APK..."
flutter build apk --release
echo "✅ APK: build/app/outputs/flutter-apk/app-release.apk"

# 5. Build Android App Bundle (for Play Store)
echo "📦 Building Android App Bundle..."
flutter build appbundle --release
echo "✅ AAB: build/app/outputs/bundle/release/app-release.aab"

echo ""
echo "🎉 Build complete!"
echo "APK size: $(du -sh build/app/outputs/flutter-apk/app-release.apk 2>/dev/null || echo 'N/A')"
echo "AAB size: $(du -sh build/app/outputs/bundle/release/app-release.aab 2>/dev/null || echo 'N/A')"
