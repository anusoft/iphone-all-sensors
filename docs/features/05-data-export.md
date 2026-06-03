# Feature 05: Add CSV/JSON Data Export

## Checklist

- [ ] Create DataExportManager service
- [ ] Export current sensor snapshot (all sensors)
- [ ] Export recorded session data
- [ ] CSV format with timestamps
- [ ] JSON format for structured data
- [ ] Share via UIActivityViewController
- [ ] Save to Files app
- [ ] Add export button to all detail views
- [ ] Add export button to dashboard toolbar
- [ ] Localize export button and share sheet text

## Details

**New File:** `Services/DataExportManager.swift`

**CSV Format:**
```csv
Timestamp,Sensor,X,Y,Z,Unit
2026-05-05T10:30:00Z,Accelerometer,0.12,-0.05,1.02,G
```

**JSON Format:**
```json
{
  "exportDate": "2026-05-05T10:30:00Z",
  "deviceModel": "iPhone17,2",
  "sensors": [
    {
      "name": "Accelerometer",
      "timestamp": "2026-05-05T10:30:00Z",
      "x": 0.12,
      "y": -0.05,
      "z": 1.02,
      "unit": "G"
    }
  ]
}
```

**UI Integration:**
- Share button (square.and.arrow.up icon) on each detail view toolbar
- Dashboard toolbar: "Export All Sensors" button

**Modified Files:**
- All `*DetailView.swift` files (add toolbar button)
- `DashboardView.swift` (add export toolbar button)

## Why This Matters
CSV export is the #1 feature request in competitor reviews. Researchers, students, and drone hobbyists need this. It immediately makes the app "useful" for App Store approval.
