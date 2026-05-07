import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case thai = "th"
    case chinese = "zh"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .thai: return "ไทย"
        case .chinese: return "中文"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .thai: return "🇹🇭"
        case .chinese: return "🇨🇳"
        }
    }
}

@MainActor
class LocalizationManager: ObservableObject {
    @AppStorage("appLanguage") var currentLanguage: AppLanguage = .english

    func t(_ key: String) -> String {
        return Translations.get(key, language: currentLanguage)
    }
}

enum Translations {
    static func get(_ key: String, language: AppLanguage) -> String {
        switch language {
        case .english: return english[key] ?? key
        case .thai: return thai[key] ?? english[key] ?? key
        case .chinese: return chinese[key] ?? english[key] ?? key
        }
    }

    static let english: [String: String] = [
        // Tabs
        "tab.sensors": "Sensors",
        "tab.system": "System",
        "tab.environment": "Environment",
        "tab.health": "Health",

        // Dashboard
        "dashboard.title": "All Sensors",
        "dashboard.search": "Search sensors...",
        "dashboard.motion": "Motion & Activity",
        "dashboard.location": "Location & Navigation",
        "dashboard.environment": "Environment",
        "dashboard.system": "System",
        "dashboard.connectivity": "Connectivity",
        "dashboard.camera": "Camera & Audio",

        // Motion sensors
        "sensor.accelerometer": "Accelerometer",
        "sensor.gyroscope": "Gyroscope",
        "sensor.magnetometer": "Magnetometer",
        "sensor.deviceMotion": "Device Motion",
        "sensor.pedometer": "Pedometer",
        "sensor.altimeter": "Altimeter",
        "sensor.activity": "Activity",

        // Location sensors
        "sensor.gps": "GPS Location",
        "sensor.compass": "Compass Heading",

        // Environment sensors
        "sensor.barometer": "Barometer",
        "sensor.proximity": "Proximity",
        "sensor.brightness": "Screen Brightness",

        // System sensors
        "sensor.battery": "Battery",
        "sensor.processor": "Processor",
        "sensor.memory": "Memory",
        "sensor.storage": "Storage",
        "sensor.thermal": "Thermal State",

        // Connectivity
        "sensor.bluetooth": "Bluetooth",
        "sensor.network": "Network",

        // Camera
        "sensor.camera": "Camera",
        "sensor.torch": "Torch",

        // Status
        "status.available": "Available",
        "status.unavailable": "Unavailable",
        "status.active": "Active",
        "status.loading": "Loading...",
        "status.noData": "No data yet",
        "status.waiting": "Waiting for data...",

        // Units
        "unit.steps": "steps",
        "unit.meters": "m",
        "unit.g": "G",
        "unit.rads": "rad/s",
        "unit.ut": "µT",
        "unit.kpa": "kPa",
        "unit.bpm": "bpm",
        "unit.percent": "%",
        "unit.cores": "cores",
        "unit.free": "free",

        // Permission
        "permission.welcome": "Welcome to All Sensors",
        "permission.welcome.desc": "This app displays real-time data from all your iPhone's sensors.",
        "permission.getStarted": "Get Started",
        "permission.location": "Location Access",
        "permission.location.desc": "We use your location to show GPS coordinates, altitude, speed, and compass heading.",
        "permission.allowLocation": "Allow Location Access",
        "permission.motion": "Motion & Fitness",
        "permission.motion.desc": "We use motion sensors to show accelerometer, gyroscope, pedometer, and activity data.",
        "permission.allowMotion": "Allow Motion Access",
        "permission.camera": "Camera Access",
        "permission.camera.desc": "We use the camera to show camera capabilities and control the torch/flashlight.",
        "permission.allowCamera": "Allow Camera Access",
        "permission.microphone": "Microphone Access",
        "permission.microphone.desc": "We use the microphone to show audio input device information.",
        "permission.allowMicrophone": "Allow Microphone Access",
        "permission.allSet": "You're All Set!",
        "permission.allSet.desc": "You can change permissions anytime in Settings.",
        "permission.startUsing": "Start Using App",
        "permission.notNow": "Not Now",

        // Language
        "language.title": "Language",

        // Logger - tab & overview
        "tab.logger": "Logger",
        "logger.title": "Logger",
        "logger.start": "Start session",
        "logger.stop": "Stop session",
        "logger.continuousActive": "sensors logging continuously",
        "logger.sessionRecording": "Recording session",
        "logger.sessionIdle": "No active session",
        "logger.storage": "Storage",

        // Logger - per-sensor config
        "logger.stream.continuous": "Continuous stream",
        "logger.stream.session": "Session stream",
        "logger.format": "Format",
        "logger.interval": "Interval",
        "logger.interval.everySample": "Every sample",
        "logger.enabled": "Enabled",
        "logger.format.sqlite": "SQLite",
        "logger.format.jsonl": "JSON Lines",
        "logger.format.csv": "CSV",

        // Logger - inline card
        "logger.inlineCard.notLogging": "Not currently logging",
        "logger.inlineCard.configure": "Configure logger",

        // Logger - settings
        "logger.settings.title": "Logger Settings",
        "logger.settings.done": "Done",
        "logger.settings.storageSection": "Storage",
        "logger.settings.cap": "Storage cap",
        "logger.settings.clearContinuous": "Clear all continuous data",
        "logger.settings.clearConfirm": "This will permanently delete all continuous-stream data. Sessions are not affected.",
        "logger.settings.behaviorSection": "Behavior",
        "logger.settings.disableAutoLock": "Disable auto-lock during session",
        "logger.settings.pauseLowBattery": "Pause continuous on low battery",
        "logger.settings.pauseThermal": "Pause continuous on thermal warning",
        "logger.settings.privacySection": "Privacy",
        "logger.settings.showExportWarning": "Show export warning",

        // Sensor categories (Logger overview groupings)
        "category.motion": "Motion",
        "category.location": "Location",
        "category.environment": "Environment",
        "category.system": "System",
        "category.connectivity": "Connectivity",
        "category.camera": "Camera",
        "category.health": "Health",

        // SensorID display names (one per SensorID.rawValue, prefixed `sensor.`)
        "sensor.motion.accelerometer": "Accelerometer",
        "sensor.motion.gyroscope": "Gyroscope",
        "sensor.motion.magnetometer": "Magnetometer",
        "sensor.motion.deviceMotion": "Device Motion",
        "sensor.motion.altimeter": "Altimeter",
        "sensor.motion.pedometer": "Pedometer",
        "sensor.motion.activity": "Motion Activity",
        "sensor.location.gps": "GPS",
        "sensor.location.heading": "Heading",
        "sensor.environment.proximity": "Proximity",
        "sensor.environment.brightness": "Screen Brightness",
        "sensor.environment.torch": "Torch",
        "sensor.environment.audio": "Audio Session",
        "sensor.system.battery": "Battery",
        "sensor.system.thermal": "Thermal State",
        "sensor.system.lowPower": "Low-Power Mode",
        "sensor.system.orientation": "Orientation",
        "sensor.system.disk": "Disk",
        "sensor.system.uptime": "Uptime",
        "sensor.connectivity.bluetoothState": "Bluetooth State",
        "sensor.connectivity.bluetoothScan": "Bluetooth Scan",
        "sensor.connectivity.network": "Network",
        "sensor.connectivity.cellular": "Cellular",
        "sensor.camera.snapshot": "Camera",
        "sensor.health.metric": "Health",

        // Data Viewer
        "dataviewer.title": "Data Viewer",
        "dataviewer.tab.sessions": "Sessions",
        "dataviewer.tab.sensor": "By Sensor",
        "dataviewer.tab.files": "Files",
        "dataviewer.delete": "Delete",
        "dataviewer.session.active": "active",
        "dataviewer.session.metadata": "Metadata",
        "dataviewer.session.perSensor": "Per-sensor",
        "dataviewer.session.title": "Session",
        "dataviewer.sensor": "Sensor",
        "dataviewer.source": "Source",
        "dataviewer.source.continuous": "Continuous",
        "dataviewer.source.latestSession": "Latest Session",
    ]

