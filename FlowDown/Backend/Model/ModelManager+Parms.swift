//
//  ModelManager+Parms.swift
//  FlowDown
//
//  Created by 秋星桥 on 2/2/25.
//

import AlertController
import ConfigurableKit
import Foundation
import Storage
import UIKit

extension ModelContextLength {
    var title: String {
        let template = switch self {
        case .short_4k, .short_8k:
            NSLocalizedString("Short", comment: "Model Context")
        case .medium_16k, .medium_32k, .medium_64k:
            NSLocalizedString("Medium", comment: "Model Context")
        case .long_100k, .long_200k:
            NSLocalizedString("Long", comment: "Model Context")
        case .huge_1m:
            NSLocalizedString("Huge", comment: "Model Context")
        case .infinity:
            NSLocalizedString("Infinity", comment: "Model Context")
        }
        if self == .infinity { return template }
        if rawValue >= 1_000_000 {
            return [template, String(format: "%.0fM", Double(rawValue) / 1_000_000)].joined(separator: " ")
        } else if rawValue >= 1000 {
            return [template, String(format: "%.0fk", Double(rawValue) / 1000)].joined(separator: " ")
        }
        return [template, String(rawValue)].joined(separator: " ")
    }

    var icon: String {
        switch self {
        case .short_4k, .short_8k:
            "text.quote"
        case .medium_16k, .medium_32k, .medium_64k:
            "book"
        case .long_100k, .long_200k:
            "text.book.closed"
        case .huge_1m:
            "books.vertical"
        case .infinity:
            "sparkles"
        }
    }
}

extension ModelManager {
    static let defaultPromptConfigurableObject: ConfigurableObject = .init(
        icon: "text.quote",
        title: String(localized: "Default Prompt"),
        explain: String(localized: "The default prompt shapes the model’s responses. We provide presets with common instructions and information to enhance performance. A more detailed prompt can improve results but may increase costs. Please notice that system prompt is decided when creating new conversation, and will not be updated afterwards."),
        key: "CONFKIT.Model.Inference.Prompt.Default",
        defaultValue: PromptType.complete.rawValue,
        annotation: .list {
            PromptType.allCases.map { .init(
                icon: $0.icon,
                title: $0.title,
                rawValue: $0.rawValue
            ) }
        }
    )

    static let extraPromptConfigurableObject: ConfigurableObject = .init(
        icon: "text.append",
        title: String(localized: "Additional Prompt"),
        explain: String(localized: "The additional prompt will be appended to the default prompt. You can make requests here, such as language preferences, response formats, etc."),
        ephemeralAnnotation: TextEditorAnnotation { view in
            assert(view.parentViewController?.navigationController != nil)
            let controller = TextEditorContentController()
            controller.title = String(localized: "Additional Prompt")
            controller.text = ModelManager.shared.additionalPrompt
            controller.callback = { text in
                ModelManager.shared.additionalPrompt = text
            }
            view.parentViewController?.navigationController?.pushViewController(controller, animated: true)
        }
    )

    static let temperatureConfigurableObject: ConfigurableObject = .init(
        icon: "sparkles",
        title: String(localized: "Imagination"),
        explain: String(localized: "This parameter can be used to control the personality of the model. The more imaginative, the more unstable the output. This parameter is also known as temperature."),
        key: "CONFKIT.Model.Inference.Temperature",
        defaultValue: 0.75,
        annotation: .list {
            [
                .init(
                    icon: "snowflake",
                    title: String(localized: "Freezing @ 0.0"),
                    rawValue: 0.1
                ),
                .init(
                    icon: "thermometer.low",
                    title: String(localized: "Precise @ 0.25"),
                    rawValue: 0.25
                ),
                .init(
                    icon: "thermometer.low",
                    title: String(localized: "Stable @ 0.5"),
                    rawValue: 0.5
                ),
                .init(
                    icon: "thermometer.medium",
                    title: String(localized: "Humankind @ 0.75"),
                    rawValue: 0.75
                ),
                .init(
                    icon: "thermometer.medium",
                    title: String(localized: "Creative @ 1.0"),
                    rawValue: 1
                ),
                .init(
                    icon: "thermometer.high",
                    title: String(localized: "Imaginative @ 1.5"),
                    rawValue: 1.5
                ),
                .init(
                    icon: "thermometer.high",
                    title: String(localized: "Magical @ 2.0"),
                    rawValue: 2.0
                ),
            ]
        }
    )
}

extension ModelManager {
    enum SearchSensitivity: String, CaseIterable, Codable {
        case essential
        case balanced
        case proactive

