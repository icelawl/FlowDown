//
//  SettingContent.swift
//  FlowDown
//
//  Created by 秋星桥 on 1/24/25.
//

import ConfigurableKit
import UIKit

extension SettingController {
    class SettingContent: StackScrollController {
        let closeButton = ImageCircleButton(name: "xmark", distinctStyle: .border, inset: 8)

        let objects: [ConfigurableObject] = [
            .init(
                icon: "gear",
                title: String(localized: "General"),
                explain: String(localized: "Change the behavior of the application, adjust text sizes, and more."),
                ephemeralAnnotation: .page { GeneralController() }
            ),
            .init(
                icon: "bolt",
                title: String(localized: "Inference"),
                explain: String(localized: "Configure global prompt, adjust parameters when inferencing."),
                ephemeralAnnotation: .page { InferenceController() }
            ),
            .init(
                icon: "doc.text.magnifyingglass",
                title: String(localized: "Model Management"),
                explain: String(localized: "Manage language model providers or download local models."),
                ephemeralAnnotation: .page { ModelController() }
            ),
            .init(
                icon: "hammer",
                title: String(localized: "Tools Configuration"),
                explain: String(localized: "Configure tool settings, choose search engine for internet searches."),
                ephemeralAnnotation: .page { ToolsController() }
            ),
            .init(
                icon: "moon.stars",
                title: String(localized: "Memory Management"),
                explain: String(localized: "Manage AI memory tools and stored conversation memories."),
                ephemeralAnnotation: .page { MemoryController() }
            ),
            .init(
                icon: "lock.shield",
                title: String(localized: "Data Control"),
                explain: String(localized: "Get control of your data, export or delete."),
                ephemeralAnnotation: .page { DataControlController() }
            ),
            .init(
                icon: "key",
                title: String(localized: "Permission List"),
                explain: String(localized: "Manage permissions for the application. Your privacy is important to us."),
                ephemeralAnnotation: .page { PermissionController() }
            ),
            .init(
                icon: "envelope",
                title: String(localized: "Support"),
                explain: String(localized: "Have any questions or just wanna keep in touch? Contact us."),
                ephemeralAnnotation: .page { SupportController() }
            ),
        ]

        init() {
            super.init(nibName: nil, bundle: nil)
            title = String(localized: "Settings")
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .background
            #if targetEnvironment(macCatalyst)
                scrollView.scrollIndicatorInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
            #endif
            navigationController?.setNavigationBarHidden(true, animated: false)
        }

        override func setupContentViews() {
            super.setupContentViews()

            let closeView = UIView()
            closeView.addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.top.right.bottom.equalToSuperview()
                make.width.height.equalTo(32)
            }
            closeButton.actionBlock = { [weak self] in
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }
            stackView.addArrangedSubviewWithMargin(closeView)
            stackView.addArrangedSubviewWithMargin(SettingHeaderView())
            stackView.addArrangedSubview(SeparatorView())

            for object in objects {
                let view = object.createView()
                stackView.addArrangedSubviewWithMargin(view)
                stackView.addArrangedSubview(SeparatorView())
            }

            stackView.addArrangedSubviewWithMargin(SettingFooterView())
            stackView.addArrangedSubviewWithMargin(UIView())
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.setNavigationBarHidden(true, animated: animated)
            scrollView.flashScrollIndicators()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if let nav = navigationController, nav.viewControllers.count > 1 {
                nav.setNavigationBarHidden(false, animated: animated)
            }
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)

            if let entry = SettingController.getNextEntryPage(),
               let controller = entry.controller
            {
                navigationController?.pushViewController(controller, animated: true)
            }

            view.window?.firstResponder()?.resignFirstResponder()
        }
    }
}

