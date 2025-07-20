#!/bin/bash
# File: start_app.sh
# Script per avviare l'app Flutter con configurazioni ottimizzate per memoria

echo "🚀 Avvio HelpPro App con ottimizzazioni memoria..."

# Vai alla directory del progetto
cd "c:\Users\gianm\Desktop\MyApps\HelpPro\helppro-frontend\helppro_appv2"

# Pulisci completamente il progetto
echo "🧹 Pulizia completa progetto..."
flutter clean
rm -rf build/
rm -rf .dart_tool/

# Reinstalla dipendenze
echo "📦 Reinstallazione dipendenze..."
flutter pub get

# Verifica dispositivi disponibili
echo "📱 Verifica dispositivi..."
flutter devices

# Controlla se l'emulatore è disponibile
echo "🔍 Controllo emulatore..."
adb devices

# Avvia l'app con configurazioni ottimizzate per memoria
echo "▶️ Avvio app con ottimizzazioni memoria..."
flutter run \
  --debug \
  --device-id emulator-5554 \
  --hot \
  --dart-define=flutter.impeller=false \
  --dart-define=flutter.service_protocol.disable=false \
  --verbose
