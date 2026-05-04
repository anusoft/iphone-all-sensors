# All Sensors - iPhone Sensor Viewer

Eine umfassende iOS-App, die Echtzeitdaten von **allen verfügbaren iPhone-Sensoren** mit schönen UI-Visualisierungen anzeigt.

Erstellt mit **SwiftUI** und angetrieben von **Xiaomi MiMo 2.5 Pro** AI-Assistent.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | [日本語](README-ja.md) | [한국어](README-ko.md) | [Español](README-es.md) | [Français](README-fr.md) | **Deutsch** | [Português](README-pt.md) | [العربية](README-ar.md)

## Funktionen

### Unterstützte Sensoren

| Kategorie | Sensoren |
|-----------|----------|
| **Bewegung und Aktivität** | Beschleunigungsmesser, Gyroskop, Magnetometer, Gerätebewegung, Schrittzähler, Höhenmesser, Aktivitätserkennung |
| **Standort und Navigation** | GPS (Koordinaten, Höhe, Geschwindigkeit), Kompass (wahrer/magnetischer Norden) |
| **Umgebung** | Barometer (kPa, hPa, inHg, mbar), Näherungssensor, Bildschirmhelligkeit |
| **System** | Akku, Prozessor, Speicher, Speicherplatz, Thermischer Zustand |
| **Konnektivität** | Bluetooth (Scan, Geräte), Netzwerk (Wi-Fi/Mobilfunk) |
| **Kamera und Audio** | Kamerainformationen, Taschenlampensteuerung |

### UI-Funktionen

- **Echtzeitdaten** - Live-Updates beim Bewegen des Geräts
- **Schöne Visualisierungen**: Kreisförmige Anzeigen, 3D-Telefonorientierung, Kompasszifferblatt
- **Berechtigungsfluss**: Geführte UI, die erklärt, warum jeder Sensor Zugriff benötigt
- **Suche**: Finden Sie jeden Sensor schnell
- **Mehrsprachig**: English, ไทย, 中文
- **Dunkelmodus**
- **Diagnoseprotokolle** zum Debuggen

## Anforderungen

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Physisches iPhone (die meisten Sensoren benötigen echte Hardware)

## Installation

1. Repository klonen:
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. In Xcode öffnen:
```bash
open iPhoneSensors.xcodeproj
```

3. Wählen Sie Ihr iPhone als Zielgerät

4. Signieren Sie die App mit Ihrer Apple ID

5. Erstellen und ausführen (`Cmd+R`)

6. Gehen Sie auf Ihrem iPhone zu **Einstellungen → Allgemein → VPN & Geräteverwaltung** und vertrauen Sie Ihrem Entwicklerprofil

## Architektur

- **SwiftUI** für deklarative UI
- **ObservableObject**-Muster mit `@EnvironmentObject` für reaktive Datenbindung
- **CoreMotion** für Bewegungssensoren
- **CoreLocation** für GPS und Kompass
- **CoreBluetooth** für BLE-Scan
- **AVFoundation** für Kamera/Audio

## Danksagungen

- Erstellt mit **Xiaomi MiMo 2.5 Pro** AI-Assistent

## Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) für Details

---

**Hinweis**: Die meisten Sensoren (Beschleunigungsmesser, Gyroskop usw.) funktionieren nur auf physischen iOS-Geräten, nicht im Simulator.
