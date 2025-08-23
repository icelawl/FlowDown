//
//  MTUpdateMemoryTool.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class MTUpdateMemoryTool: ModelTool {
    override var shortDescription: String {
        "update existing memory content using its ID"
    }

    override var interfaceName: String {
        String(localized: "Update Memory")
    }

    override var definition: ChatRequestBody.Tool {
        .function(
            name: "update_memory",
            description: """
            Updates an existing memory with new content. Use list_memories first to get the memory ID, then use this tool to update the content when information changes or becomes more specific.

            IMPORTANT: Format updated memories in third person perspective (e.g., "User is a senior software engineer" not "I'm a senior software engineer").
            """,
            parameters: [
                "type": "object",
                "properties": [
                    "memory_id": [
                        "type": "string",
                        "description": "The unique ID of the memory to update (obtained from list_memories).",
                    ],
                    "new_content": [
                        "type": "string",
                        "description": "The new content to replace the existing memory content. Format in third person perspective.",
                    ],
                ],
                "required": ["memory_id", "new_content"],
                "additionalProperties": false,
            ],
            strict: true
        )
    }

    override class var controlObject: ConfigurableObject {
        .init(
            icon: "pencil.circle",
            title: String(localized: "Update Memory"),
            explain: String(localized: "Allows AI to update existing memory content."),
            key: "wiki.qaq.ModelTools.UpdateMemoryTool.enabled",
            defaultValue: true,
            annotation: .boolean
        )
    }

    override func execute(with input: String, anchorTo _: UIView) async throws -> String {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let memoryId = json["memory_id"] as? String,
              let newContent = json["new_content"] as? String
        else {
            throw NSError(
                domain: "MTUpdateMemoryTool", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "Invalid parameters. Both memory_id and new_content are required."),
                ]
            )
        }

        return await MemoryStore.shared.updateMemory(id: memoryId, newContent: newContent)
    }
}
