//
//  MTRecallMemoryTool.swift
//  FlowDown
//
//  Created by Alan Ye on 8/14/25.
//

import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class MTRecallMemoryTool: ModelTool {
    override var shortDescription: String {
        "recall stored memories to provide context for the conversation"
    }

    override var interfaceName: String {
        String(localized: "Recall Memory")
    }

    override var definition: ChatRequestBody.Tool {
        .function(
            name: "recall_memory",
            description: """
            Retrieves all stored memories to provide context for the current conversation. Use this at the beginning of conversations or when you need to remember user preferences, project details, or other stored information.
            """,
            parameters: [
                "type": "object",
                "properties": [:],
                "additionalProperties": false,
            ],
            strict: true
        )
    }

    override class var controlObject: ConfigurableObject {
        .init(
            icon: "square.and.arrow.up",
            title: String(localized: "Recall Memory"),
            explain: String(localized: "Allows AI to retrieve stored memories for context."),
            key: "wiki.qaq.ModelTools.RecallMemoryTool.enabled",
            defaultValue: true,
            annotation: .boolean
        )
    }

    override func execute(with _: String, anchorTo _: UIView) async throws -> String {
        await MemoryStore.shared.getAllMemories()
    }
}
