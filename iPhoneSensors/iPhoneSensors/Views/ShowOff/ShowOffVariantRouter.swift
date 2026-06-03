import SwiftUI

// Routes (sensorID, variantIndex) -> the right variant view.
// Each variant view is a self-contained 402×874-ish full-bleed canvas.

struct SOVariantRouter: View {
    let sensor: SOSensorEntry
    let variant: Int

    var body: some View {
        switch sensor.id {
        // ── Motion & Location ──────────────────────────────────────
        case "01": SOGPS(variant: variant)
        case "02": SOHeading(variant: variant)
        case "03": SOAccel(variant: variant)
        case "04": SOGyro(variant: variant)
        // ── Environment ────────────────────────────────────────────
        case "05": SOMag(variant: variant)
        case "06": SODeviceMotion(variant: variant)
        case "07": SOAlt(variant: variant)
        case "08": SOBaro(variant: variant)
        case "09": SOPed(variant: variant)
        case "10": SOActivity(variant: variant)
        // ── System ─────────────────────────────────────────────────
        case "11": SOBattery(variant: variant)
        case "12": SOThermal(variant: variant)
        case "13": SODisk(variant: variant)
        case "14": SOMem(variant: variant)
        case "15": SOCPU(variant: variant)
        // ── Connectivity / Hardware ────────────────────────────────
        case "16": SOBluetooth(variant: variant)
        case "17": SONetwork(variant: variant)
        case "18": SOCamera(variant: variant)
        case "19": SOLight(variant: variant)
        case "20": SOProx(variant: variant)
        case "21": SOTorch(variant: variant)
        default:   SOPlaceholder(text: "Unknown sensor")
        }
    }
}

// MARK: - Placeholder used while variants are being filled in

struct SOPlaceholder: View {
    let text: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Text(text)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}
