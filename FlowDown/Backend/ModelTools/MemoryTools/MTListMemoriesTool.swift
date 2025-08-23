//
//  MTListMemoriesTool.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class MTListMemoriesTool: ModelTool {
    override var shortDescription: String {
        "list stored memories with their IDs for update/delete operations"
    }

    override var interfaceName: String {
        String(localized: "List Memories")
    }

    override var definition: ChatRequestBody.Tool {
        .function(
            name: "list_memories",
            description: """
            Lists stored memories with their unique IDs. Use this when you need to update or delete specific memories, as the IDs are required for those operations.
            """,
            parameters: [
                "type": "object",
                "properties": [
                    "limit": [
                        "type": "number",
                        "description": "Maximum number of memories to retrieve (default: 20, max: 100).",
                    ],
                ],
                "required": ["limit"],
                "additionalProperties": false,
            ],
            strict: true
        )
    }

    override class var controlObject: ConfigurableObject {
        .init(
            icon: "list.bullet.clipboard",
            title: String(localized: "List Memories"),
            explain: String(localized: "Allows AI to list memories with IDs for management operations."),
            key: "wiki.qaq.ModelTools.ListMemoriesTool.enabled",
            defaultValue: true,
            annotation: .boolean
        )
    }

    override func execute(with input: String, anchorTo _: UIView) async throws -> String {
        var limit = 20

        if let data = input.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let limitValue = json["limit"] as? Int
        {
            limit = min(max(limitValue, 1), 100) // Ensure between 1 and 100
        }

        return await MemoryStore.shared.listMemoriesWithIds(limit: limit)
    }
}