extension SettingController.EntryPage {
    var controller: UIViewController? {
        switch self {
        case .general:
            return SettingController.SettingContent.GeneralController()
        case .inference:
            return SettingController.SettingContent.InferenceController()
        case let .chatTemplateEditor(templateIdentifier):
            return ChatTemplateEditorController(templateIdentifier: templateIdentifier)
        case .modelManagement:
            return SettingController.SettingContent.ModelController()
        case .tools:
            return SettingController.SettingContent.ToolsController()
        case .mcp:
            return SettingController.SettingContent.MCPController()
        case .memory:
            return SettingController.SettingContent.MemoryController()
        case .dataControl:
            return SettingController.SettingContent.DataControlController()
        case .permissionList:
            return SettingController.SettingContent.PermissionController()
        case .contactUs:
            return SettingController.SettingContent.SupportController()
        case let .modelEditor(modelIdentifier):
            if let localModel = ModelManager.shared.localModel(identifier: modelIdentifier) {
                return LocalModelEditorController(identifier: localModel.id)
            }
            if let cloudModel = ModelManager.shared.cloudModel(identifier: modelIdentifier) {
                return CloudModelEditorController(identifier: cloudModel.id)
            }
            return nil
        }
    }
}

extension SettingController.SettingContent {
    class SettingHeaderView: UIView {
        let iconImageView = UIImageView().with {
            $0.image = .avatar
            $0.contentMode = .scaleAspectFill
            $0.layer.cornerRadius = 16
            $0.layer.cornerCurve = .continuous
            $0.layerBorderWidth = 1
            $0.layerBorderColor = .systemGray4.withAlphaComponent(0.5)
            $0.clipsToBounds = true
        }

        let label = UILabel().with {
            $0.text = String(localized: "Settings")
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.font = .preferredFont(forTextStyle: .body).bold
            $0.textColor = .label
        }

        let descriptionLabel = UILabel().with {
            $0.text = String(localized: "Change application behavior, manage language model providers, and get control of your data.")
            $0.numberOfLines = 0
            $0.textAlignment = .center
            $0.font = .preferredFont(forTextStyle: .body)
            $0.textColor = .label
        }

        init() {
            super.init(frame: .zero)

            addSubview(iconImageView)
            iconImageView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.width.height.equalTo(64)
                make.centerX.equalToSuperview()
            }

            addSubview(label)
            label.snp.makeConstraints { make in
                make.top.equalTo(iconImageView.snp.bottom).offset(16)
                make.centerX.equalToSuperview()
                make.width.equalToSuperview()
            }

            addSubview(descriptionLabel)
            descriptionLabel.snp.makeConstraints { make in
                make.top.equalTo(label.snp.bottom).offset(8)
                make.centerX.equalToSuperview()
                make.width.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }
    }
}

extension SettingController.SettingContent {
    class SettingFooterView: UIView {
        let versionButton = UIButton(type: .system).with {
            let version = String(AnchorVersion.version)
            let build = String(AnchorVersion.build)
            let text = String(format: String(localized: "Version %@ (%@)"), version, build)
            #if DEBUG
                let finalText = text + " 🐦"
            #else
                let finalText = text
            #endif
            $0.setTitle(finalText, for: .normal)
            $0.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
            $0.setTitleColor(.secondaryLabel, for: .normal)
            $0.contentHorizontalAlignment = .center
        }

        init() {
            super.init(frame: .zero)
            addSubview(versionButton)
            let action = UIAction { _ in
                UpdateManager.shared.anchor(self)
                UpdateManager.shared.performUpdateCheckFromUI()
            }
            versionButton.addAction(action, for: .touchUpInside)

            addSubview(versionButton)
            versionButton.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }
    }
}

extension StackScrollController {
    func setupConfigurableObjectViews(from objects: [ConfigurableObject]) {
        for (idx, object) in objects.enumerated() {
            let view = object.createView()
            stackView.addArrangedSubviewWithMargin(view)
            if idx < objects.count - 1 { stackView.addArrangedSubview(SeparatorView()) }
        }
    }
}
