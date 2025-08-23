//
//  ModelManager+Builtin.swift
//  FlowDown
//
//  Created by 秋星桥 on 4/6/25.
//

import Foundation
import Storage

extension CloudModel {
    enum BuiltinModel: CaseIterable {
        case gemini
        case mistral
        case qwen_coder

        var model: CloudModel {
            switch self {
            case .gemini:
                CloudModel(
                    id: "d26f2641-2802-490c-afcd-5e053460f829",
                    model_identifier: "gemini",
                    endpoint: "https://text.pollinations.ai/openai/v1/chat/completions",
                    context: .medium_64k,
                    capabilities: [.tool, .visual],
                    comment: String(localized: "This model is provided by pollinations.ai free of charge. Rate limit applies."),
                )
            case .mistral:
                CloudModel(
                    id: "78c9c492-ef7c-4504-aa95-04e4ce3a4602",
                    model_identifier: "mistral",
                    endpoint: "https://text.pollinations.ai/openai/v1/chat/completions",
                    context: .medium_64k,
                    capabilities: [.tool, .visual],
                    comment: String(localized: "This model is provided by pollinations.ai free of charge. Rate limit applies."),
                )
            case .qwen_coder:
                CloudModel(
                    id: "349cf3e2-944d-4f9c-84a0-4affdab9d286",
                    model_identifier: "qwen-coder",
                    endpoint: "https://text.pollinations.ai/openai/v1/chat/completions",
                    context: .medium_64k,
                    capabilities: [.tool, .visual],
                    comment: String(localized: "This model is provided by pollinations.ai free of charge. Rate limit applies."),
                )
            }
        }
    }
}
