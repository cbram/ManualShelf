# ManualShelf 📚

Eine moderne iOS/iPadOS-App (auf dem Mac als „Designed for iPad“) zum Sammeln und Verwalten von Bedienungsanleitungen als PDF, JPG oder PNG.

## 🎯 Über das Projekt

ManualShelf ist eine benutzerfreundliche App, die es ermöglicht, alle wichtigen Bedienungsanleitungen an einem zentralen Ort zu sammeln und zu organisieren. Egal ob für Haushaltsgeräte, Elektronik oder andere Produkte - mit ManualShelf haben Sie alle Manuals immer griffbereit.

## ✨ Features

### 📱 Hauptfunktionen
- **📋 Übersichtliche Liste**: Alle gespeicherten Manuals in einer sortierten Liste
- **➕ Einfaches Hinzufügen**: PDFs, JPGs und PNGs direkt über den integrierten Dokumentenauswähler hinzufügen
- **🏷️ Tag-System**: Manuals und Dateien können mit Tags versehen, gefiltert und nachträglich bearbeitet werden
- **🎨 Barrierefreies Color Coding**: Tags werden farbenblindenfreundlich und kontrastreich dargestellt
- **🔍 Filter & Suche**: Manuals können nach Titel, Dateiname und Tags gefiltert werden
- **📖 Vollbild-PDF- und Bild-Viewer**: Manuals in voller Größe betrachten mit:
  - 🔍 Zoom-Funktionen (0.25x - 5x)
  - 📜 Natürliches Scrollen
  - 👆 Touch-optimierte Bedienung
  - 🔄 Bildrotation und freies Verschieben für Bilder

### 🎨 Benutzeroberfläche
- **🌟 Modernes Design**: Folgt den iOS Design Guidelines
- **📱 Universell**: Optimiert für iPhone, iPad und Mac
- **🇩🇪 Deutsche Sprache**: Vollständig lokalisiert
- **🌓 Dark Mode**: Unterstützt helle und dunkle Darstellung
- **♿ Barrierefreie UX**: Farbenblindenfreundliche Darstellung, hohe Kontraste

### 💾 Datenverwaltung
- **🔒 Sicher**: Lokale Speicherung mit Core Data
- **☁️ iCloud-Synchronisation**: Automatischer Abgleich über die private iCloud-Datenbank (CloudKit) zwischen iPhone, iPad und Mac, sobald ein iCloud-Konto angemeldet ist; abschaltbar in den Einstellungen des Geräts unter iCloud
- **🗂 Organisiert**: Automatische Sortierung nach Hinzufügungsdatum
- **🗑 Aufräumen**: Einfaches Löschen nicht mehr benötigter Manuals
- **🧹 Unbenutzte Tags werden automatisch entfernt**

## 🛠 Technische Details

### Architektur
- **SwiftUI**: Moderne deklarative UI-Entwicklung
- **Core Data**: Robuste lokale Datenspeicherung
- **PDFKit**: Native PDF-Darstellung und -Interaktion
- **Document Picker**: Systemintegration für Dateiauswahl

### Unterstützte Plattformen
- iOS 17.0+
- iPadOS 17.0+
- macOS: nur als „Designed for iPad“ auf Macs mit Apple-Chip

### Dateiformate
- 📄 **PDF**
- 🖼 **JPG** und **PNG**

## 🚀 Installation

### Voraussetzungen
- Xcode 27 oder neuer
- iOS 17.0+ / iPadOS 17.0+ / Mac mit Apple-Chip („Designed for iPad“)

### Schritte
1. **Repository klonen**:
   ```bash
   git clone https://github.com/cbram/ManualShelf.git
   cd ManualShelf
   ```

2. **Xcode öffnen**:
   ```bash
   open ManualShelf.xcodeproj
   ```

3. **Build und Run**:
   - Wählen Sie Ihr Zielgerät (iPhone, iPad oder „My Mac (Designed for iPad)“)
   - Drücken Sie `Cmd + R` zum Starten

