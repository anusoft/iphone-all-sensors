# All Sensors - Visualizador de Sensores iPhone

Um aplicativo iOS abrangente que exibe dados em tempo real de **todos os sensores disponíveis do iPhone** com belas visualizações de UI.

Construído com **SwiftUI** e alimentado pelo assistente AI **Xiaomi MiMo 2.5 Pro**.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | [日本語](README-ja.md) | [한국어](README-ko.md) | [Español](README-es.md) | [Français](README-fr.md) | [Deutsch](README-de.md) | **Português** | [العربية](README-ar.md)

## Recursos

### Sensores Suportados

| Categoria | Sensores |
|-----------|----------|
| **Movimento e Atividade** | Acelerômetro, Giroscópio, Magnetômetro, Movimento do dispositivo, Podômetro, Altímetro, Reconhecimento de atividade |
| **Localização e Navegação** | GPS (coordenadas, altitude, velocidade), Bússola (norte verdadeiro/magnético) |
| **Ambiente** | Barômetro (kPa, hPa, inHg, mbar), Sensor de proximidade, Brilho da tela |
| **Sistema** | Bateria, Processador, Memória, Armazenamento, Estado térmico |
| **Conectividade** | Bluetooth (scan, dispositivos), Rede (Wi-Fi/CELULAR) |
| **Câmera e Áudio** | Informações da câmera, Controle da lanterna |

### Recursos de UI

- **Dados em tempo real** - Atualização ao vivo ao mover o dispositivo
- **Belas visualizações**: Medidores circulares, Orientação 3D do telefone, Mostrado da bússola
- **Fluxo de permissões**: UI guiada explicando por que cada sensor precisa de acesso
- **Pesquisa**: Encontre qualquer sensor rapidamente
- **Multi-idioma**: English, ไทย, 中文
- **Modo escuro**
- **Logs de diagnóstico** para depuração

## Requisitos

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- iPhone físico (a maioria dos sensores requer hardware real)

## Instalação

1. Clonar o repositório:
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Abrir no Xcode:
```bash
open iPhoneSensors.xcodeproj
```

3. Selecionar seu iPhone como dispositivo alvo

4. Assinar o app com seu Apple ID

5. Compilar e executar (`Cmd+R`)

6. No seu iPhone, vá para **Configurações → Geral → VPN e Gerenciamento de Dispositivos** e confie no seu perfil de desenvolvedor

## Arquitetura

- **SwiftUI** para UI declarativa
- Padrão **ObservableObject** com `@EnvironmentObject` para vinculação de dados reativa
- **CoreMotion** para sensores de movimento
- **CoreLocation** para GPS e bússola
- **CoreBluetooth** para scan BLE
- **AVFoundation** para câmera/áudio

## Agradecimentos

- Construído com o assistente AI **Xiaomi MiMo 2.5 Pro**

## Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes

---

**Nota**: A maioria dos sensores (acelerômetro, giroscópio, etc.) só funciona em dispositivos iOS físicos, não no simulador.
