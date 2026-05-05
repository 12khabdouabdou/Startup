#!/bin/bash

# EcoRoute Setup Script
# Run this script to set up and run the EcoRoute Flutter app

echo "🚀 EcoRoute - Setup and Run Script"
echo "=================================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo ""
    echo "Please install Flutter first:"
    echo "  macOS:  brew install --cask flutter"
    echo "  Windows: Download from https://flutter.dev/docs/get-started/install/windows"
    echo "  Linux:   sudo snap install flutter --classic"
    echo ""
    echo "Or visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter found!"
flutter --version
echo ""

# Navigate to project
cd "$(dirname "$0")"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Run code generation
echo "🔧 Running code generation..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""

# Check for errors
if [ $? -eq 0 ]; then
    echo "✅ Setup complete!"
    echo ""
    echo "🎯 Next steps:"
    echo "   1. Create a Supabase project at https://supabase.com"
    echo "   2. Copy your Project URL and anon key"
    echo "   3. Create lib/core/config/env.dart with:"
    echo ""
    echo "      class Env {"
    echo "        static const String supabaseUrl = 'YOUR_URL';"
    echo "        static const String supabaseAnonKey = 'YOUR_KEY';"
    echo "      }"
    echo ""
    echo "   4. Run the app:"
    echo "      flutter run"
    echo ""
    echo "🚀 Ready to run! Execute: flutter run"
else
    echo "❌ Setup failed. Please check the errors above."
    exit 1
fi
