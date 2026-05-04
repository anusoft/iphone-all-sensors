# All Sensors - Visor de Sensores iPhone

Una aplicación iOS completa que muestra datos en tiempo real de **todos los sensores disponibles del iPhone** con hermosas visualizaciones de UI.

Construido con **SwiftUI** y potenciado por el asistente AI **Xiaomi MiMo 2.5 Pro**.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | [日本語](README-ja.md) | [한국어](README-ko.md) | **Español** | [Français](README-fr.md) | [Deutsch](README-de.md) | [Português](README-pt.md) | [العربية](README-ar.md)

## Características

### Sensores Soportados

| Categoría | Sensores |
|-----------|----------|
| **Movimiento y Actividad** | Acelerómetro, Giroscopio, Magnetómetro, Movimiento del dispositivo, Podómetro, Altímetro, Reconocimiento de actividad |
| **Ubicación y Navegación** | GPS (coordenadas, altitud, velocidad), Brújula (norte verdadero/magnético) |
| **Entorno** | Barómetro (kPa, hPa, inHg, mbar), Sensor de proximidad, Brillo de pantalla |
| **Sistema** | Batería, Procesador, Memoria, Almacenamiento, Estado térmico |
| **Conectividad** | Bluetooth (escaneo, dispositivos), Red (Wi-Fi/CELULAR) |
| **Cámara y Audio** | Información de cámara, Control de linterna |

### Características de UI

- **Datos en tiempo real** - Actualización en vivo al mover el dispositivo
- **Hermosas visualizaciones**: Medidores circulares, Orientación 3D del teléfono, Dial de brújula
- **Flujo de permisos**: UI guiada que explica por qué cada sensor necesita acceso
- **Búsqueda**: Encuentra cualquier sensor rápidamente
- **Multi-idioma**: English, ไทย, 中文
- **Modo oscuro**
- **Registro de diagnóstico** para depuración

## Requisitos

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- iPhone físico (la mayoría de los sensores requieren hardware real)

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Abrir en Xcode:
```bash
open iPhoneSensors.xcodeproj
```

3. Seleccionar tu iPhone como dispositivo objetivo

4. Firmar la app con tu Apple ID

5. Compilar y ejecutar (`Cmd+R`)

6. En tu iPhone, ve a **Configuración → General → VPN y gestión de dispositivos** y confía en tu perfil de desarrollador

## Arquitectura

- **SwiftUI** para UI declarativa
- Patrón **ObservableObject** con `@EnvironmentObject` para enlace de datos reactivo
- **CoreMotion** para sensores de movimiento
- **CoreLocation** para GPS y brújula
- **CoreBluetooth** para escaneo BLE
- **AVFoundation** para cámara/audio

## Agradecimientos

- Construido con el asistente AI **Xiaomi MiMo 2.5 Pro**

## Licencia

Este proyecto está licenciado bajo la licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles

---

**Nota**: La mayoría de los sensores (acelerómetro, giroscopio, etc.) solo funcionan en dispositivos iOS físicos, no en el simulador.
