# ManualShelf 📚

Eine moderne iOS/iPadOS/macOS App zum Sammeln und Verwalten von Bedienungsanleitungen im PDF-Format.

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
- iOS 15.0+
- iPadOS 15.0+
- macOS 12.0+

### Dateiformat
- 📄 **PDF**: Ausschließliche Unterstützung für PDF-Dateien

## 🚀 Installation

### Voraussetzungen
- Xcode 14.0 oder neuer
- iOS 15.0+ / iPadOS 15.0+ / macOS 12.0+

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
   - Wählen Sie Ihr Zielgerät (iPhone, iPad oder Mac)
   - Drücken Sie `Cmd + R` zum Starten

## 📖 Verwendung

### Manual hinzufügen
1. Öffnen Sie die ManualShelf App
2. Tippen Sie auf das **+** Symbol oben rechts
3. Geben Sie einen Titel für das Manual ein
4. Wählen Sie "PDF-Datei auswählen" und navigieren Sie zu Ihrer PDF
5. Tippen Sie auf "Manual hinzufügen"

### Manual ansehen
1. Tippen Sie auf ein Manual in der Liste
2. Das PDF öffnet sich im Vollbild-Modus
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
│   ├── PDFViewerView.swift           # PDF-Betrachter
│   ├── Persistence.swift            # Core Data Stack
│   └── ManualShelf.xcdatamodeld/     # Core Data Modell
├── ManualShelfTests/                 # Unit Tests
├── ManualShelfUITests/               # UI Tests
└── README.md                         # Diese Datei
```

## 🎨 Core Data Modell

### Manual Entität
- **title**: String - Titel des Manuals
- **fileName**: String - Ursprünglicher Dateiname
- **dateAdded**: Date - Hinzufügungsdatum
- **fileData**: Binary Data - PDF-Inhalt (extern gespeichert)

## 🔮 Geplante Features

- [ ] Kategorien für bessere Organisation
- [ ] Suchfunktion
- [ ] Favoriten-System
- [ ] Export-Funktionen
- [ ] OCR-Texterkennung für Suchindizierung
- [ ] iCloud-Synchronisation

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