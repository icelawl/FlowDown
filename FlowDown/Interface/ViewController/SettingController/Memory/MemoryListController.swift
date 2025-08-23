//
//  MemoryListController.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import AlertController
import ConfigurableKit
import Storage
import UIKit

class MemoryListController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let searchController = UISearchController(searchResultsController: nil)
    private var memories: [Memory] = []
    private var filteredMemories: [Memory] = []
    private var isSearching: Bool {
        searchController.isActive && !searchText.isEmpty
    }

    private var searchText: String {
        searchController.searchBar.text ?? ""
    }

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMemories()
    }

    private func setupUI() {
        view.backgroundColor = .background

        // Setup search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = String(localized: "Search memories...")
        searchController.searchBar.searchBarStyle = .minimal
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.preferredSearchBarPlacement = .stacked

        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .background
        tableView.separatorStyle = .singleLine
        tableView.register(MemoryCell.self, forCellReuseIdentifier: MemoryCell.identifier)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadMemories() {
        Task.detached {
            do {
                let loadedMemories = try await MemoryStore.shared.getAllMemoriesAsync()
                await MainActor.run {
                    self.memories = loadedMemories
                    self.filterMemories()
                }
            } catch {
                await MainActor.run {
                    print("[MemoryListController] Failed to load memories: \(error)")
                    self.memories = []
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func searchMemories(query: String) {
        Task.detached {
            do {
                let searchResults = try await MemoryStore.shared.searchMemories(query: query, limit: 50)
                await MainActor.run {
                    self.filteredMemories = searchResults
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    print("[MemoryListController] Failed to search memories: \(error)")
                    self.filteredMemories = []
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func filterMemories() {
        if isSearching {
            searchMemories(query: searchText)
        } else {
            filteredMemories = memories
            tableView.reloadData()
        }
    }

    private func currentMemories() -> [Memory] {
        isSearching ? filteredMemories : memories
    }

    private func deleteMemory(at indexPath: IndexPath) {
        let memory = currentMemories()[indexPath.row]

        Task.detached {
            do {
                try await MemoryStore.shared.deleteMemoryAsync(id: memory.id)
                await MainActor.run {
                    if self.isSearching {
                        self.filteredMemories.remove(at: indexPath.row)
                        if let originalIndex = self.memories.firstIndex(where: { $0.id == memory.id }) {
                            self.memories.remove(at: originalIndex)
                        }
                    } else {
                        self.memories.remove(at: indexPath.row)
                    }
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            } catch {
                await MainActor.run {
                    let errorAlert = AlertViewController(
                        title: String(localized: "Error"),
                        message: String(localized: "Failed to delete memory: \(error.localizedDescription)")
                    ) { context in
                        context.addAction(title: String(localized: "OK"), attribute: .dangerous) {
                            context.dispose()
                        }
                    }
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension MemoryListController: UITableViewDataSource {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        currentMemories().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MemoryCell.identifier, for: indexPath) as! MemoryCell
        let memory = currentMemories()[indexPath.row]
        cell.configure(with: memory)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MemoryListController: UITableViewDelegate {
    func tableView(_: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteMemory(at: indexPath)
        }
    }

    func tableView(_: UITableView, titleForDeleteConfirmationButtonForRowAt _: IndexPath) -> String? {
        String(localized: "Delete")
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menu = UIMenu(options: [.displayInline], children: [
            UIAction(title: String(localized: "Delete Memory"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                self?.deleteMemory(at: indexPath)
            },
        ])
        let cell = tableView.cellForRow(at: indexPath)
        cell?.present(menu: menu)
    }
}

// MARK: - UISearchResultsUpdating

extension MemoryListController: UISearchResultsUpdating {
    func updateSearchResults(for _: UISearchController) {
        filterMemories()
    }
}

// MARK: - MemoryCell

class MemoryCell: UITableViewCell {
    static let identifier = "MemoryCell"

    private let configurableView = ConfigurableActionView(
        responseEverywhere: false,
        actionBlock: { _ in }
    )

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        let margin = AutoLayoutMarginView(configurableView)
        contentView.addSubview(margin)
        margin.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        separatorInset = .zero

        configurableView.configure(icon: UIImage(systemName: "bubbles.and.sparkles") ?? UIImage())
        configurableView.isUserInteractionEnabled = false
    }

    func configure(with memory: Memory) {
        // Use the memory content as title
        configurableView.configure(title: memory.content)

        // Format timestamp for description
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let timestamp = formatter.string(from: memory.timestamp)

        var descriptions: [String] = [timestamp]

        // Add conversation context if available
        if let conversationId = memory.conversationId {
            descriptions.append("Conversation: \(conversationId)")
        }

        configurableView.configure(description: descriptions.joined(separator: " • "))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        preservesSuperviewLayoutMargins = false
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
    }
}