        var title: String {
            switch self {
            case .essential:
                NSLocalizedString("Essential", comment: "Search Strategy")
            case .balanced:
                NSLocalizedString("Balanced", comment: "Search Strategy")
            case .proactive:
                NSLocalizedString("Proactive", comment: "Search Strategy")
            }
        }

        var icon: String {
            switch self {
            case .essential:
                "bolt"
            case .balanced:
                "magnifyingglass"
            case .proactive:
                "book"
            }
        }

        var briefDescription: String {
            switch self {
            case .essential:
                "Avoid web searches unless absolutely necessary for time-sensitive or highly uncertain information where your internal knowledge is likely incorrect. Prioritize speed, but not at the cost of severe inaccuracy."
            case .balanced:
                "You MUST perform a web search for topics like politics, current events, weather, sports, scientific developments, cultural trends, or any other dynamic topic. Err on the side of searching if you are even remotely uncertain that your knowledge is complete and up-to-date."
            case .proactive:
                "You MUST conduct a research-level web search to ensure comprehensive and up-to-date coverage, even for topics where you have some existing knowledge, unless the user explicitly asks you not to browse."
            }
        }

        var promptTemplate: String {
            let base = """
            You are an expert at deciding when to use a web search to answer a user's query. Ensure your information is accurate and up-to-date.

            Context to consider:
            1. User's current question/request
            2. Previous conversation history
            3. Attached documents/files
            4. Current date and time (for time-sensitive queries)

            Instructions:
            - Decide if a web search is required.
            - If required, generate 1–3 simple, clear search queries in the user's language.
            - Respond with valid XML indicating search_required and listing queries.
            """

            return """
            \(base)

            Current Search Mode: \(title)
            \(briefDescription)

            Respond with XML like:
            <output>
            <search_required>true</search_required>
            <queries>
            <query>example search query</query>
            </queries>
            </output>

            If no search is needed:
            <output>
            <search_required>false</search_required>
            <queries></queries>
            </output>
            """
        }
    }

    static let searchSensitivityConfigurableObject: ConfigurableObject = .init(
        icon: "list.bullet.clipboard",
        title: String(localized: "Search Strategy"),
        explain: String(localized: "Adjust how aggressively web searches are triggered."),
        key: "Model.Inference.SearchSensitivity",
        defaultValue: SearchSensitivity.balanced.rawValue,
        annotation: .list {
            SearchSensitivity.allCases.map {
                .init(icon: $0.icon, title: $0.title, rawValue: $0.rawValue)
            }
        }
    )
}

extension ModelManager {
    enum PromptType: String, CaseIterable, Codable {
        case none
        case minimal
        case complete

        var title: String {
            switch self {
            case .none: String(localized: "None")
            case .minimal: NSLocalizedString("Minimal", comment: "Prompt Type")
            case .complete: String(localized: "Complete")
            }
        }

        var icon: String {
            switch self {
            case .none: "viewfinder"
            case .minimal: "text.viewfinder"
            case .complete: "text.badge.star"
            }
        }
    }
}

class TextEditorAnnotation: ConfigurableObject.AnnotationProtocol {
    let onEdit: (ConfigurableInfoView) -> Void
    init(onEdit: @escaping (ConfigurableInfoView) -> Void) {
        self.onEdit = onEdit
    }

    func createView(fromObject _: ConfigurableObject) -> ConfigurableView {
        let view = ConfigurableInfoView()
        view.configure(value: String(localized: "Edit"))
        view.setTapBlock(onEdit)
        return view
    }
}