## 📖 Verwendung

### Manual hinzufügen
1. Öffnen Sie die ManualShelf App
2. Tippen Sie auf das **+** Symbol oben rechts
3. Geben Sie einen Titel für das Manual ein
4. Wählen Sie „Weitere Datei hinzufügen…“ und wählen Sie eine oder mehrere PDF-, JPG- oder PNG-Dateien
5. Tippen Sie auf „Manual speichern“

### Manual ansehen
1. Tippen Sie auf ein Manual in der Liste
2. Die Datei (PDF oder Bild) öffnet sich im Vollbild-Modus
3. Verwenden Sie Pinch-to-Zoom für Vergrößerung/Verkleinerung
4. Scrollen Sie durch die Seiten

### Manual löschen
1. Wischen Sie nach links auf einem Manual in der Liste
2. Tippen Sie auf "Löschen"
3. Oder verwenden Sie den "Bearbeiten"-Button für Mehrfachauswahl

## 📁 Projektstruktur

```
ManualShelf/
├── ManualShelf/
│   ├── ManualShelfApp.swift          # Haupt-App-Datei
│   ├── ManualsListView.swift         # Hauptansicht mit Manual-Liste
│   ├── AddManualView.swift           # View zum Hinzufügen neuer Manuals
│   ├── ManualDisplayView.swift       # PDF- und Bild-Betrachter
│   ├── Persistence.swift             # Core Data Stack (NSPersistentCloudKitContainer)
│   ├── CloudKitSyncManager.swift     # iCloud-Sync-Status
│   └── ManualShelf.xcdatamodeld/     # Core Data Modell
├── ManualShelfTests/                 # Unit Tests
├── ManualShelfUITests/               # UI Tests
└── README.md                         # Diese Datei
```

## 🎨 Core Data Modell

Das Modell ist für CloudKit eingerichtet (`usedWithCloudKit`), alle Attribute und Beziehungen sind optional.

### Manual
- **title**: String – Titel des Manuals
- **dateAdded**: Date – Hinzufügungsdatum
- **files**: to-many → ManualFile (Löschregel Nullify)

### ManualFile
- **fileName**: String – ursprünglicher Dateiname
- **fileType**: String – Dateiendung des Typs, z. B. `pdf`, `jpeg`, `png`
- **fileData**: Binary Data – Dateiinhalt (in der Datenbank, nicht als externe Datei)
- **dateAdded**: Date – Hinzufügungsdatum
- **imageRotationDegrees**: Integer 16 – Drehung für Bilder (Standard 0)
- **pdfRotationDegrees**: Integer 16 – Drehung für PDFs (Standard 0)
- **manual**: to-one → Manual
- **manualTags**: to-many → ManualTag

### ManualTag
- **name**: String – Name des Tags
- **color**: String – Farbe des Tags
- **manuals**: to-many → ManualFile (Tags hängen an Dateien, nicht direkt am Manual)

## 🔮 Geplante Features

Geplante Funktionen werden als [offene Issues](https://github.com/cbram/ManualShelf/issues?q=is%3Aissue+is%3Aopen) gepflegt.

## 🤝 Beitragen

Beiträge sind willkommen! Bitte:

1. Forken Sie das Repository
2. Erstellen Sie einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Committen Sie Ihre Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Pushen Sie zum Branch (`git push origin feature/AmazingFeature`)
5. Öffnen Sie einen Pull Request

## 📄 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe [LICENSE](LICENSE) für weitere Details.

## 👨‍💻 Autor

**Christian Bram**
- GitHub: [@cbram](https://github.com/cbram)

## 🙏 Danksagungen

- Apple für SwiftUI und PDFKit
- Die iOS-Entwicklergemeinschaft für Inspiration und Best Practices

---

*Erstellt mit ❤️ und SwiftUI* 