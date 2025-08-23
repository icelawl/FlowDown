//
//  ModelToolsManager.swift
//  FlowDown
//
//  Created by 秋星桥 on 2/27/25.
//

import AlertController
import ChatClientKit
import ConfigurableKit
import Foundation
import UIKit

class ModelToolsManager {
    static let shared = ModelToolsManager()

    let tools: [ModelTool]

    static let skipConfirmationKey = "ModelToolsManager.skipConfirmation"
    static var skipConfirmationValue: Bool {
        get { UserDefaults.standard.bool(forKey: ModelToolsManager.skipConfirmationKey) }
        set { UserDefaults.standard.set(newValue, forKey: ModelToolsManager.skipConfirmationKey) }
    }

    static var skipConfirmation: ConfigurableToggleActionView {
        .init().with {
            $0.actionBlock = { skipConfirmationValue = $0 }
            $0.configure(icon: UIImage(systemName: "hammer"))
            $0.configure(title: String(localized: "Skip Tool Confirmation"))
            $0.configure(description: String(localized: "Skip the confirmation dialog when executing tools."))
            $0.boolValue = skipConfirmationValue
        }
    }

    private init() {
        #if targetEnvironment(macCatalyst)
            tools = [
                MTWaitForNextRound(),

                MTAddCalendarTool(),
                MTQueryCalendarTool(),

                MTWebScraperTool(),
                MTWebSearchTool(),

//            MTLocationTool(),

                MTURLTool(),

                MTStoreMemoryTool(),
                MTRecallMemoryTool(),
                MTListMemoriesTool(),
                MTUpdateMemoryTool(),
                MTDeleteMemoryTool(),
            ]
        #else
            tools = [
                MTWaitForNextRound(),

                MTAddCalendarTool(),
                MTQueryCalendarTool(),

                MTWebScraperTool(),
                MTWebSearchTool(),

                MTLocationTool(),

                MTURLTool(),

                MTStoreMemoryTool(),
                MTRecallMemoryTool(),
                MTListMemoriesTool(),
                MTUpdateMemoryTool(),
                MTDeleteMemoryTool(),
            ]
        #endif

        #if DEBUG
            var registeredToolNames: Set<String> = []
        #endif

        for tool in tools {
            print("[*] registering tool: \(tool.functionName)")
            #if DEBUG
                assert(registeredToolNames.insert(tool.functionName).inserted)
            #endif
            if tool is MTWaitForNextRound { continue }
        }
    }

    var enabledTools: [ModelTool] {
        tools.filter { tool in
            if tool is MTWaitForNextRound { return true }
            if tool is MTWebSearchTool { return true }
            return tool.isEnabled
        }
    }

    func getEnabledToolsIncludeMCP() async -> [ModelTool] {
        var result = enabledTools
        let mcpTools = await MCPService.shared.listServerTools()
        result.append(contentsOf: mcpTools.filter(\.isEnabled))
        return result
    }

    var configurableTools: [ModelTool] {
        tools.filter { tool in
            if tool is MTWaitForNextRound { return false }
            if tool is MTWebSearchTool { return false }
            if tool is MTStoreMemoryTool { return false }
            if tool is MTRecallMemoryTool { return false }
            if tool is MTListMemoriesTool { return false }
            if tool is MTUpdateMemoryTool { return false }
            if tool is MTDeleteMemoryTool { return false }
            return true
        }
    }

    func tool(for request: ToolCallRequest) -> ModelTool? {
        print("[*] finding tool call with function name \(request.name)")
        return enabledTools.first {
            $0.functionName.lowercased() == request.name.lowercased()
        }
    }

    func findTool(for request: ToolCallRequest) async -> ModelTool? {
        print("[*] finding tool call with function name \(request.name)")
        let allTools = await getEnabledToolsIncludeMCP()
        return allTools.first {
            $0.functionName.lowercased() == request.name.lowercased()
        }
    }

    func perform(withTool tool: ModelTool, parms: String, anchorTo view: UIView) -> Result<String, Error> {
        assert(!Thread.isMainThread)

        var ans = String(localized: "Execute tool call timed out")
        var success = false
        let sem = DispatchSemaphore(value: 0)

        let execution = {
            do {
                ans = try await tool.execute(with: parms, anchorTo: view)
                success = true
            } catch {
                ans = String(localized: "Tool execution failed: \(error.localizedDescription)")
            }
            sem.signal()
        }

        if Self.skipConfirmationValue {
            Task.detached { await execution() }
            sem.wait()
        } else {
            DispatchQueue.main.async {
                let setupContext: (ActionContext) -> Void = { context in
                    context.addAction(title: String(localized: "Cancel")) {
                        context.dispose {
                            sem.signal()
                        }
                    }
                    context.addAction(title: String(localized: "Use Tool"), attribute: .dangerous) {
                        context.dispose {
                            Task.detached { await execution() }
                        }
                    }
                }

                let alert = if let tool = tool as? MCPTool {
                    AlertViewController(
                        title: String(localized: "Execute MCP Tool"),
                        message: String(localized: "The model wants to execute '\(tool.toolInfo.name)' from \(tool.toolInfo.serverName). This tool can access external resources.\n\nDescription: \(tool.toolInfo.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No description available")"),
                        setupActions: setupContext
                    )
                } else {
                    AlertViewController(
                        title: String(localized: "Tool Call"),
                        message: String(localized: "Your model is calling a tool: \(tool.interfaceName)"),
                        setupActions: setupContext
                    )
                }
                view.parentViewController?.present(alert, animated: true)
            }
            sem.wait()
        }

        if success {
            return .success(ans)
        } else {
            return .failure(NSError(domain: "ToolCall", code: 500, userInfo: [
                NSLocalizedDescriptionKey: ans,
            ]))
        }
    }
}
