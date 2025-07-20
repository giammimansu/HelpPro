# start_app.ps1
# Script PowerShell per avviare l'app Flutter con ottimizzazioni memoria

Write-Host "🚀 Avvio HelpPro App con ottimizzazioni memoria..." -ForegroundColor Green

# Vai alla directory del progetto
Set-Location "c:\Users\gianm\Desktop\MyApps\HelpPro\helppro-frontend\helppro_appv2"

# Verifica se Flutter è installato
try {
    flutter --version | Out-Host
} catch {
    Write-Host "❌ Flutter non trovato! Installare Flutter prima di continuare." -ForegroundColor Red
    exit 1
}

# Pulisci completamente il progetto
Write-Host "🧹 Pulizia completa progetto..." -ForegroundColor Yellow
flutter clean
if (Test-Path "build") { Remove-Item -Recurse -Force "build" }
if (Test-Path ".dart_tool") { Remove-Item -Recurse -Force ".dart_tool" }

# Reinstalla dipendenze
Write-Host "📦 Reinstallazione dipendenze..." -ForegroundColor Yellow
flutter pub get

# Verifica dispositivi disponibili
Write-Host "📱 Verifica dispositivi..." -ForegroundColor Cyan
flutter devices

# Controlla se l'emulatore è disponibile
Write-Host "🔍 Controllo emulatore..." -ForegroundColor Cyan
adb devices

# Configura variabili di ambiente per ridurre uso memoria
$env:FLUTTER_ENGINE_ENABLE_SKIA_TRACING = "false"

# Avvia l'app con configurazioni ottimizzate per memoria
Write-Host "▶️ Avvio app con ottimizzazioni memoria..." -ForegroundColor Green
Write-Host "⚠️ Se l'app va in OutOfMemory, ridurre ulteriormente le impostazioni" -ForegroundColor Yellow

flutter run `
  --debug `
  --device-id emulator-5554 `
  --hot `
  --dart-define=flutter.impeller=false `
  --dart-define=flutter.service_protocol.disable=false `
  --dart-define=flutter.trace_skia=false