    static let thai: [String: String] = [
        "tab.sensors": "เซ็นเซอร์",
        "tab.system": "ระบบ",
        "tab.environment": "สิ่งแวดล้อม",
        "tab.health": "สุขภาพ",
        "dashboard.title": "เซ็นเซอร์ทั้งหมด",
        "dashboard.search": "ค้นหาเซ็นเซอร์...",
        "dashboard.motion": "การเคลื่อนไหวและกิจกรรม",
        "dashboard.location": "ตำแหน่งและการนำทาง",
        "dashboard.environment": "สิ่งแวดล้อม",
        "dashboard.system": "ระบบ",
        "dashboard.connectivity": "การเชื่อมต่อ",
        "dashboard.camera": "กล้องและเสียง",
        "sensor.accelerometer": "เครื่องวัดความเร่ง",
        "sensor.gyroscope": "ไจโรสโคป",
        "sensor.magnetometer": "แมกนิโตมิเตอร์",
        "sensor.deviceMotion": "การเคลื่อนไหวของอุปกรณ์",
        "sensor.pedometer": "เครื่องนับก้าว",
        "sensor.altimeter": "เครื่องวัดความสูง",
        "sensor.activity": "กิจกรรม",
        "sensor.gps": "ตำแหน่ง GPS",
        "sensor.compass": "เข็มทิศ",
        "sensor.barometer": "บารอมิเตอร์",
        "sensor.proximity": "เซ็นเซอร์วัดระยะ",
        "sensor.brightness": "ความสว่างหน้าจอ",
        "sensor.battery": "แบตเตอรี่",
        "sensor.processor": "โปรเซสเซอร์",
        "sensor.memory": "หน่วยความจำ",
        "sensor.storage": "พื้นที่จัดเก็บ",
        "sensor.thermal": "สถานะความร้อน",
        "sensor.bluetooth": "บลูทูธ",
        "sensor.network": "เครือข่าย",
        "sensor.camera": "กล้อง",
        "sensor.torch": "ไฟฉาย",
        "status.available": "พร้อมใช้งาน",
        "status.unavailable": "ไม่พร้อมใช้งาน",
        "status.active": "ทำงาน",
        "status.loading": "กำลังโหลด...",
        "status.noData": "ยังไม่มีข้อมูล",
        "status.waiting": "กำลังรอข้อมูล...",
        "unit.steps": "ก้าว",
        "unit.meters": "ม.",
        "unit.g": "G",
        "unit.rads": "rad/s",
        "unit.ut": "µT",
        "unit.kpa": "kPa",
        "unit.bpm": "ครั้ง/นาที",
        "unit.percent": "%",
        "unit.cores": "คอร์",
        "unit.free": "ว่าง",
        "permission.welcome": "ยินดีต้อนรับสู่ All Sensors",
        "permission.welcome.desc": "แอปนี้แสดงข้อมูลแบบเรียลไทม์จากเซ็นเซอร์ทั้งหมดของ iPhone ของคุณ",
        "permission.getStarted": "เริ่มต้นใช้งาน",
        "permission.location": "การเข้าถึงตำแหน่ง",
        "permission.location.desc": "เราใช้ตำแหน่งของคุณเพื่อแสดงพิกัด GPS ความสูง ความเร็ว และเข็มทิศ",
        "permission.allowLocation": "อนุญาตการเข้าถึงตำแหน่ง",
        "permission.motion": "การเคลื่อนไหวและฟิตเนส",
        "permission.motion.desc": "เราใช้เซ็นเซอร์การเคลื่อนไหวเพื่อแสดงข้อมูล accelerometer, gyrometer, เครื่องนับก้าว และกิจกรรม",
        "permission.allowMotion": "อนุญาตการเข้าถึงการเคลื่อนไหว",
        "permission.camera": "การเข้าถึงกล้อง",
        "permission.camera.desc": "เราใช้กล้องเพื่อแสดงข้อมูลความสามารถของกล้องและควบคุมไฟฉาย",
        "permission.allowCamera": "อนุญาตการเข้าถึงกล้อง",
        "permission.microphone": "การเข้าถึงไมโครโฟน",
        "permission.microphone.desc": "เราใช้ไมโครโฟนเพื่อแสดงข้อมูลอุปกรณ์อินพุตเสียง",
        "permission.allowMicrophone": "อนุญาตการเข้าถึงไมโครโฟน",
        "permission.allSet": "พร้อมแล้ว!",
        "permission.allSet.desc": "คุณสามารถเปลี่ยนการอนุญาตได้ตลอดเวลาในการตั้งค่า",
        "permission.startUsing": "เริ่มใช้แอป",
        "permission.notNow": "ข้ามไปก่อน",
        "language.title": "ภาษา",

        // Logger - tab & overview
        "tab.logger": "ตัวบันทึก",
        "logger.title": "ตัวบันทึก",
        "logger.start": "เริ่มเซสชัน",
        "logger.stop": "หยุดเซสชัน",
        "logger.continuousActive": "เซ็นเซอร์กำลังบันทึกต่อเนื่อง",
        "logger.sessionRecording": "กำลังบันทึก",
        "logger.sessionIdle": "ไม่มีเซสชันที่ทำงานอยู่",
        "logger.storage": "พื้นที่จัดเก็บ",

        // Logger - per-sensor config
        "logger.stream.continuous": "สตรีมต่อเนื่อง",
        "logger.stream.session": "สตรีมเซสชัน",
        "logger.format": "รูปแบบ",
        "logger.interval": "ช่วงเวลา",
        "logger.interval.everySample": "ทุกตัวอย่าง",
        "logger.enabled": "เปิดใช้งาน",
        "logger.inlineCard.notLogging": "ไม่ได้บันทึกในตอนนี้",
        "logger.inlineCard.configure": "ตั้งค่าตัวบันทึก",
        // Format names left as English (technical identifiers)

        // Logger - settings
        "logger.settings.title": "ตั้งค่าตัวบันทึก",
        "logger.settings.done": "เสร็จสิ้น",
        "logger.settings.storageSection": "พื้นที่จัดเก็บ",
        "logger.settings.cap": "ขีดจำกัดพื้นที่",
        "logger.settings.clearContinuous": "ล้างข้อมูลต่อเนื่องทั้งหมด",
        "logger.settings.clearConfirm": "การดำเนินการนี้จะลบข้อมูลสตรีมต่อเนื่องทั้งหมดอย่างถาวร เซสชันจะไม่ได้รับผลกระทบ",
        "logger.settings.behaviorSection": "พฤติกรรม",
        "logger.settings.disableAutoLock": "ปิดล็อคอัตโนมัติระหว่างเซสชัน",
        "logger.settings.pauseLowBattery": "หยุดสตรีมต่อเนื่องเมื่อแบตเตอรี่ต่ำ",
        "logger.settings.pauseThermal": "หยุดสตรีมต่อเนื่องเมื่ออุณหภูมิสูง",
        "logger.settings.privacySection": "ความเป็นส่วนตัว",
        "logger.settings.showExportWarning": "แสดงคำเตือนการส่งออก",

        // Sensor categories
        "category.motion": "การเคลื่อนไหว",
        "category.location": "ตำแหน่ง",
        "category.environment": "สภาพแวดล้อม",
        "category.system": "ระบบ",
        "category.connectivity": "การเชื่อมต่อ",
        "category.camera": "กล้อง",
        "category.health": "สุขภาพ",

        // SensorID display names left as English (technical names typically untranslated;
        // English fallback already kicks in for missing keys, but listed explicitly is OK
        // — kept omitted here so the English values fallback through Translations.get).

        // Data Viewer
        "dataviewer.title": "ตัวดูข้อมูล",
        "dataviewer.tab.sessions": "เซสชัน",
        "dataviewer.tab.sensor": "ตามเซ็นเซอร์",
        "dataviewer.tab.files": "ไฟล์",
        "dataviewer.delete": "ลบ",
        "dataviewer.session.active": "กำลังบันทึก",
        "dataviewer.session.metadata": "ข้อมูลเมตา",
        "dataviewer.session.perSensor": "แยกตามเซ็นเซอร์",
        "dataviewer.session.title": "เซสชัน",
        "dataviewer.sensor": "เซ็นเซอร์",
        "dataviewer.source": "แหล่ง",
        "dataviewer.source.continuous": "ต่อเนื่อง",
        "dataviewer.source.latestSession": "เซสชันล่าสุด",
    ]

