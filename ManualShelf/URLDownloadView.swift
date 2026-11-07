//
//  URLDownloadView.swift
//  ManualShelf
//

import SwiftUI
import UniformTypeIdentifiers

/// Sheet for loading a manual file from a web address (issue 8).
struct URLDownloadView: View {
    let onDownloaded: (Data, String, UTType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addressText = ""
    @State private var downloadTask: Task<Void, Never>?
    @State private var errorMessage: String?

    private var isDownloading: Bool { downloadTask != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/manual.pdf", text: $addressText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isDownloading)
                        .onSubmit(startDownload)
                } footer: {
                    Text("PDF, JPEG or PNG, up to \(URLDownload.maximumSizeInMegabytes) MB.")
                }
                if isDownloading {
                    Section {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Downloading...")
                        }
                    }
                }
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    }
                }
            }
            .navigationTitle("Load from URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        downloadTask?.cancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Load", action: startDownload)
                        .disabled(isDownloading || addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func startDownload() {
        guard !isDownloading else { return }
        errorMessage = nil
        downloadTask = Task {
            do {
                let url = try URLDownload.validatedURL(from: addressText)
                let (data, fileName, type) = try await URLDownload.download(from: url)
                onDownloaded(data, fileName, type)
                dismiss()
            } catch is CancellationError {
                // Cancelled by the user; nothing to report
            } catch {
                errorMessage = error.localizedDescription
            }
            downloadTask = nil
        }
    }
}
