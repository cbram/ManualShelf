# ManualShelf 📚

A modern iOS/iPadOS app (on the Mac as "Designed for iPad") for collecting and managing user manuals as PDF, JPG or PNG.

## 🎯 About

ManualShelf keeps all your important user manuals in one place. Whether for household appliances, electronics or anything else, your manuals are always at hand.

## ✨ Features

### 📱 Main features
- **📋 Clear list**: All saved manuals in a sorted list
- **➕ Easy adding**: Add PDFs, JPGs and PNGs from the document picker or load them from an https address (up to 50 MB); the first file's name is suggested as title
- **🖼 Thumbnails**: Preview images of the files in the list and in the manual view
- **📤 Sharing**: Share a single file or all files of a manual through the system share sheet
- **🏷️ Tags**: Tag manuals and files, filter by tags and edit them later
- **🎨 Accessible colour coding**: Tags use colour-blind-safe, high-contrast colours
- **🔍 Filter & search**: Filter manuals by title, file name and tags
- **📖 Full-screen PDF and image viewer** with:
  - 🔍 Zoom (0.25x – 5x)
  - 📜 Natural scrolling
  - 👆 Touch-optimised controls
  - 🔄 Rotation and free panning for images

### 🎨 User interface
- **🌟 Modern design**: Follows the iOS design guidelines
- **📱 Universal**: Optimised for iPhone, iPad and Mac
- **🌍 Languages**: English and German
- **🌓 Dark Mode**: Light and dark appearance
- **♿ Accessible**: Colour-blind-safe colours, high contrast, VoiceOver labels

### 💾 Data
- **🔒 Local storage** with Core Data
- **☁️ iCloud sync**: Automatic sync through the private iCloud database (CloudKit) between iPhone, iPad and Mac as soon as an iCloud account is signed in; can be turned off in the device's iCloud settings
- **🗂 Organised**: Sorted by date added by default
- **🗑 Clean-up**: Delete manuals you no longer need
- **🧹 Unused tags are removed automatically**

## 🛠 Technical details

### Architecture
- **SwiftUI**: Declarative UI
- **Core Data**: Local data storage
- **PDFKit**: Native PDF display and interaction
- **Document Picker**: System file picker

### Supported platforms
- iOS 17.0+
- iPadOS 17.0+
- macOS: only as "Designed for iPad" on Macs with Apple silicon

### File formats
- 📄 **PDF**
- 🖼 **JPG** and **PNG**

## 🚀 Installation

### Requirements
- Xcode 27 or later
- iOS 17.0+ / iPadOS 17.0+ / Mac with Apple silicon ("Designed for iPad")

### Steps
1. **Clone the repository**:
   ```bash
   git clone https://github.com/cbram/ManualShelf.git
   cd ManualShelf
   ```

2. **Open in Xcode**:
   ```bash
   open ManualShelf.xcodeproj
   ```

3. **Build and run**:
   - Choose your target device (iPhone, iPad or "My Mac (Designed for iPad)")
   - Press `Cmd + R`

## 📖 Usage

### Add a manual
1. Open ManualShelf
2. Tap the **+** button at the top right
3. Enter a title for the manual
4. Choose "Add another file..." and pick one or more PDF, JPG or PNG files, or "Load from URL..." and enter an https address
5. Tap "Save Manual"

### View a manual
1. Tap a manual in the list
2. The file (PDF or image) opens full screen
3. Pinch to zoom in or out
4. Scroll through the pages

### Delete a manual
1. Swipe left on a manual in the list
2. Tap "Delete"
3. Or use the "Edit" button to select several

## 📁 Project structure

```
ManualShelf/
├── ManualShelf/
│   ├── ManualShelfApp.swift          # App entry point
│   ├── ManualsListView.swift         # Main view with the list of manuals
│   ├── AddManualView.swift           # View for adding new manuals
│   ├── ManualDisplayView.swift       # PDF and image viewer
│   ├── Persistence.swift             # Core Data stack (NSPersistentCloudKitContainer)
│   ├── CloudKitSyncManager.swift     # iCloud sync status
│   ├── Localizable.xcstrings         # UI texts (English, German)
│   └── ManualShelf.xcdatamodeld/     # Core Data model
├── ManualShelfTests/                 # Unit tests
├── ManualShelfUITests/               # UI tests
└── README.md                         # This file
```

## 🎨 Core Data model

The model is set up for CloudKit (`usedWithCloudKit`); all attributes and relationships are optional.

### Manual
- **title**: String – title of the manual
- **dateAdded**: Date – date added
- **files**: to-many → ManualFile (delete rule Nullify)

### ManualFile
- **fileName**: String – original file name
- **fileType**: String – file extension of the type, e.g. `pdf`, `jpeg`, `png`
- **fileData**: Binary Data – file content (stored in the database, not as an external file)
- **dateAdded**: Date – date added
- **imageRotationDegrees**: Integer 16 – rotation for images (default 0)
- **pdfRotationDegrees**: Integer 16 – rotation for PDFs (default 0)
- **manual**: to-one → Manual
- **manualTags**: to-many → ManualTag

### ManualTag
- **name**: String – tag name
- **color**: String – tag colour
- **manuals**: to-many → ManualFile (tags belong to files, not directly to the manual)

## 🔮 Planned features

Planned features are tracked as [open issues](https://github.com/cbram/ManualShelf/issues?q=is%3Aissue+is%3Aopen).

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push the branch (`git push origin feature/AmazingFeature`)
5. Open a pull request

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## 👨‍💻 Author

**Christian Bram**
- GitHub: [@cbram](https://github.com/cbram)

## 🙏 Acknowledgements

- Apple for SwiftUI and PDFKit
- The iOS developer community for inspiration and best practices

---

*Made with ❤️ and SwiftUI*