    static let chinese: [String: String] = [
        "tab.sensors": "传感器",
        "tab.system": "系统",
        "tab.environment": "环境",
        "tab.health": "健康",
        "dashboard.title": "所有传感器",
        "dashboard.search": "搜索传感器...",
        "dashboard.motion": "运动与活动",
        "dashboard.location": "位置与导航",
        "dashboard.environment": "环境",
        "dashboard.system": "系统",
        "dashboard.connectivity": "连接",
        "dashboard.camera": "相机与音频",
        "sensor.accelerometer": "加速度计",
        "sensor.gyroscope": "陀螺仪",
        "sensor.magnetometer": "磁力计",
        "sensor.deviceMotion": "设备运动",
        "sensor.pedometer": "计步器",
        "sensor.altimeter": "高度计",
        "sensor.activity": "活动",
        "sensor.gps": "GPS位置",
        "sensor.compass": "指南针",
        "sensor.barometer": "气压计",
        "sensor.proximity": "接近传感器",
        "sensor.brightness": "屏幕亮度",
        "sensor.battery": "电池",
        "sensor.processor": "处理器",
        "sensor.memory": "内存",
        "sensor.storage": "存储",
        "sensor.thermal": "热状态",
        "sensor.bluetooth": "蓝牙",
        "sensor.network": "网络",
        "sensor.camera": "相机",
        "sensor.torch": "手电筒",
        "status.available": "可用",
        "status.unavailable": "不可用",
        "status.active": "活跃",
        "status.loading": "加载中...",
        "status.noData": "暂无数据",
        "status.waiting": "等待数据...",
        "unit.steps": "步",
        "unit.meters": "米",
        "unit.g": "G",
        "unit.rads": "rad/s",
        "unit.ut": "µT",
        "unit.kpa": "kPa",
        "unit.bpm": "次/分",
        "unit.percent": "%",
        "unit.cores": "核心",
        "unit.free": "空闲",
        "permission.welcome": "欢迎使用 All Sensors",
        "permission.welcome.desc": "此应用显示iPhone所有传感器的实时数据",
        "permission.getStarted": "开始使用",
        "permission.location": "位置访问",
        "permission.location.desc": "我们使用您的位置来显示GPS坐标、海拔、速度和指南针方向",
        "permission.allowLocation": "允许位置访问",
        "permission.motion": "运动与健身",
        "permission.motion.desc": "我们使用运动传感器来显示加速度计、陀螺仪、计步器和活动数据",
        "permission.allowMotion": "允许运动访问",
        "permission.camera": "相机访问",
        "permission.camera.desc": "我们使用相机来显示相机功能和控制手电筒",
        "permission.allowCamera": "允许相机访问",
        "permission.microphone": "麦克风访问",
        "permission.microphone.desc": "我们使用麦克风来显示音频输入设备信息",
        "permission.allowMicrophone": "允许麦克风访问",
        "permission.allSet": "设置完成！",
        "permission.allSet.desc": "您可以随时在设置中更改权限",
        "permission.startUsing": "开始使用",
        "permission.notNow": "稍后",
        "language.title": "语言",
    ]
}
