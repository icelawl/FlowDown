//
//  ModelController+Delegates.swift
//  FlowDown
//
//  Created by 秋星桥 on 1/27/25.
//

import AlertController
import Foundation
import Storage
import UIKit

extension SettingController.SettingContent.ModelController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else {
            return
        }
        switch itemIdentifier.type {
        case .local:
            let controller = LocalModelEditorController(identifier: itemIdentifier.identifier)
            navigationController?.pushViewController(controller, animated: true)
        case .cloud:
            let controller = CloudModelEditorController(identifier: itemIdentifier.identifier)
            navigationController?.pushViewController(controller, animated: true)
        }
    }

    func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        let delete = UIContextualAction(
            style: .destructive,
            title: String(localized: "Delete")
        ) { _, _, completion in
            switch itemIdentifier.type {
            case .local:
                ModelManager.shared.removeLocalModel(identifier: itemIdentifier.identifier)
            case .cloud:
                ModelManager.shared.removeCloudModel(identifier: itemIdentifier.identifier)
            }
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }
        var actions: [UIMenuElement] = []

        switch itemIdentifier.type {
        case .local: break
        case .cloud:
            actions.append(UIAction(
                title: String(localized: "Export Model"),
                image: UIImage(systemName: "square.and.arrow.up")
            ) { _ in
                self.exportModel(itemIdentifier)
            })
            actions.append(UIAction(
                title: String(localized: "Duplicate"),
                image: UIImage(systemName: "doc.on.doc")
            ) { _ in
                switch itemIdentifier.type {
                case .local:
                    preconditionFailure()
                case .cloud:
                    guard let model = ModelManager.shared.cloudModel(identifier: itemIdentifier.identifier) else {
                        return
                    }
                    model.id = UUID().uuidString
                    ModelManager.shared.insertCloudModel(model)
                }
            })
        }
        actions.append(UIAction(
            title: String(localized: "Delete"),
            image: UIImage(systemName: "trash"),
            attributes: .destructive
        ) { _ in
            switch itemIdentifier.type {
            case .local:
                ModelManager.shared.removeLocalModel(identifier: itemIdentifier.identifier)
            case .cloud:
                ModelManager.shared.removeCloudModel(identifier: itemIdentifier.identifier)
            }
        })
        #if targetEnvironment(macCatalyst)
            let cell = tableView.cellForRow(at: indexPath)
            let point = tableView.convert(point, to: cell)
            cell?.present(menu: .init(children: actions), anchorPoint: point)
            return nil
        #else
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                .init(children: actions)
            }
        #endif
    }
}

extension SettingController.SettingContent.ModelController: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_: UISearchBar, textDidChange _: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(commitSearch), object: nil)
        perform(#selector(commitSearch), with: nil, afterDelay: 0.25)
    }

    @objc func commitSearch() {
        updateDataSource()
    }
}

extension SettingController.SettingContent.ModelController: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DisposableResources")
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        for url in urls {
            _ = url.startAccessingSecurityScopedResource()
        }
        ModelManager.shared.importModels(at: urls, controller: self)
    }
}

extension SettingController.SettingContent.ModelController: UITableViewDragDelegate {
    func tableView(_: UITableView, itemsForBeginning _: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let itemIdentifier = dataSource.itemIdentifier(for: indexPath),
              itemIdentifier.type == .cloud,
              let model = ModelManager.shared.cloudModel(identifier: itemIdentifier.identifier)
        else { return [] }

        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let plistData = try encoder.encode(model)
            let fileName = "Export-\(model.modelDisplayName.sanitizedFileName)\(model.auxiliaryIdentifier).fdmodel"
            let itemProvider = NSItemProvider(item: plistData as NSSecureCoding, typeIdentifier: "wiki.qaq.fdmodel")
            itemProvider.suggestedName = fileName
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = model
            return [dragItem]
        } catch {
            print("[-] failed to encode model: \(error)")
            return []
        }
    }
}

extension SettingController.SettingContent.ModelController {
    func exportModel(_ itemIdentifier: ModelViewModel) {
        guard itemIdentifier.type == .cloud,
              let model = ModelManager.shared.cloudModel(identifier: itemIdentifier.identifier) else { return }

        let tempFileDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DisposableResources")
            .appendingPathComponent(UUID().uuidString)
        let modelName = model.modelDisplayName
        let tempFile = tempFileDir
            .appendingPathComponent("Export-\(modelName.sanitizedFileName)")
            .appendingPathExtension("fdmodel")
        try? FileManager.default.createDirectory(at: tempFileDir, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: tempFile.path, contents: nil)

        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(model)
            try data.write(to: tempFile, options: .atomic)

            let exporter = FileExporterHelper()
            exporter.targetFileURL = tempFile
            exporter.referencedView = view
            exporter.deleteAfterComplete = true
            exporter.exportTitle = String(localized: "Export Model")
            exporter.completion = {
                try? FileManager.default.removeItem(at: tempFileDir)
            }
            exporter.execute(presentingViewController: self)
        } catch {
            print("[-] failed to export model: \(error)")
        }
    }
}