extension ModelManager.PromptType {
    func createPrompt() -> String {
        let template = switch self {
        case .none:
            ""
        case .minimal:
            ###"""
            You are an assistant in {{Template.applicationName}}. Chat was created at {{Template.currentDateTime}}.
            User is using system locale {{Template.systemLanguage}}, app locale {{Template.appLanguage}}.
            Your knowledge was last updated several years ago, covering events up until that time. Provide brief answers for simple questions, and detailed responses for complex or open-ended ones.
            Respond in the user’s native language unless otherwise instructed (e.g., for translation tasks). Continue in the original language of the conversation.
            The user/system may attach documents to the conversation. Please review them alongside the user’s query to provide an answer.
            MUST CITE document with [^Index] and DO NOT CITE document without an index.
            When presenting content in a list, task list, or numbered list, avoid nesting code blocks or tables. Code blocks and tables in Markdown syntax should only appear at the root level. For complex answers, organise with headings ## / ### and separate sections using ---; use lists, **bold**, and _italics_ as needed. Never use tildes unless you genuinely need ~strikethrough~. Use LaTeX for all math: \\( ... \\) for inline math like \\( E=mc^2 \\), and \\[ ... \\] for display math. Multi-line equations are supported. You understand that Markdown may escape your symbols, in that case, add \ prior to the symbol to escape it. Eg: \( will be output as \\\(, ~ will need \~. Otherwise it will be parsed accordingly.
            If tools are enabled, first provide a response to the user, then use it. Avoid mentioning tool's function name unless directly relevant to the user’s query. Avoid asking for confirmation between each step of multi-stage user requests, unless for ambiguous requests.
            Avoid mentioning your knowledge limits unless directly relevant to the user’s query.
            """###
            .replacingOccurrences(
                of: "{{Template.applicationName}}",
                with: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown AI app"
            )
            .replacingOccurrences(
                of: "{{Template.currentDateTime}}",
                with: DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .full)
            )
            .replacingOccurrences(
                of: "{{Template.systemLanguage}}",
                with: Locale.current.identifier
            )
            .replacingOccurrences(
                of: "{{Template.appLanguage}}",
                with: Bundle.main.preferredLocalizations.first ?? "en"
            )
        case .complete:
            ###"""
            You are an assistant in {{Template.applicationName}}. Chat was created at {{Template.currentDateTime}}.
            User is using system locale {{Template.systemLanguage}}, app locale {{Template.appLanguage}}.
            Your knowledge was last updated several years ago and covers events prior to that time. Provide brief answers for simple questions, and detailed responses for more complex ones. You cannot open URLs, links, or videos—if expected to do so, clarify and ask the user to paste the relevant content directly, unless tools are provided with relevant features.
            Over the course of the conversation, you adapt to the user’s tone and preference. Try to match the user’s vibe, tone, and generally how they are speaking. You want the conversation to feel natural. You engage in authentic conversation by responding to the information provided, asking relevant questions, and showing genuine curiosity. If natural, continue the conversation with casual conversation.
            When assisting with tasks that involve views held by many people, you help express those views even if you personally disagree, but provide a broader perspective afterward. Avoid stereotyping, including negative stereotyping of majority groups. For controversial topics, offer careful, objective information without downplaying harmful content or implying both sides are equally reasonable.
            If asked about obscure topics with rare information, remind the user that you may hallucinate in such cases, using the term “hallucinate” for clarity. Do not add this caveat when the information is likely to be found online multiple times.
            You can help with writing, analysis, math, coding (in markdown), and other tasks, and will reply in the user’s most likely native language (e.g., responding in Chinese if the user uses Chinese). For tasks like rewriting or optimization, continue in the original language of the text. For complex answers, organise with headings ## / ### and separate sections using ---; use lists, **bold**, and _italics_ as needed. Never use tildes unless you genuinely need ~strikethrough~. You understand that markdown may escape your symbols, in that case, add \ prior to the symbol to escape it. Eg: \( will be output as \\\(, ~ will need \~. Otherwise it will be parsed accordingly.
            For all mathematical content (including multi-line equations), you must consistently use LaTeX formatting to ensure clarity and proper rendering. For inline mathematics that flows within a sentence, enclose the expression in \\( ... \\), for example, \\( E=mc^2 \\). For standalone, display-style equations that should be centered on their own line, use \\[ ... \\], such as \\[ \int_{a}^{b} f(x) \,dx = F(b) - F(a) \\].
            When presenting content in a list, task list, or numbered list, avoid nesting code blocks or tables. Code blocks and tables in Markdown syntax should only appear at the root level.
            The user/system may attach documents to the conversation. Please review them alongside the user’s query to provide an answer. Cite them in the output using following syntax for the user to verify: [^Index]. If there are multiple documents, cite them in order. eg: [^1, 2]. Do not cite document without an index.
            If tools are enabled, first provide a response to the user, then use the tool(s). After that, end the conversation and wait for system actions. Avoid mentioning tool's function name unless directly relevant to the user’s query, instead, use a generic term like "tool". Avoid asking for confirmation between each step of multi-stage user requests. However, for ambiguous requests, you may ask for clarification (but do so sparingly). You shall not explicitly repeat the raw response from tools to the user, and you must not thank the user for providing their location.
            Avoid mentioning your capabilities unless directly relevant to the user’s query.
            """###
        }
        return template
            .replacingOccurrences(
                of: "{{Template.applicationName}}",
                with: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "unknown AI app"
            )
            .replacingOccurrences(
                of: "{{Template.currentDateTime}}",
                with: DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .full)
            )
            .replacingOccurrences(
                of: "{{Template.systemLanguage}}",
                with: Locale.current.identifier
            )
            .replacingOccurrences(
                of: "{{Template.appLanguage}}",
                with: Bundle.main.preferredLocalizations.first ?? "en"
            )
    }
}
