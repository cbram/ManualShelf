//
//  RenameFileAlert.swift
//  ManualShelf
//

import SwiftUI

/// Alert with a text field for renaming a file; the extension is shown but not editable.
private struct RenameFileAlert: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var name: String
    let fileExtension: String
    let onRename: () -> Void

    func body(content: Content) -> some View {
        content.alert("Rename File", isPresented: $isPresented) {
            TextField("Name", text: $name)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {}
            Button("Rename", action: onRename)
        } message: {
            if !fileExtension.isEmpty {
                Text("The extension .\(fileExtension) is kept.")
            }
        }
    }
}

extension View {
    func renameFileAlert(isPresented: Binding<Bool>, name: Binding<String>, fileExtension: String,
                         onRename: @escaping () -> Void) -> some View {
        modifier(RenameFileAlert(isPresented: isPresented, name: name, fileExtension: fileExtension, onRename: onRename))
    }
}
