# All Sensors - iPhone 传感器查看器

一个全面的 iOS 应用，显示来自**所有可用 iPhone 传感器**的实时数据，具有精美的 UI 可视化。

使用 **SwiftUI** 构建，由 **Xiaomi MiMo 2.5 Pro** AI 助手驱动。

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | **中文** | [日本語](README-ja.md) | [한국어](README-ko.md) | [Español](README-es.md) | [Français](README-fr.md) | [Deutsch](README-de.md) | [Português](README-pt.md) | [العربية](README-ar.md)

## 功能

### 支持的传感器

| 类别 | 传感器 |
|------|--------|
| **运动与活动** | 加速度计、陀螺仪、磁力计、设备运动、计步器、高度计、活动识别 |
| **位置与导航** | GPS（坐标、海拔、速度）、指南针（真北/磁北） |
| **环境** | 气压计（kPa、hPa、inHg、mbar）、接近传感器、屏幕亮度 |
| **系统** | 电池、处理器、内存、存储、热状态 |
| **连接** | 蓝牙（扫描、设备）、网络（Wi-Fi/蜂窝） |
| **相机与音频** | 相机信息、手电筒控制 |

### UI 功能

- **实时数据** - 移动设备时实时更新
- **精美可视化**：圆形仪表、3D 手机方向、指南针表盘
- **权限流程**：引导式 UI 解释每个传感器为什么需要访问
- **搜索**：快速查找任何传感器
- **多语言**：English、中文、ไทย
- **暗黑模式**支持
- **诊断日志**用于调试

## 要求

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- 真实 iPhone（大多数传感器需要真实硬件）

## 安装

1. 克隆仓库：
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. 在 Xcode 中打开：
```bash
open iPhoneSensors.xcodeproj
```

3. 选择您的 iPhone 作为目标设备

4. 使用您的 Apple ID 签名应用

5. 构建并运行（`Cmd+R`）

6. 在 iPhone 上，前往 **设置 → 通用 → VPN 与设备管理**，信任您的开发者配置文件

## 项目结构

```
iPhoneSensors/
├── App/                    # 应用入口点
├── Views/
│   ├── Dashboard/          # 主传感器仪表板
│   ├── Sensors/            # 传感器详情视图
│   └── Components/         # 可重用 UI 组件
├── Services/               # 传感器管理器
├── Models/                 # 数据模型
└── Resources/              # 应用配置
```

## 架构

- **SwiftUI** 用于声明式 UI
- **ObservableObject** 模式与 `@EnvironmentObject` 用于响应式数据绑定
- **CoreMotion** 用于运动传感器
- **CoreLocation** 用于 GPS 和指南针
- **CoreBluetooth** 用于 BLE 扫描
- **AVFoundation** 用于相机/音频

## 致谢

- 由 **Xiaomi MiMo 2.5 Pro** AI 助手构建

## 许可证

此项目根据 MIT 许可证授权 - 详见 [LICENSE](LICENSE) 文件

---

**注意**：大多数传感器（加速度计、陀螺仪等）仅在真实 iOS 设备上工作，不在模拟器上工作。
