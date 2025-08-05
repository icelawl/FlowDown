//
//  main.swift
//  FlowDown
//
//  Created by 秋星桥 on 2024/12/31.
//

@_exported import Foundation
@_exported import SnapKit
@_exported import SwifterSwift
@_exported import UIKit

#if !DEBUG
    fclose(stdout)
    fclose(stderr)

    Security.removeDebugger()
    guard Security.validateAppSignature() else {
        Security.crashOut()
    }
#endif

#if os(macOS) || targetEnvironment(macCatalyst)
    #if !DEBUG
        do {
            // 确保在发布版本中启用了沙盒，否则崩溃
            let sandboxTestDir = URL(fileURLWithPath: "/tmp/sandbox.test.\(UUID().uuidString)")
            FileManager.default.createFile(atPath: sandboxTestDir.path, contents: nil, attributes: nil)
            if FileManager.default.fileExists(atPath: sandboxTestDir.path) {
                fatalError("This app should not run outside of sandbox which may cause trouble.")
            }
        }
    #endif
#endif

import ConfigurableKit
import MLX

#if targetEnvironment(simulator) || arch(x86_64)
    ConfigurableKit.set(value: false, forKey: MLX.GPU.isSupportedKey)
    assert(!MLX.GPU.isSupported)
#else
    ConfigurableKit.set(value: true, forKey: MLX.GPU.isSupportedKey)
    assert(MLX.GPU.isSupported)
#endif

import os
import Storage

let sdb = try Storage.db()
let logger = Logger(subsystem: "FlowDown", category: "general")

_ = ModelManager.shared
_ = ModelToolsManager.shared
_ = ConversationManager.shared
_ = MCPService.shared

DispatchQueue.global().async {
    let clean = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("DisposableResources")
    try? FileManager.default.removeItem(at: clean)
}

#if os(macOS) || targetEnvironment(macCatalyst)
    _ = UpdateManager.shared
#endif
_ = UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
