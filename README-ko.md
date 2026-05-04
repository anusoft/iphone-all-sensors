# All Sensors - iPhone 센서 뷰어

**사용 가능한 모든 iPhone 센서**에서 실시간 데이터를 표시하는 포괄적인 iOS 앱. 아름다운 UI 시각화 포함.

**SwiftUI**로 구축, **Xiaomi MiMo 2.5 Pro** AI 어시스턴트가 구동.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/Framework-SwUI-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

[English](README.md) | [ไทย](README-th.md) | [中文](README-zh.md) | [日本語](README-ja.md) | **한국어** | [Español](README-es.md) | [Français](README-fr.md) | [Deutsch](README-de.md) | [Português](README-pt.md) | [العربية](README-ar.md)

## 기능

### 지원되는 센서

| 카테고리 | 센서 |
|----------|------|
| **모션 및 활동** | 가속도계, 자이로스코프, 자력계, 기기 모션, 만보기, 고도계, 활동 인식 |
| **위치 및 내비게이션** | GPS(좌표, 고도, 속도), 나침반(진북/자북) |
| **환경** | 기압계(kPa, hPa, inHg, mbar), 근접 센서, 화면 밝기 |
| **시스템** | 배터리, 프로세서, 메모리, 저장소, 열 상태 |
| **연결** | Bluetooth(스캔, 장치), 네트워크(Wi-Fi/셀룰러) |
| **카메라 및 오디오** | 카메라 정보, 손전등 제어 |

### UI 기능

- **실시간 데이터** - 기기를 움직이면 실시간으로 업데이트
- **아름다운 시각화**: 원형 게이지, 3D 전화 방향, 나침반 다이얼
- **권한 흐름**: 각 센서에 액세스가 필요한 이유를 설명하는 가이드 UI
- **검색**: 모든 센서를 빠르게 검색
- **다국어**: English, ไทย, 中文
- **다크 모드** 지원
- **진단 로그**로 디버깅

## 요구 사항

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- 실제 iPhone(대부분의 센서는 실제 하드웨어 필요)

## 설치

1. 저장소 클론:
```bash
git clone https://github.com/anusoft/iphone-all-sensors.git
cd iphone-all-sensors/iPhoneSensors
```

2. Xcode에서 열기:
```bash
open iPhoneSensors.xcodeproj
```

3. iPhone을 대상 기기로 선택

4. Apple ID로 앱 서명

5. 빌드 및 실행 (`Cmd+R`)

6. iPhone에서 **설정 → 일반 → VPN 및 기기 관리**로 이동하여 개발자 프로필 신뢰

## 프로젝트 구조

```
iPhoneSensors/
├── App/                    # 앱 진입점
├── Views/
│   ├── Dashboard/          # 메인 센서 대시보드
│   ├── Sensors/            # 개별 센서 상세 보기
│   └── Components/         # 재사용 가능한 UI 구성 요소
├── Services/               # 센서 관리자
├── Models/                 # 데이터 모델
└── Resources/              # 앱 설정
```

## 아키텍처

- **SwiftUI** - 선언형 UI
- **ObservableObject** 패턴과 `@EnvironmentObject`로 반응형 데이터 바인딩
- **CoreMotion** - 모션 센서용
- **CoreLocation** - GPS 및 나침반용
- **CoreBluetooth** - BLE 스캔용
- **AVFoundation** - 카메라/오디오용

## 감사의 말

- **Xiaomi MiMo 2.5 Pro** AI 어시스턴트로 구축

## 라이센스

이 프로젝트는 MIT 라이센스에 따라 라이센스됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일 참조

---

**참고**: 대부분의 센서(가속도계, 자이로스코프 등)는 시뮬레이터가 아닌 실제 iOS 기기에서만 작동합니다.
