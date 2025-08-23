//
//  SettingContent+Memory.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import AlertController
import ConfigurableKit
import Foundation
import Storage
import UIKit

extension SettingController.SettingContent {
    class MemoryController: StackScrollController {
        init() {
            super.init(nibName: nil, bundle: nil)
            title = String(localized: "Memory Management")
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .background
        }

        override func setupContentViews() {
            super.setupContentViews()
            stackView.addArrangedSubview(SeparatorView())

            // Memory Tools Section
            stackView.addArrangedSubviewWithMargin(
                ConfigurableSectionHeaderView().with(
                    header: String(localized: "Memory Tools")
                )
            ) { $0.bottom /= 2 }
            stackView.addArrangedSubview(SeparatorView())

            // Add memory tool controls
            let memoryTools = ModelToolsManager.shared.tools.filter { tool in
                false
                    || tool is MTStoreMemoryTool
                    || tool is MTRecallMemoryTool
                    || tool is MTListMemoriesTool
                    || tool is MTUpdateMemoryTool
                    || tool is MTDeleteMemoryTool
            }

            for tool in memoryTools {
                stackView.addArrangedSubviewWithMargin(tool.createConfigurableObjectView())
                stackView.addArrangedSubview(SeparatorView())
            }

            stackView.addArrangedSubviewWithMargin(
                ConfigurableSectionFooterView().with(
                    footer: String(localized: "These tools allow the AI to store, recall, and manage important information from conversations for better context awareness.")
                )
            ) { $0.top /= 2 }
            stackView.addArrangedSubview(SeparatorView())

            // Data Management Section
            stackView.addArrangedSubviewWithMargin(
                ConfigurableSectionHeaderView().with(
                    header: String(localized: "Data Management")
                )
            ) { $0.bottom /= 2 }
            stackView.addArrangedSubview(SeparatorView())

            // View All Memories
            let viewMemories = ConfigurableObject(
                icon: "waveform.path.ecg",
                title: String(localized: "Memory List"),
                explain: String(localized: "Browse, search, and manage stored memories."),
                ephemeralAnnotation: .page { MemoryListController() }
            ).createView()
            stackView.addArrangedSubviewWithMargin(viewMemories)
            stackView.addArrangedSubview(SeparatorView())

            // Export Memories
            let exportMemories = ConfigurableObject(
                icon: "square.and.arrow.up",
                title: String(localized: "Export Memories"),
                explain: String(localized: "Export all memories as JSON file."),
                ephemeralAnnotation: .action { controller in
                    guard let controller else { return }
                    Task {
                        await self.exportMemories(from: controller)
                    }
                }
            ).createView()
            stackView.addArrangedSubviewWithMargin(exportMemories)
            stackView.addArrangedSubview(SeparatorView())

            // Clear All Memories
            let clearMemories = ConfigurableObject(
                icon: "trash",
                title: String(localized: "Clear All Memories"),
                explain: String(localized: "Delete all stored memories permanently."),
                ephemeralAnnotation: .action { controller in
                    guard let controller else { return }
                    Task {
                        await self.clearAllMemories(from: controller)
                    }
                }
            ).createView()
            stackView.addArrangedSubviewWithMargin(clearMemories)
            stackView.addArrangedSubview(SeparatorView())

            stackView.addArrangedSubviewWithMargin(
                ConfigurableSectionFooterView().with(
                    footer: String(localized: "All memory data is stored locally on your device. Export operations allow you to backup your memory data.")
                )
            ) { $0.top /= 2 }
            stackView.addArrangedSubview(SeparatorView())
        }

        @MainActor
        private func exportMemories(from controller: UIViewController) async {
            do {
                let memories = try await MemoryStore.shared.getAllMemoriesAsync()

                guard !memories.isEmpty else {
                    let alert = AlertViewController(
                        title: String(localized: "No Memories"),
                        message: String(localized: "There are no memories to export.")
                    ) { context in
                        context.addAction(title: String(localized: "OK"), attribute: .dangerous) {
                            context.dispose()
                        }
                    }
                    controller.present(alert, animated: true)
                    return
                }

                let memoryData = memories.map { memory -> [String: Any] in
                    [
                        "id": memory.id,
                        "content": memory.content,
                        "timestamp": ISO8601DateFormatter().string(from: memory.timestamp),
                        "conversationId": memory.conversationId as Any,
                    ]
                }

                let jsonData = try JSONSerialization.data(withJSONObject: memoryData, options: .prettyPrinted)

                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "memories_\(ISO8601DateFormatter().string(from: Date())).json"
                let fileURL = tempDir.appendingPathComponent(fileName)

                try jsonData.write(to: fileURL)

                #if targetEnvironment(macCatalyst)
                    let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
                    documentPicker.title = String(localized: "Export Memories")
                    documentPicker.modalPresentationStyle = .formSheet
                    controller.present(documentPicker, animated: true)
                #else
                    let share = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )
                    share.popoverPresentationController?.sourceView = controller.view
                    share.popoverPresentationController?.sourceRect = controller.view.bounds
                    share.completionWithItemsHandler = { _, _, _, _ in
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                    controller.present(share, animated: true)
                #endif
            } catch {
                let alert = AlertViewController(
                    title: String(localized: "Export Failed"),
                    message: String(localized: "Failed to export memories: \(error.localizedDescription)")
                ) { context in
                    context.addAction(title: String(localized: "OK"), attribute: .dangerous) {
                        context.dispose()
                    }
                }
                controller.present(alert, animated: true)
            }
        }

        @MainActor
        private func clearAllMemories(from controller: UIViewController) async {
            let alert = AlertViewController(
                title: String(localized: "Clear All Memories"),
                message: String(localized: "Are you sure you want to delete all stored memories? This action cannot be undone.")
            ) { context in
                context.addAction(title: String(localized: "Cancel")) {
                    context.dispose()
                }
                context.addAction(title: String(localized: "Clear All"), attribute: .dangerous) {
                    context.dispose {
                        Task {
                            do {
                                try await MemoryStore.shared.deleteAllMemoriesAsync()
                                await MainActor.run {
                                    Indicator.present(
                                        title: String(localized: "Memories Cleared"),
                                        referencingView: controller.view
                                    )
                                }
                            } catch {
                                await MainActor.run {
                                    let errorAlert = AlertViewController(
                                        title: String(localized: "Error"),
                                        message: String(localized: "Failed to clear memories: \(error.localizedDescription)")
                                    ) { context in
                                        context.addAction(title: String(localized: "OK"), attribute: .dangerous) {
                                            context.dispose()
                                        }
                                    }
                                    controller.present(errorAlert, animated: true)
                                }
                            }
                        }
                    }
                }
            }
            controller.present(alert, animated: true)
        }
    }
}
