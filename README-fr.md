# All Sensors - Visionneuse de Capteurs iPhone

Une application iOS complète affichant des données en temps réel de **tous les capteurs iPhone disponibles** avec de belles visualisations UI.

Construit avec **SwiftUI** et propulsé par l'assistant AI **Xiaomi MiMo 2.5 Pro**.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | [日本語](README-ja.md) | [한국어](README-ko.md) | [Español](README-es.md) | **Français** | [Deutsch](README-de.md) | [Português](README-pt.md) | [العربية](README-ar.md)

## Fonctionnalités

### Capteurs Supportés

| Catégorie | Capteurs |
|-----------|----------|
| **Mouvement et Activité** | Accéléromètre, Gyroscope, Magnétomètre, Mouvement de l'appareil, Podomètre, Altimètre, Reconnaissance d'activité |
| **Position et Navigation** | GPS (coordonnées, altitude, vitesse), Boussole (nord vrai/magnétique) |
| **Environnement** | Baromètre (kPa, hPa, inHg, mbar), Capteur de proximité, Luminosité de l'écran |
| **Système** | Batterie, Processeur, Mémoire, Stockage, État thermique |
| **Connectivité** | Bluetooth (scan, appareils), Réseau (Wi-Fi/Cellulaire) |
| **Caméra et Audio** | Informations caméra, Contrôle de la lampe torche |

### Fonctionnalités UI

- **Données en temps réel** - Mise à jour en direct lors du déplacement de l'appareil
- **Belles visualisations** : Jauges circulaires, Orientation 3D du téléphone, Cadran de boussole
- **Flux de permissions** : UI guidée expliquant pourquoi chaque capteur a besoin d'accès
- **Recherche** : Trouvez rapidement n'importe quel capteur
- **Multi-langue** : English, ไทย, 中文
- **Mode sombre**
- **Journal de diagnostic** pour le débogage

## Prérequis

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- iPhone physique (la plupart des capteurs nécessitent du matériel réel)

## Installation

1. Cloner le dépôt :
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Ouvrir dans Xcode :
```bash
open iPhoneSensors.xcodeproj
```

3. Sélectionner votre iPhone comme appareil cible

4. Signer l'application avec votre Apple ID

5. Compiler et exécuter (`Cmd+R`)

6. Sur votre iPhone, allez dans **Réglages → Général → VPN et gestion des appareils** et faites confiance à votre profil de développeur

## Architecture

- **SwiftUI** pour l'UI déclarative
- Pattern **ObservableObject** avec `@EnvironmentObject` pour la liaison de données réactive
- **CoreMotion** pour les capteurs de mouvement
- **CoreLocation** pour le GPS et la boussole
- **CoreBluetooth** pour le scan BLE
- **AVFoundation** pour la caméra/l'audio

## Remerciements

- Construit avec l'assistant AI **Xiaomi MiMo 2.5 Pro**

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour les détails

---

**Note** : La plupart des capteurs (accéléromètre, gyroscope, etc.) ne fonctionnent que sur les appareils iOS physiques, pas sur le simulateur.
