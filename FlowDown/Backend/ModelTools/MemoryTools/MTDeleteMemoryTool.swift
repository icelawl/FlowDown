//
//  MTDeleteMemoryTool.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class MTDeleteMemoryTool: ModelTool {
    override var shortDescription: String {
        "delete a specific memory using its ID"
    }

    override var interfaceName: String {
        String(localized: "Delete Memory")
    }

    override var definition: ChatRequestBody.Tool {
        .function(
            name: "delete_memory",
            description: """
            Deletes a specific memory using its unique ID. Use list_memories first to get the memory ID, then use this tool to remove outdated or incorrect memories.
            """,
            parameters: [
                "type": "object",
                "properties": [
                    "memory_id": [
                        "type": "string",
                        "description": "The unique ID of the memory to delete (obtained from list_memories).",
                    ],
                    "reason": [
                        "type": "string",
                        "description": "Reason for deleting this memory (e.g., 'outdated', 'incorrect', 'no longer relevant').",
                    ],
                ],
                "required": ["memory_id", "reason"],
                "additionalProperties": false,
            ],
            strict: true
        )
    }

    override class var controlObject: ConfigurableObject {
        .init(
            icon: "trash.circle",
            title: String(localized: "Delete Memory"),
            explain: String(localized: "Allows AI to delete specific memories that are no longer needed."),
            key: "wiki.qaq.ModelTools.DeleteMemoryTool.enabled",
            defaultValue: true,
            annotation: .boolean
        )
    }

    override func execute(with input: String, anchorTo _: UIView) async throws -> String {
        guard let data = input.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let memoryId = json["memory_id"] as? String
        else {
            throw NSError(
                domain: "MTDeleteMemoryTool", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: String(localized: "Invalid parameters. memory_id is required."),
                ]
            )
        }

        let reason = json["reason"] as? String
        return await MemoryStore.shared.deleteMemory(id: memoryId, reason: reason)
    }
}
