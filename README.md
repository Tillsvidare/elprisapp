# Elpris - Swedish Electricity Price App

En Flutter-app som visar aktuella svenska elpriser med diagram och hemskärmswidget.

## Funktioner

- **Aktuellt pris**: Visar nuvarande elpris för den valda regionen
- **24-timmars diagram**: Visualiserar alla 96 prisperioder (15-minutersintervaller) för dagen
- **Regionväljare**: Byt mellan SE1 (Luleå), SE2 (Sundsvall), SE3 (Stockholm) och SE4 (Malmö)
- **Pull-to-refresh**: Dra nedåt för att uppdatera prisdata
- **Hemskärmswidget**: Visar nuvarande pris + kommande 6 perioder direkt på hemskärmen
- **Statistik**: Min, Max och Genomsnittspris för dagen

## Krav

- Flutter SDK (version 3.0.0 eller senare)
- Android SDK (minSdkVersion 24 / Android 7.0)
- Dart SDK (version 3.0.0 eller senare)

## Installation

### 1. Installera Flutter

Om du inte har Flutter installerat, följ instruktionerna på: https://flutter.dev/docs/get-started/install/windows

### 2. Klona eller navigera till projektet

```bash
cd C:\kod\elprisapp
```

### 3. Installera dependencies

```bash
flutter pub get
```

### 4. Kör appen

#### På Android-emulator eller fysisk enhet:

```bash
flutter run
```

#### Bygg APK för distribution:

```bash
flutter build apk --release
```

APK-filen finns då i: `build/app/outputs/flutter-apk/app-release.apk`

## Hemskärmswidget

### Lägga till widget på hemskärmen:

1. Tryck och håll på en tom yta på hemskärmen
2. Välj "Widgets" eller "Lägg till widgets"
3. Hitta "Elpris" i listan
4. Dra widgeten till önskad plats på hemskärmen

### Widget-funktioner:

- Visar nuvarande elpris (stort)
- Visar kommande 6 perioder (1 timme 45 minuter framåt)
- Uppdateras automatiskt var 15:e minut
- Tryck på widgeten för att öppna appen

## Projektstruktur

```
lib/
├── main.dart                      # Appstart
├── models/
│   └── price_data.dart           # Prisdatamodell
├── services/
│   ├── electricity_api.dart      # API-tjänst
│   └── preferences_service.dart  # Inställningar
├── screens/
│   └── home_screen.dart          # Huvudskärm
├── widgets/
│   ├── current_price_card.dart   # Nuvarande pris
│   ├── price_chart.dart          # Prisdiagram
│   └── region_selector.dart      # Regionväljare
└── home_widget/
    └── price_widget_provider.dart # Widget-provider

android/
├── app/src/main/
│   ├── kotlin/com/elpris/elprisapp/
│   │   ├── MainActivity.kt
│   │   └── HomeScreenWidgetProvider.kt
│   └── res/
│       ├── layout/price_widget.xml
│       ├── xml/price_widget_info.xml
│       ├── drawable/
│       │   ├── widget_background.xml
│       │   └── current_price_background.xml
│       └── values/strings.xml
```

## API

Appen hämtar data från: https://www.elprisetjustnu.se/api/v1/prices/

API-format: `https://www.elprisetjustnu.se/api/v1/prices/YYYY/MM-DD_REGION.json`

Exempel: `https://www.elprisetjustnu.se/api/v1/prices/2026/01-11_SE3.json`

## Dependencies

- `http: ^1.1.0` - HTTP-anrop
- `fl_chart: ^0.66.0` - Diagramvisualisering
- `intl: ^0.19.0` - Datum/tid-formatering
- `shared_preferences: ^2.2.0` - Spara vald region
- `home_widget: ^0.4.0` - Hemskärmswidget

## Felsökning

### Flutter kommandot hittas inte

Se till att Flutter är installerat och finns i din PATH. Testa:
```bash
flutter --version
```

### Appen kraschar vid start

1. Kontrollera att du har kört `flutter pub get`
2. Kontrollera internetanslutning (appen behöver hämta data)
3. Kör `flutter clean` följt av `flutter pub get`

### Widget uppdateras inte

1. Ta bort och lägg till widgeten igen
2. Öppna appen för att tvinga en uppdatering
3. Kontrollera att widgetens uppdateringsfrekvens är korrekt inställd

## Licens

MIT License

## Kontakt

För bugrapporter och funktionsförfrågningar, öppna en issue på GitHub.
