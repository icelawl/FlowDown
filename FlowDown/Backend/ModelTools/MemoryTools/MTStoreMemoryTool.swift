//
//  MTStoreMemoryTool.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class MTStoreMemoryTool: ModelTool {
    override var shortDescription: String {
        "store important information to memory for future conversations"
    }

    override var interfaceName: String {
        String(localized: "Store Memory")
    }

    override var definition: ChatRequestBody.Tool {
        .function(
            name: "store_memory",
            description: """
            Stores important information to memory that can be recalled in future conversations. Use this proactively when the user shares personal preferences, project details, feedback, goals, or other information that would be valuable to remember.

            IMPORTANT: Format memories in third person perspective (e.g., "User is a student" not "I'm a student"). Be specific and clear about what you're storing.
            """,
            parameters: [
                "type": "object",
                "properties": [
                    "content": [
                        "type": "string",
                        "description": "The important information to store in memory. Format in third person (e.g., 'User is a software engineer', 'User prefers detailed explanations'). Be concise but comprehensive.",
                    ],
                ],
                "required": ["content"],
                "additionalProperties": false,
            ],
            strict: true
        )
    }

    override class var controlObject: ConfigurableObject {
        .init(
            icon: "square.and.arrow.down",
            title: String(localized: "Store Memory"),
            explain: String(localized: "Allows AI to store important information for future conversations."),
            key: "wiki.qaq.ModelTools.StoreMemoryTool.enabled",
            defaultValue: true,
            annotation: .boolean
        )
    }

    override func execute(with input: String, anchorTo _: UIView) async throws -> String {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? String
        else {
            throw NSError(
                domain: "MTStoreMemoryTool", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "Invalid memory content"),
                ]
            )
        }

        await MemoryStore.shared.store(content: content)

        return String(localized: "Memory stored successfully: \(content)")
    }
}
