//
//  ConversationSession+SystemPrompt.swift
//  FlowDown
//
//  Created by 秋星桥 on 3/19/25.
//

import ChatClientKit
import Foundation
import RichEditor

extension ConversationSession {
    func injectNewSystemCommand(
        _ requestMessages: inout [ChatRequestBody.Message],
        _ modelName: String,
        _ modelWillExecuteTools: Bool,
        _ object: RichEditorView.Object
    ) async {
        let sysPrompt = [
            String(localized:
                """
                System is providing you up to date information about current query:

                Model/Your Name: \(modelName)
                Current Date: \(Date().formatted(date: .long, time: .complete))
                Current User Locale: \(Locale.current.identifier)

                Please use up-to-date information and ensure compliance with the previously provided guidelines.
                """
            ),
        ]
        requestMessages.append(.system(content: .text(sysPrompt.joined(separator: "\n"))))

        if case .bool(true) = object.options[.browsing] {
            let sensitivity = ModelManager.shared.searchSensitivity
            requestMessages.append(
                .system(
                    content: .text(
                        """
                        Web Search Mode: \(sensitivity.title)
                        \(sensitivity.briefDescription)
                        """
                    )
                )
            )
        }

        if modelWillExecuteTools {
            var toolGuidance = String(localized:
                """
                The system provides several tools for your convenience. Please use them wisely and according to the user's query. Avoid requesting information that is already provided or easily inferred.
                """
            )

            // Add memory tools guidance if memory tools are enabled
            let memoryToolsEnabled = await ModelToolsManager.shared.getEnabledToolsIncludeMCP().contains { tool in
                tool is MTStoreMemoryTool || tool is MTRecallMemoryTool ||
                    tool is MTListMemoriesTool || tool is MTUpdateMemoryTool ||
                    tool is MTDeleteMemoryTool
            }

            if memoryToolsEnabled {
                toolGuidance += "\n\n" +
                    """
                    Memory Tools Available:

                    STORE MEMORY - Use store_memory proactively to save important user information like:
                    • Personal details: "User is a software engineer", "User prefers dark mode"
                    • Project context: "Working on iOS app called FlowDown", "Using Swift and UIKit"
                    • Preferences: "User likes detailed explanations", "User prefers concise responses"
                    • Goals: "Learning SwiftUI", "Building a chat application"
                    • Important facts: "User's timezone is PST", "User works remotely"

                    FORMAT: Store memories in third person format (e.g., "User is a student" not "I'm a student")
                    WHEN: Immediately when user shares personal info, preferences, or important context

                    RECALL MEMORY - Use recall_memory to get context:
                    • At conversation start to understand user background
                    • When you need context about user preferences or past discussions
                    • Before making recommendations to personalize them

                    MANAGE MEMORY - Use list_memories, update_memory, delete_memory to maintain accuracy:
                    • List memories when you need to update or remove specific information
                    • Update memories when information changes or becomes more specific
                    • Delete memories when information becomes outdated or incorrect

                    Be proactive about memory management to provide personalized, contextually aware assistance. Always format stored information clearly and in third person perspective.
                    """
            }

            requestMessages.append(
                .system(content: .text(toolGuidance))
            )
        }

        requestMessages.append(.user(content: .text(object.text)))
    }

    func moveSystemMessagesToFront(_ requestMessages: inout [ChatRequestBody.Message]) {
        let systemMessage = requestMessages.reduce(
            (content: "", name: String?.none)
        ) { result, message in
            var newContent = result.content + "\n"
            var newName = result.name
            guard case let .system(content, name) = message else {
                return result
            }
            if let name, result.name == nil {
                newName = name
            }
            switch content {
            case let .parts(parts):
                newContent += parts.joined(separator: "\n")
            case let .text(text):
                newContent += text
            }
            return (newContent, newName)
        }
        if !systemMessage.content.isEmpty {
            requestMessages.removeAll {
                guard case .system = $0 else { return false }
                return true
            }
            let message = ChatRequestBody.Message.system(
                content: .text(systemMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)),
                name: systemMessage.name
            )
            requestMessages.insert(message, at: 0)
        }
    }
}
