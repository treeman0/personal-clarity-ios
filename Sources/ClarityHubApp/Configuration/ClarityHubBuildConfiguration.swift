enum ClarityHubBuildMode: String, Equatable {
    case cloud
    case local
}

enum ClarityHubBuildConfiguration {
    static let mode: ClarityHubBuildMode = {
        #if CLARITYHUB_LOCAL
        return .local
        #else
        return .cloud
        #endif
    }()

    static let defaultStoreName: String = {
        switch mode {
        case .cloud:
            return "ClarityHub"
        case .local:
            return "ClarityHubLocal"
        }
    }()

    static let cloudKitSync: ClarityHubModelContainerFactory.CloudKitSync = {
        switch mode {
        case .cloud:
            return .productionPrivate
        case .local:
            return .disabled
        }
    }()

    static let storageTitle: String = {
        switch mode {
        case .cloud:
            return "Private iCloud"
        case .local:
            return "On this iPhone"
        }
    }()

    static let storageDetail: String = {
        switch mode {
        case .cloud:
            return "CloudKit sync enabled"
        case .local:
            return "Local storage, no iCloud sync"
        }
    }()

    static let storageSystemImage: String = {
        switch mode {
        case .cloud:
            return "icloud"
        case .local:
            return "iphone"
        }
    }()
}
