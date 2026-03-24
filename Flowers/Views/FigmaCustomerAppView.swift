//
//  FigmaCustomerAppView.swift
//  Flowers
//
//  Created by Codex on 2026/3/18.
//

import SwiftUI
import Combine

struct FigmaCustomerAppView: View {
    @StateObject private var appModel = FigmaCustomerAppModel()

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            switch appModel.authState {
            case .welcome:
                WelcomeScreen(appModel: appModel)
            case .emailLogin:
                EmailLoginScreen(appModel: appModel)
            case .main:
                MainFlowScreen(appModel: appModel)
            }
        }
        .alert(
            appModel.authErrorTitle,
            isPresented: Binding(
                get: { appModel.authErrorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        appModel.dismissAuthError()
                    }
                }
            )
        ) {
            Button("知道了", role: .cancel) {
                appModel.dismissAuthError()
            }
        } message: {
            Text(appModel.authErrorMessage ?? "")
        }
    }
}

@MainActor
final class FigmaCustomerAppModel: ObservableObject {
    enum AuthState {
        case welcome
        case emailLogin
        case main
    }

    enum AuthEntryMode {
        case login
        case register

        var formTitle: String {
            switch self {
            case .login:
                return "登入你的帳戶"
            case .register:
                return "建立新帳戶"
            }
        }

        var descriptionText: String {
            switch self {
            case .login:
                return "使用 Firebase 帳戶登入，訂單與花園資料都會綁定到你的帳號。"
            case .register:
                return "註冊後會建立 Firebase Auth 帳戶，並在 Firestore 的 users 集合寫入你的用戶資料。"
            }
        }

        var primaryActionTitle: String {
            switch self {
            case .login:
                return "登入"
            case .register:
                return "註冊並開始使用"
            }
        }

        var loadingTitle: String {
            switch self {
            case .login:
                return "登入中..."
            case .register:
                return "註冊中..."
            }
        }

        var secondaryPrompt: String {
            switch self {
            case .login:
                return "還沒有帳戶？"
            case .register:
                return "已經有帳戶？"
            }
        }

        var secondaryActionTitle: String {
            switch self {
            case .login:
                return "立即註冊"
            case .register:
                return "返回登入"
            }
        }
    }

    enum MainTab: CaseIterable {
        case browse
        case assistant
        case home
        case cart
        case profile

        var symbolName: String {
            switch self {
            case .browse:
                return "leaf"
            case .assistant:
                return "ellipsis.message"
            case .home:
                return "house.fill"
            case .cart:
                return "cart"
            case .profile:
                return "person.crop.circle"
            }
        }

        var selectedColor: Color {
            switch self {
            case .browse:
                return Color(red: 0.07, green: 0.30, blue: 0.26)
            case .assistant:
                return Color(red: 0.25, green: 0.21, blue: 0.38)
            case .home:
                return .black
            case .cart:
                return .black
            case .profile:
                return .black
            }
        }
    }

    enum BrowseMode {
        case materials
        case bouquets
    }

    enum OverlayScreen {
        case productDetail
        case assistantJourney
        case farm
        case checkout
        case orderTracking
        case orderHistory
        case editProfile
        case notifications
    }

    enum AssistantFlowStage: Equatable {
        case chat
        case diy(DIYStep)
        case preview
    }

    @Published var authState: AuthState = .welcome
    @Published var authEntryMode: AuthEntryMode = .login
    @Published var activeTab: MainTab = .home
    @Published var overlayScreen: OverlayScreen?
    @Published var email = ""
    @Published var password = ""
    @Published var selectedProduct = BouquetProduct.defaultSelection
    @Published private var featuredBouquetIndex = 0
    @Published var cartItems: [CartItem] = []
    @Published var browseMode: BrowseMode = .materials
    @Published var selectedFlowerCategory: FlowerCategory?
    @Published var selectedPurchaseType = "花束"
    @Published var selectedRecipient = "朋友"
    @Published var selectedOccasion = "生日"
    @Published var selectedColor = "粉色"
    @Published var selectedBudget = "港幣100-200元"
    @Published var availableFlowers: [Flower] = []
    @Published var availableBouquetProducts: [BouquetProduct] = []
    @Published var availableWrappingOptions: [BouquetWrappingOption] = []
    @Published var assistantFlowStage: AssistantFlowStage = .chat
    @Published var selectedDIYFlowerCategory: FlowerCategory = .tulip
    @Published var selectedFlowerQuantities: [String: Int] = [:]
    @Published var selectedWrappingOptionID: String?
    @Published var includeGreetingCard = true
    @Published var cardMessage = ""
    @Published var selectedBlessingTemplateID: String?
    @Published var generatedPreview: AIGeneratedPreview?
    @Published var previewErrorMessage: String?
    @Published var isGeneratingPreview = false
    @Published var showPreviewDisclaimer = false
    @Published var apiKey = ProcessInfo.processInfo.environment["ARK_API_KEY"] ?? ""
    @Published var modelName = ProcessInfo.processInfo.environment["ARK_IMAGE_MODEL"] ?? "doubao-seedream-5-0-250428"
    @Published var assistantAPIKey = ProcessInfo.processInfo.environment["ARK_API_KEY"] ?? ""
    @Published var assistantModelName = ProcessInfo.processInfo.environment["ARK_CHAT_MODEL"] ?? "doubao-seed-2-0-mini-260215"
    @Published var assistantComposerText = ""
    @Published var assistantMessages: [StorefrontAssistantMessage] = []
    @Published var assistantConversationStep = 1
    @Published var assistantErrorMessage: String?
    @Published var isSendingAssistantMessage = false
    @Published var assistantRecommendationText: String?
    @Published var isGeneratingAssistantRecommendation = false
    @Published var selectedPaymentMethod: CheckoutPaymentMethod = .alipayHK
    @Published var isShowingCheckoutPriceDetails = false
    @Published var isSubmittingPayment = false
    @Published var isAuthenticating = false
    @Published var paymentErrorMessage: String?
    @Published var submittedTrackingOrder: StorefrontTrackingOrder?
    @Published var authErrorTitle = "操作失敗"
    @Published var authErrorMessage: String?
    @Published private(set) var userOrders: [OrderData] = []
    @Published private(set) var isLoadingUserOrders = false
    @Published private(set) var userOrdersErrorMessage: String?
    @Published private(set) var cancellingOrderID: String?
    @Published var profileRecord: UserProfileRecord?
    @Published var isLoadingProfile = false
    @Published var isSavingProfile = false
    @Published var profileSaveErrorMessage: String?
    @Published var profileDraftName = ""
    @Published var profileDraftEmail = ""
    @Published var profileDraftPhone = ""
    @Published private var restockReminderTargets: [RestockReminderTarget] = []
    @Published private(set) var unreadRestockReminderKeys: Set<String> = []
    @Published private(set) var notificationMessages: [StorefrontNotificationMessage] = []

    private let flowerService = FlowerService()
    private let bouquetService = BouquetService()
    private let previewService = AIBouquetPreviewService()
    private let assistantService = StorefrontAIChatService()
    private let storefrontConfigService = StorefrontConfigService()
    private let orderService = OrderService()
    private let reminderTargetsStorageKey = "storefront.restockReminderTargets"
    private let unreadReminderStorageKey = "storefront.unreadRestockReminderKeys"
    private let reminderAvailabilityStorageKey = "storefront.restockReminderAvailability"
    private let notificationMessagesStorageKey = "storefront.notificationMessages"
    private var cancellables = Set<AnyCancellable>()
    private var liveBouquetCatalog: [BouquetData] = []
    private var inventoryStocksByCode: [String: Int] = [:]
    private var lastKnownReminderAvailabilityByKey: [String: Bool] = [:]
    private var hasResolvedRemoteFlowers = false
    private var hasResolvedRemoteBouquets = false
    private var hasResolvedInventory = false
    private var hasResolvedRemoteWrappingOptions = false
    private var remoteFlowerCount = 0

    init() {
        resetAssistantChat()
        loadPersistedRestockReminderState()
        setupFlowerBindings()
        setupBouquetBindings()
        setupInventoryBindings()
        setupPreviewConfigurationBindings()
        setupWrappingBindings()
        setupOrderBindings()
        setupAuthBindings()
        bouquetService.fetchCatalogBouquets()
        storefrontConfigService.startListening()

        if FirebaseManager.shared.hasAuthenticatedUser {
            authState = .main
            activeTab = .home
            email = FirebaseManager.shared.authenticatedEmail ?? ""
            refreshUserOrders()
            loadCurrentUserProfile()
        }
    }

    var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSubmitAuthForm: Bool {
        canLogin && !isAuthenticating
    }

    var recommendedBouquet: BouquetProduct {
        selectedProduct
    }

    var profileDisplayName: String {
        let storedDisplayName = profileRecord?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !storedDisplayName.isEmpty {
            return storedDisplayName
        }

        if let email = FirebaseManager.shared.authenticatedEmail,
           let userName = email.split(separator: "@").first,
           !userName.isEmpty {
            return String(userName)
        }

        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if let userName = typedEmail.split(separator: "@").first,
           !userName.isEmpty {
            return String(userName)
        }

        return FirebaseManager.shared.hasAuthenticatedUser ? "花店顧客" : "訪客"
    }

    var profileEmailText: String {
        let storedEmail = profileRecord?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !storedEmail.isEmpty {
            return storedEmail
        }

        if let authenticatedEmail = FirebaseManager.shared.authenticatedEmail,
           !authenticatedEmail.isEmpty {
            return authenticatedEmail
        }

        let typedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return typedEmail.isEmpty ? "訪客模式" : typedEmail
    }

    var profilePhoneText: String {
        let storedPhoneNumber = profileRecord?.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !storedPhoneNumber.isEmpty {
            return storedPhoneNumber
        }

        if let phoneNumber = FirebaseManager.shared.authenticatedPhoneNumber,
           !phoneNumber.isEmpty {
            return phoneNumber
        }

        return FirebaseManager.shared.hasAuthenticatedUser ? "未設定" : "訪客模式"
    }

    var canSaveProfileChanges: Bool {
        FirebaseManager.shared.hasAuthenticatedUser
            && !isSavingProfile
            && !profileDraftEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var featuredBouquetProduct: BouquetProduct? {
        guard !availableBouquetProducts.isEmpty else { return nil }
        let safeIndex = max(0, featuredBouquetIndex) % availableBouquetProducts.count
        return availableBouquetProducts[safeIndex]
    }
    
    var promotionalBouquetProduct: BouquetProduct? {
        availableBouquetProducts.dropFirst().first ?? featuredBouquetProduct
    }

    var filteredFlowers: [Flower] {
        let flowers = availableFlowers
        guard let selectedFlowerCategory else { return flowers }
        return flowers.filter { $0.category == selectedFlowerCategory }
    }

    var isLoadingFlowerCatalog: Bool {
        !hasResolvedRemoteFlowers && availableFlowers.isEmpty
    }

    var flowerCatalogStateMessage: String? {
        if isLoadingFlowerCatalog {
            return "正在從 Firestore 載入真實花材資料..."
        }

        if availableFlowers.isEmpty {
            return "Firestore 的 flowers 暫時沒有可展示的花材。"
        }

        if filteredFlowers.isEmpty {
            return "這個分類暫時沒有可選花材。"
        }

        return nil
    }

    var assistantCanSendMessage: Bool {
        !assistantComposerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSendingAssistantMessage
    }

    var assistantDataStatusText: String {
        var lines: [String] = []

        if hasResolvedRemoteFlowers {
            lines.append("花材 \(availableFlowers.count) 款")
        } else {
            lines.append("花材載入中")
        }

        if hasResolvedRemoteBouquets {
            lines.append("花束 \(availableBouquetProducts.count) 款")
        } else {
            lines.append("花束載入中")
        }

        if hasResolvedRemoteWrappingOptions {
            lines.append("包裝 \(availableWrappingOptions.count) 款")
        } else {
            lines.append("包裝載入中")
        }

        return lines.joined(separator: " · ")
    }

    var cartTotalPrice: Double {
        cartItems.reduce(0) { partial, item in
            partial + unitPrice(for: item.product) * Double(item.quantity)
        }
    }

    var cartTotalPriceText: String {
        "HKD \(Int(cartTotalPrice.rounded()))"
    }

    var hasUnreadRestockAlerts: Bool {
        unreadNotificationCount > 0
    }

    var unreadNotificationCount: Int {
        notificationMessages.filter(\.isUnread).count
    }

    var diyFlowerCategories: [FlowerCategory] {
        FlowerCategory.allCases.filter { category in
            availableFlowers.contains(where: { $0.category == category })
        }
    }

    var diyFlowers: [Flower] {
        availableFlowers
            .filter { $0.category == selectedDIYFlowerCategory }
            .sorted { lhs, rhs in
                if lhs.price == rhs.price {
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
                return lhs.price < rhs.price
            }
    }

    var selectedDIYFlowers: [SelectedFlowerLine] {
        availableFlowers.compactMap { flower in
            let quantity = selectedFlowerQuantities[flower.id, default: 0]
            guard quantity > 0 else { return nil }
            return SelectedFlowerLine(flower: flower, quantity: quantity)
        }
    }

    var selectedWrappingOption: BouquetWrappingOption? {
        availableWrappingOptions.first(where: { $0.id == selectedWrappingOptionID })
    }

    var selectedFlowerStemCount: Int {
        selectedFlowerQuantities.values.reduce(0, +)
    }

    var selectedFlowerSubtotal: Double {
        selectedDIYFlowers.reduce(0) { partial, line in
            partial + line.subtotal
        }
    }

    var greetingCardFee: Double {
        includeGreetingCard ? 28 : 0
    }

    var wrappingFee: Double {
        selectedWrappingOption?.price ?? 0
    }

    var arrangementFee: Double {
        selectedDIYFlowers.isEmpty ? 0 : 50
    }

    var diyTotalPrice: Double {
        selectedFlowerSubtotal + greetingCardFee + wrappingFee + arrangementFee
    }

    var recommendedFlowerTypes: [String] {
        let recipient = selectedRecipient
        let occasion = selectedOccasion
        let color = selectedColor

        if occasion.contains("畢業") {
            if color.contains("黃") {
                return ["向日葵", "白滿天星", "尤加利葉"]
            }
            if color.contains("粉") {
                return ["向日葵", "粉郁金香", "粉滿天星"]
            }
            return ["向日葵", "白滿天星", "尤加利葉"]
        }

        if occasion.contains("紀念") || recipient.contains("伴侶") {
            if color.contains("紅") {
                return ["紅玫瑰", "紅郁金香", "白滿天星"]
            }
            if color.contains("白") || color.contains("綠") {
                return ["白玫瑰", "白百合", "尤加利葉"]
            }
            return ["粉玫瑰", "粉郁金香", "粉滿天星"]
        }

        if recipient.contains("家人") || occasion.contains("感謝") {
            if color.contains("白") || color.contains("綠") {
                return ["白百合", "白滿天星", "尤加利葉"]
            }
            return ["粉康乃馨", "粉百合", "尤加利葉"]
        }

        if color.contains("藍") {
            return ["藍繡球", "白滿天星", "尤加利葉"]
        }
        if color.contains("紅") {
            return ["紅玫瑰", "白百合", "尤加利葉"]
        }
        if color.contains("白") || color.contains("綠") {
            return ["白玫瑰", "白百合", "尤加利葉"]
        }
        if color.contains("黃") {
            return ["向日葵", "香檳玫瑰", "尤加利葉"]
        }

        return ["粉玫瑰", "粉百合", "粉滿天星"]
    }

    var suggestedDesignText: String {
        switch selectedPurchaseType {
        case "單枝花":
            return "以 \(selectedColor) 為主調的單枝花禮，適合送給 \(selectedRecipient) 作為 \(selectedOccasion) 心意。"
        case "自訂":
            return "為 \(selectedRecipient) 客製一款 \(selectedColor) 主調的 \(selectedOccasion) 花禮，層次感會更突出。"
        default:
            return "推薦一束送給 \(selectedRecipient) 的 \(selectedColor) \(selectedOccasion) 花束，整體包裝走精緻柔和路線。"
        }
    }

    var estimatedPriceText: String {
        switch (selectedPurchaseType, selectedBudget) {
        case ("單枝花", "小於港幣100元"):
            return "約 HKD 68-98"
        case ("單枝花", "港幣100-200元"):
            return "約 HKD 128-168"
        case ("單枝花", "港幣200-300元"):
            return "約 HKD 188-228"
        case ("單枝花", _):
            return "約 HKD 320+"
        case ("自訂", "小於港幣100元"):
            return "約 HKD 108"
        case ("自訂", "港幣100-200元"):
            return "約 HKD 188-218"
        case ("自訂", "港幣200-300元"):
            return "約 HKD 268-298"
        case ("自訂", _):
            return "約 HKD 398+"
        case (_, "小於港幣100元"):
            return "約 HKD 98"
        case (_, "港幣100-200元"):
            return "約 HKD 168-198"
        case (_, "港幣200-300元"):
            return "約 HKD 238-288"
        default:
            return "約 HKD 368+"
        }
    }

    var diyAssistantSummaryText: String {
        let trimmedRecommendation = assistantRecommendationText?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedRecommendation, !trimmedRecommendation.isEmpty {
            return trimmedRecommendation
        }

        return suggestedDesignText
    }

    var diyAssistantSummaryDetail: String? {
        let trimmedRecommendation = assistantRecommendationText?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedRecommendation, !trimmedRecommendation.isEmpty {
            return nil
        }

        return "建議花材：\(recommendedFlowerTypes.joined(separator: "、"))"
    }

    var customBouquetHeadline: String {
        if selectedOccasion.contains("畢業") {
            return "畢業祝賀花束"
        }
        if selectedOccasion.contains("生日") {
            return "生日心意花束"
        }
        if selectedOccasion.contains("紀念") {
            return "紀念日浪漫花束"
        }
        return "\(selectedColor)\(selectedOccasion)花束"
    }

    var canAdvanceFromFlowerStep: Bool {
        !selectedDIYFlowers.isEmpty
    }

    var canAdvanceFromWrappingStep: Bool {
        selectedWrappingOption != nil
    }

    var missingReferenceFlowerNames: [String] {
        selectedDIYFlowers
            .filter { !$0.flower.hasReferenceImage }
            .map { $0.flower.name }
    }
    
    var missingPreviewReferenceMessages: [String] {
        var messages: [String] = []
        
        if !hasResolvedRemoteFlowers {
            messages.append("花材参考图仍在从 Firestore 加载。")
        } else if remoteFlowerCount == 0 {
            messages.append("Firestore 的 flowers 暂无可用花材参考图。")
        } else if selectedDIYFlowers.isEmpty {
            messages.append("请先选择花材。")
        } else if !missingReferenceFlowerNames.isEmpty {
            messages.append("以下花材缺少 Firestore 参考图：\(missingReferenceFlowerNames.joined(separator: "、"))")
        }
        
        if !hasResolvedRemoteWrappingOptions {
            messages.append("包装参考图仍在从 Firestore 加载。")
        } else if selectedWrappingOption == nil {
            messages.append("请先选择包装。")
        } else if selectedWrappingOption?.hasReferenceImage != true {
            messages.append("所选包装缺少 Firestore 参考图。")
        }
        
        return messages
    }
    
    var canGenerateDIYPreview: Bool {
        missingPreviewReferenceMessages.isEmpty
    }

    var hasDIYProgress: Bool {
        !selectedDIYFlowers.isEmpty
            || selectedWrappingOptionID != nil
            || !cardMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedBlessingTemplateID != nil
            || generatedPreview != nil
            || assistantFlowStage == .preview
    }

    var hasAssistantRecommendationProgress: Bool {
        assistantConversationStep > 1
            || assistantRecommendationText != nil
            || isGeneratingAssistantRecommendation
            || hasDIYProgress
            || {
                if case .diy = assistantFlowStage {
                    return true
                }
                return false
            }()
    }

    var checkoutPrimaryItem: CartItem? {
        cartItems.first
    }

    var checkoutProductTitle: String {
        guard let primary = checkoutPrimaryItem else {
            return "花禮訂單"
        }

        if cartItems.count == 1 {
            return primary.product.name
        }

        return "\(primary.product.name) 等\(cartItems.count)件花禮"
    }

    var checkoutProductSubtitle: String {
        if cartItems.count == 1 {
            return checkoutPrimaryItem?.product.tagline ?? "店舖花禮"
        }

        let totalQuantity = cartItems.reduce(0) { $0 + $1.quantity }
        return "共 \(totalQuantity) 件商品"
    }

    var checkoutProductImageURL: String {
        checkoutPrimaryItem?.product.imageURL ?? ""
    }

    var checkoutPickupLocation: String {
        "蔚蘭園 – 香港大學站 B2 出口"
    }

    var checkoutPickupTimeText: String {
        timeText(from: checkoutPickupDate)
    }

    var checkoutPickupWindowText: String {
        let start = checkoutPickupDate.addingTimeInterval(90 * 60)
        let end = start.addingTimeInterval(30 * 60)
        return "\(timeText(from: start)) - \(timeText(from: end))"
    }

    var checkoutSpecialRequests: String {
        let trimmedCardMessage = cardMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        if includeGreetingCard, !trimmedCardMessage.isEmpty {
            return trimmedCardMessage
        }

        return "請準備新鮮花材，謝謝 🌹"
    }

    var checkoutBreakdownLines: [CheckoutBreakdownLine] {
        let itemLines = cartItems.map { item in
            CheckoutBreakdownLine(
                title: item.product.name,
                detail: "\(item.quantity) × \(currencyText(unitPrice(for: item.product)))",
                amount: unitPrice(for: item.product) * Double(item.quantity)
            )
        }

        if itemLines.isEmpty {
            return [
                CheckoutBreakdownLine(
                    title: "店舖花禮",
                    detail: "1 × HKD 0",
                    amount: 0
                )
            ]
        }

        return itemLines
    }

    func showEmailLogin(mode: AuthEntryMode = .login) {
        authEntryMode = mode
        authErrorMessage = nil
        authErrorTitle = "操作失敗"
        password = ""
        authState = .emailLogin
    }

    func enterAsGuest() {
        authEntryMode = .login
        authErrorMessage = nil
        authState = .main
        activeTab = .home
        overlayScreen = nil
    }

    func submitAuthForm() {
        guard canSubmitAuthForm else { return }

        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPassword = password

        email = normalizedEmail
        dismissAuthError()
        isAuthenticating = true

        Task { [weak self] in
            guard let self else { return }

            defer {
                self.isAuthenticating = false
            }

            do {
                switch self.authEntryMode {
                case .login:
                    try await FirebaseManager.shared.login(email: normalizedEmail, password: resolvedPassword)
                case .register:
                    try await FirebaseManager.shared.register(email: normalizedEmail, password: resolvedPassword)
                }

                self.finalizeSuccessfulAuthentication()
            } catch {
                self.presentAuthError(
                    title: self.authEntryMode == .login ? "登入失敗" : "註冊失敗",
                    message: error.localizedDescription
                )
            }
        }
    }

    func backToWelcome() {
        authEntryMode = .login
        password = ""
        isAuthenticating = false
        dismissAuthError()
        authState = .welcome
    }

    func logout() {
        do {
            if FirebaseManager.shared.currentUser != nil {
                try FirebaseManager.shared.signOut()
            }
            resetSessionStateAfterLogout()
        } catch {
            authErrorTitle = "登出失敗"
            authErrorMessage = error.localizedDescription
        }
    }

    func dismissAuthError() {
        authErrorTitle = "操作失敗"
        authErrorMessage = nil
    }

    func switchAuthEntryMode() {
        authEntryMode = authEntryMode == .login ? .register : .login
        password = ""
        dismissAuthError()
    }

    func selectTab(_ tab: MainTab) {
        activeTab = tab
        if tab == .browse {
            browseMode = .materials
        }
        overlayScreen = nil
    }

    func openProduct(_ product: BouquetProduct, from tab: MainTab = .home) {
        selectedProduct = product
        activeTab = tab
        overlayScreen = .productDetail
    }

    func openCustomBouquetFlow(from tab: MainTab = .assistant) {
        activeTab = tab
        overlayScreen = .assistantJourney
    }

    func startAssistantRecommendationFlow(from tab: MainTab = .assistant) {
        activeTab = tab
        resetAssistantSelections()
        resetDIYFlow()
        clearAssistantRecommendation()
        assistantConversationStep = 1
        overlayScreen = .assistantJourney
    }

    func openDirectDIYFlow(from tab: MainTab = .browse) {
        activeTab = tab
        if !hasDIYProgress {
            resetDIYFlow()
        }
        proceedToDIYDesigner()
        overlayScreen = .assistantJourney
    }

    func openFarm() {
        activeTab = .profile
        overlayScreen = .farm
    }

    func openOrderHistory() {
        activeTab = .profile
        refreshUserOrders()
        overlayScreen = .orderHistory
    }

    func canCancelOrder(_ order: OrderData) -> Bool {
        guard let orderID = order.id else { return false }
        return order.status == OrderStatus.pending.rawValue && cancellingOrderID != orderID
    }

    func cancelPendingOrder(_ order: OrderData) {
        guard order.status == OrderStatus.pending.rawValue,
              let orderID = order.id else {
            return
        }

        cancellingOrderID = orderID
        userOrdersErrorMessage = nil

        orderService.cancelOrder(orderId: orderID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.cancellingOrderID = nil

                switch result {
                case .success:
                    if let index = self.userOrders.firstIndex(where: { $0.id == orderID }) {
                        self.userOrders[index].status = OrderStatus.cancelled.rawValue
                    }
                    self.refreshUserOrders()
                case .failure(let error):
                    self.userOrdersErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func openProfileEditor() {
        activeTab = .profile
        profileSaveErrorMessage = nil
        primeProfileDrafts()
        overlayScreen = .editProfile
    }

    func openBrowse(mode: BrowseMode) {
        activeTab = .browse
        browseMode = mode
        overlayScreen = nil
    }

    func closeOverlay() {
        overlayScreen = nil
    }

    func openNotifications() {
        overlayScreen = .notifications
    }

    func saveProfileChanges() {
        guard canSaveProfileChanges else { return }

        isSavingProfile = true
        profileSaveErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            defer {
                self.isSavingProfile = false
            }

            do {
                let updatedProfile = try await FirebaseManager.shared.updateCurrentUserProfile(
                    displayName: self.profileDraftName,
                    email: self.profileDraftEmail,
                    phoneNumber: self.profileDraftPhone
                )
                self.profileRecord = updatedProfile
                self.email = updatedProfile.email
                self.overlayScreen = nil
            } catch {
                self.profileSaveErrorMessage = error.localizedDescription
            }
        }
    }

    func cartQuantity(for productID: String) -> Int {
        cartItems.first(where: { $0.product.id == productID })?.quantity ?? 0
    }

    func cartQuantity(for flower: Flower) -> Int {
        cartQuantity(for: BouquetProduct.fromFlower(flower).id)
    }

    func addProductToCart(_ product: BouquetProduct) {
        guard canIncrementCartQuantity(for: product) else { return }
        if let index = cartItems.firstIndex(where: { $0.product.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: product, quantity: 1))
        }
    }

    func removeProductFromCart(_ product: BouquetProduct) {
        guard let index = cartItems.firstIndex(where: { $0.product.id == product.id }) else { return }
        if cartItems[index].quantity > 1 {
            cartItems[index].quantity -= 1
        } else {
            cartItems.remove(at: index)
        }
    }

    func addSelectedProductToCart() {
        addProductToCart(selectedProduct)
    }

    func proceedToCheckout() {
        addSelectedProductToCart()
        openCheckout()
    }

    func proceedToCart() {
        activeTab = .cart
        overlayScreen = nil
    }

    func openCheckout() {
        guard !cartItems.isEmpty else {
            activeTab = .cart
            overlayScreen = nil
            return
        }

        activeTab = .cart
        overlayScreen = .checkout
        isShowingCheckoutPriceDetails = false
        paymentErrorMessage = nil
    }

    func browseFeaturedProduct() {
        guard let featuredBouquetProduct else { return }
        openProduct(featuredBouquetProduct, from: .home)
    }

    func showNextFeaturedProduct() {
        guard !availableBouquetProducts.isEmpty else { return }
        featuredBouquetIndex = (featuredBouquetIndex + 1) % availableBouquetProducts.count
    }

    func showPreviousFeaturedProduct() {
        guard !availableBouquetProducts.isEmpty else { return }
        let total = availableBouquetProducts.count
        featuredBouquetIndex = (featuredBouquetIndex - 1 + total) % total
    }

    func addFlowerToCart(_ flower: Flower) {
        addProductToCart(BouquetProduct.fromFlower(flower))
    }

    func removeFlowerFromCart(_ flower: Flower) {
        removeProductFromCart(BouquetProduct.fromFlower(flower))
    }

    func resetAssistantSelections() {
        selectedPurchaseType = "花束"
        selectedRecipient = "朋友"
        selectedOccasion = "生日"
        selectedColor = "粉色"
        selectedBudget = "港幣100-200元"
    }

    func resetAssistantChat() {
        assistantComposerText = ""
        assistantErrorMessage = nil
        isSendingAssistantMessage = false
        assistantRecommendationText = nil
        isGeneratingAssistantRecommendation = false
        assistantConversationStep = 1
        assistantMessages = [
            StorefrontAssistantMessage(
                role: .assistant,
                text: "你好，我已经接上实时数据库了。你可以直接问我现有什么花、价格多少、哪些花束适合送礼，或让我按预算推荐。"
            )
        ]
    }

    func clearAssistantRecommendation() {
        assistantRecommendationText = nil
        assistantErrorMessage = nil
        isGeneratingAssistantRecommendation = false
    }

    func sendAssistantPreset(_ text: String) async {
        guard !isSendingAssistantMessage else { return }
        assistantComposerText = text
        await sendAssistantMessage()
    }

    func sendAssistantMessage() async {
        let trimmedMessage = assistantComposerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty, !isSendingAssistantMessage else { return }

        assistantComposerText = ""
        assistantErrorMessage = nil
        assistantMessages.append(
            StorefrontAssistantMessage(
                role: .user,
                text: trimmedMessage
            )
        )

        isSendingAssistantMessage = true
        defer {
            isSendingAssistantMessage = false
        }

        do {
            let reply = try await assistantService.reply(
                history: assistantMessages,
                context: buildAssistantContext(),
                apiKey: assistantAPIKey,
                modelName: assistantModelName
            )
            assistantMessages.append(
                StorefrontAssistantMessage(
                    role: .assistant,
                    text: reply
                )
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            assistantErrorMessage = message
            assistantMessages.append(
                StorefrontAssistantMessage(
                    role: .assistant,
                    text: "暂时无法生成回答：\(message)"
                )
            )
        }
    }

    func generateAssistantRecommendation() async {
        assistantRecommendationText = nil
        assistantErrorMessage = nil
        isGeneratingAssistantRecommendation = true

        defer {
            isGeneratingAssistantRecommendation = false
        }

        let prompt = """
        请根据以下顾客需求，基于当前数据库中真实存在的花材、花束、包装和库存，给出最后的购买推荐。

        顾客需求：
        - 购买类型：\(selectedPurchaseType)
        - 收花对象：\(selectedRecipient)
        - 送花场合：\(selectedOccasion)
        - 颜色偏好：\(selectedColor)
        - 预算范围：\(selectedBudget)

        输出要求：
        - 用中文回答。
        - 先给一句总体推荐结论。
        - 再给 2 到 3 个真实可买的推荐，可以是成品花束，也可以是花材组合。
        - 尽量写出具体名称、价格或预算匹配情况。
        - 如果数据库里没有完全匹配的选项，要明确说明，并给最接近的推荐。
        - 最后补一句，告诉用户进入 DIY 时优先看哪类花材或包装。
        - 不要输出 JSON。
        """

        do {
            let reply = try await assistantService.reply(
                history: [
                    StorefrontAssistantMessage(
                        role: .user,
                        text: prompt
                    )
                ],
                context: buildAssistantContext(),
                apiKey: assistantAPIKey,
                modelName: assistantModelName
            )
            assistantRecommendationText = reply
        } catch {
            assistantErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func quantity(for flower: Flower) -> Int {
        selectedFlowerQuantities[flower.id, default: 0]
    }

    func increaseFlowerQuantity(_ flower: Flower) {
        guard canIncrementDIYQuantity(for: flower) else { return }
        selectedFlowerQuantities[flower.id, default: 0] += 1
    }

    func decreaseFlowerQuantity(_ flower: Flower) {
        let currentQuantity = selectedFlowerQuantities[flower.id, default: 0]
        guard currentQuantity > 0 else { return }
        if currentQuantity == 1 {
            selectedFlowerQuantities.removeValue(forKey: flower.id)
        } else {
            selectedFlowerQuantities[flower.id] = currentQuantity - 1
        }
    }

    func toggleWrappingSelection(_ option: BouquetWrappingOption) {
        if selectedWrappingOptionID == option.id {
            selectedWrappingOptionID = nil
        } else {
            selectedWrappingOptionID = option.id
        }
    }

    func toggleGreetingCard(_ include: Bool) {
        includeGreetingCard = include
        if !include {
            cardMessage = ""
            selectedBlessingTemplateID = nil
        }
    }

    func applyBlessingTemplate(_ template: CardBlessingTemplate) {
        includeGreetingCard = true
        selectedBlessingTemplateID = template.id
        cardMessage = template.message
    }

    func proceedToDIYDesigner() {
        if let recommendedCategory = preferredDIYCategory {
            selectedDIYFlowerCategory = recommendedCategory
        }
        assistantFlowStage = .diy(.flowers)
    }

    func navigateToDIYStep(_ step: DIYStep) {
        assistantFlowStage = .diy(step)
    }
    
    func stepBackInDIYFlow(from step: DIYStep) {
        if let previous = step.previous {
            assistantFlowStage = .diy(previous)
        } else {
            assistantFlowStage = .chat
        }
    }

    func presentPreviewDisclaimerOverlay() {
        showPreviewDisclaimer = true
    }

    func dismissPreviewDisclaimerOverlay() {
        showPreviewDisclaimer = false
    }

    func returnToConfirmStep() {
        assistantFlowStage = .diy(.confirm)
        showPreviewDisclaimer = false
    }

    func generateDIYPreview() async {
        previewErrorMessage = nil
        isGeneratingPreview = true

        defer {
            isGeneratingPreview = false
        }
        
        guard canGenerateDIYPreview else {
            previewErrorMessage = missingPreviewReferenceMessages.first ?? "请先补齐 Firestore 里的花材和包装参考图。"
            return
        }

        let selections = selectedDIYFlowers.map { line in
            AIBouquetSelection(
                flower: line.flower,
                quantity: line.quantity,
                score: 100,
                reasons: ["用户在 DIY 流程中实际选择"],
                isSelected: true
            )
        }

        do {
            generatedPreview = try await previewService.generatePreview(
                requirement: selectedWrappingOption?.name ?? "",
                selections: selections,
                wrappingOption: selectedWrappingOption,
                apiKey: apiKey,
                modelName: modelName,
                requireReferenceImages: true
            )
            assistantFlowStage = .preview
            showPreviewDisclaimer = true
        } catch {
            previewErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    func addCustomBouquetToCart() {
        let product = BouquetProduct(
            id: "custom-\(selectedDIYFlowers.map(\.flower.id).joined(separator: "-"))-\(selectedWrappingOptionID ?? "plain")",
            name: customBouquetHeadline,
            tagline: selectedWrappingOption?.name ?? "DIY 客製花束",
            descriptionLines: selectedDIYFlowers.map { "\($0.flower.name) x\($0.quantity)" },
            longDescription: [
                suggestedDesignText,
                "花材：\(selectedDIYFlowers.map { "\($0.flower.name) x\($0.quantity)" }.joined(separator: "、"))",
                "包裝：\(selectedWrappingOption?.name ?? "未選擇")"
            ],
            priceText: "HKD \(Int(diyTotalPrice.rounded()))",
            imageURL: generatedPreview?.imageURL.absoluteString
                ?? selectedWrappingOption?.imageURL
                ?? selectedDIYFlowers.first?.flower.imageURL?.absoluteString
                ?? "",
            accent: FigmaPalette.softPink,
            inventoryItems: selectedDIYFlowers.map { line in
                BouquetItemData(
                    flowerId: line.flower.id,
                    flowerName: line.flower.name,
                    flowerEmoji: line.flower.emoji,
                    flowerPrice: line.flower.price,
                    quantity: line.quantity,
                    positionX: 0,
                    positionY: 0,
                    scale: 1,
                    rotation: 0
                )
            }
        )
        addProductToCart(product)
    }

    func addCustomBouquetToCartAndProceedToCheckout() {
        addCustomBouquetToCart()
        openCheckout()
    }

    func toggleCheckoutPriceDetails() {
        isShowingCheckoutPriceDetails.toggle()
    }

    func selectPaymentMethod(_ method: CheckoutPaymentMethod) {
        selectedPaymentMethod = method
    }

    func dismissCheckout() {
        overlayScreen = nil
        activeTab = .cart
    }

    func dismissTracking() {
        overlayScreen = nil
        activeTab = .home
    }

    func submitDemoPayment() {
        guard !cartItems.isEmpty, !isSubmittingPayment else { return }

        isSubmittingPayment = true
        paymentErrorMessage = nil

        let cartSnapshot = cartItems
        let sourceOrderId = generateSourceOrderId()
        let orderName = checkoutProductTitle
        let pickupDate = checkoutPickupDate
        let orderItems = cartSnapshot.map { item in
            StorefrontOrderLineItem(
                productId: item.product.id,
                productName: item.product.name,
                unitPrice: unitPrice(for: item.product),
                quantity: item.quantity,
                inventoryItems: item.product.inventoryItems
            )
        }

        orderService.submitStorefrontOrder(
            items: orderItems,
            orderName: orderName,
            customerName: demoCustomerName,
            customerPhone: demoCustomerPhone,
            deliveryAddress: checkoutPickupLocation,
            deliveryDate: pickupDate,
            specialRequests: checkoutSpecialRequests,
            totalPrice: cartSnapshot.reduce(0) { partial, item in
                partial + unitPrice(for: item.product) * Double(item.quantity)
            },
            sourceOrderId: sourceOrderId
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSubmittingPayment = false

                switch result {
                case .success(let submittedOrder):
                    self.submittedTrackingOrder = StorefrontTrackingOrder(
                        documentID: submittedOrder.documentID,
                        sourceOrderId: submittedOrder.sourceOrderId,
                        createdAt: submittedOrder.createdAt,
                        pickupDate: pickupDate,
                        pickupLocation: self.checkoutPickupLocation,
                        pickupWindowText: self.checkoutPickupWindowText,
                        note: self.checkoutSpecialRequests,
                        paymentMethod: self.selectedPaymentMethod,
                        items: cartSnapshot.map { item in
                            StorefrontTrackingOrder.ItemSnapshot(
                                name: item.product.name,
                                quantity: item.quantity,
                                unitPrice: self.unitPrice(for: item.product),
                                imageURL: item.product.imageURL
                            )
                        },
                        totalPrice: cartSnapshot.reduce(0) { partial, item in
                            partial + self.unitPrice(for: item.product) * Double(item.quantity)
                        }
                    )
                    self.cartItems = []
                    self.isShowingCheckoutPriceDetails = false
                    self.overlayScreen = .orderTracking
                    self.activeTab = .cart
                case .failure(let error):
                    self.paymentErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func setupOrderBindings() {
        orderService.$orders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] orders in
                self?.userOrders = orders
            }
            .store(in: &cancellables)

        orderService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoadingUserOrders = isLoading
            }
            .store(in: &cancellables)

        orderService.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.userOrdersErrorMessage = error
            }
            .store(in: &cancellables)
    }

    private func setupAuthBindings() {
        FirebaseManager.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }

                if user != nil {
                    self.refreshUserOrders()
                    self.loadCurrentUserProfile()
                } else {
                    self.orderService.stopListening()
                    self.userOrders = []
                    self.isLoadingUserOrders = false
                    self.userOrdersErrorMessage = nil
                    self.profileRecord = nil
                    self.isLoadingProfile = false
                    self.isSavingProfile = false
                    self.profileSaveErrorMessage = nil
                    self.profileDraftName = ""
                    self.profileDraftEmail = ""
                    self.profileDraftPhone = ""
                }
            }
            .store(in: &cancellables)
    }

    private func refreshUserOrders() {
        userOrdersErrorMessage = nil
        orderService.fetchUserOrders()
    }

    private func loadCurrentUserProfile() {
        guard FirebaseManager.shared.hasAuthenticatedUser else { return }

        isLoadingProfile = true
        profileSaveErrorMessage = nil

        Task { [weak self] in
            guard let self else { return }

            defer {
                self.isLoadingProfile = false
            }

            do {
                let profile = try await FirebaseManager.shared.fetchCurrentUserProfile()
                self.profileRecord = profile
                self.email = profile.email
                self.primeProfileDrafts()
            } catch {
                self.profileSaveErrorMessage = error.localizedDescription
            }
        }
    }

    private func primeProfileDrafts() {
        profileDraftName = profileDisplayName == "訪客" ? "" : profileDisplayName
        profileDraftEmail = profileEmailText == "訪客模式" ? "" : profileEmailText
        profileDraftPhone = profilePhoneText == "訪客模式" || profilePhoneText == "未設定" ? "" : profilePhoneText
    }

    private func setupFlowerBindings() {
        flowerService.$flowers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] flowerDataList in
                guard let self else { return }
                self.remoteFlowerCount = flowerDataList.count
                if !flowerDataList.isEmpty {
                    self.availableFlowers = flowerDataList.map { $0.toFlower() }
                    if !self.diyFlowerCategories.contains(self.selectedDIYFlowerCategory),
                       let firstCategory = self.diyFlowerCategories.first {
                        self.selectedDIYFlowerCategory = firstCategory
                    }
                }
                self.refreshBouquetCatalog()
            }
            .store(in: &cancellables)
        
        flowerService.$hasResolvedFlowers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasResolved in
                self?.hasResolvedRemoteFlowers = hasResolved
            }
            .store(in: &cancellables)
    }

    private func setupBouquetBindings() {
        bouquetService.$catalogBouquets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] bouquets in
                self?.liveBouquetCatalog = bouquets
                self?.refreshBouquetCatalog()
            }
            .store(in: &cancellables)
        
        bouquetService.$hasResolvedCatalogBouquets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasResolved in
                self?.hasResolvedRemoteBouquets = hasResolved
                self?.refreshBouquetCatalog()
            }
            .store(in: &cancellables)
    }

    private func setupPreviewConfigurationBindings() {
        storefrontConfigService.$previewConfiguration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in
                guard let self, let config, config.isEnabled else { return }
                
                if let apiKey = config.apiKey {
                    self.apiKey = apiKey
                }
                
                if let modelName = config.modelName {
                    self.modelName = modelName
                }

                if let assistantApiKey = config.assistantApiKey {
                    self.assistantAPIKey = assistantApiKey
                }

                if let assistantModelName = config.assistantModelName {
                    self.assistantModelName = assistantModelName
                }
            }
            .store(in: &cancellables)
    }

    private func setupInventoryBindings() {
        storefrontConfigService.$inventoryStocksByCode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stocksByCode in
                guard let self else { return }
                self.inventoryStocksByCode = stocksByCode
                if self.hasResolvedInventory {
                    self.evaluateRestockReminders()
                }
            }
            .store(in: &cancellables)

        storefrontConfigService.$hasResolvedInventory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasResolved in
                guard let self else { return }
                self.hasResolvedInventory = hasResolved
                if hasResolved {
                    self.evaluateRestockReminders()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupWrappingBindings() {
        storefrontConfigService.$wrappingOptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] options in
                guard let self else { return }
                let mappedOptions = options.map(BouquetWrappingOption.init)
                self.availableWrappingOptions = mappedOptions
                
                if let selectedWrappingOptionID,
                   !mappedOptions.contains(where: { $0.id == selectedWrappingOptionID }) {
                    self.selectedWrappingOptionID = nil
                }
            }
            .store(in: &cancellables)
        
        storefrontConfigService.$hasResolvedWrappingOptions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasResolved in
                self?.hasResolvedRemoteWrappingOptions = hasResolved
            }
            .store(in: &cancellables)
    }

    private func finalizeSuccessfulAuthentication() {
        authEntryMode = .login
        dismissAuthError()
        authState = .main
        activeTab = .home
        overlayScreen = nil
        email = FirebaseManager.shared.authenticatedEmail ?? email
        password = ""
        refreshUserOrders()
        loadCurrentUserProfile()
    }

    private func presentAuthError(title: String, message: String) {
        authErrorTitle = title
        authErrorMessage = message
    }

    private func resetSessionStateAfterLogout() {
        orderService.stopListening()
        authErrorMessage = nil
        authErrorTitle = "操作失敗"
        authState = .welcome
        authEntryMode = .login
        activeTab = .home
        overlayScreen = nil
        email = ""
        password = ""
        isAuthenticating = false
        userOrders = []
        isLoadingUserOrders = false
        userOrdersErrorMessage = nil
        profileRecord = nil
        isLoadingProfile = false
        isSavingProfile = false
        profileSaveErrorMessage = nil
        profileDraftName = ""
        profileDraftEmail = ""
        profileDraftPhone = ""
        selectedProduct = BouquetProduct.defaultSelection
        featuredBouquetIndex = 0
        cartItems = []
        browseMode = .materials
        selectedFlowerCategory = nil
        selectedPaymentMethod = .alipayHK
        isShowingCheckoutPriceDetails = false
        isSubmittingPayment = false
        paymentErrorMessage = nil
        submittedTrackingOrder = nil
        resetAssistantSelections()
        resetDIYFlow()
        resetAssistantChat()
    }

    private func resetDIYFlow() {
        assistantFlowStage = .chat
        selectedDIYFlowerCategory = preferredDIYCategory ?? diyFlowerCategories.first ?? .rose
        selectedFlowerQuantities = [:]
        selectedWrappingOptionID = nil
        includeGreetingCard = true
        cardMessage = ""
        selectedBlessingTemplateID = nil
        generatedPreview = nil
        previewErrorMessage = nil
        isGeneratingPreview = false
        showPreviewDisclaimer = false
    }

    private var preferredDIYCategory: FlowerCategory? {
        for flowerName in recommendedFlowerTypes {
            if let flower = availableFlowers.first(where: { $0.name == flowerName }) {
                return flower.category
            }
        }
        return diyFlowerCategories.first
    }
    
    private func refreshBouquetCatalog() {
        let remoteProducts = liveBouquetCatalog.map { bouquet in
            BouquetProduct.fromBouquet(bouquet, availableFlowers: availableFlowers)
        }
        let resolvedCatalog = hasResolvedRemoteBouquets ? remoteProducts : []

        availableBouquetProducts = resolvedCatalog

        if resolvedCatalog.isEmpty {
            featuredBouquetIndex = 0
        } else {
            featuredBouquetIndex = featuredBouquetIndex % resolvedCatalog.count
        }

        if let firstProduct = resolvedCatalog.first,
           !resolvedCatalog.contains(where: { $0.id == selectedProduct.id }) {
            selectedProduct = resolvedCatalog.dropFirst().first ?? firstProduct
        }
    }

    private func buildAssistantContext() -> StorefrontAssistantContext {
        let flowerRecords = availableFlowers.prefix(50).map { flower in
            StorefrontAssistantContext.FlowerRecord(
                name: flower.name,
                englishName: flower.englishName,
                category: flower.categoryDisplayName,
                color: flower.colorName,
                priceHKD: flower.price,
                stock: availableStock(for: flower) ?? flower.stockQuantity,
                inventoryCode: flower.inventoryCode,
                unit: flower.unitDisplayName,
                season: flower.season,
                description: flower.description
            )
        }

        let bouquetRecords = availableBouquetProducts.prefix(20).map { product in
            StorefrontAssistantContext.BouquetRecord(
                name: product.name,
                tagline: product.tagline,
                priceText: product.priceText,
                stock: availableStock(for: product),
                descriptionLines: product.descriptionLines
            )
        }

        let wrappingRecords = availableWrappingOptions.prefix(20).map { option in
            StorefrontAssistantContext.WrappingRecord(
                name: option.name,
                priceHKD: option.price,
                stock: availableStock(for: option) ?? option.stockQuantity,
                inventoryCode: option.inventoryCode
            )
        }

        return StorefrontAssistantContext(
            generatedAt: Date(),
            hasResolvedFlowers: hasResolvedRemoteFlowers,
            hasResolvedBouquets: hasResolvedRemoteBouquets,
            hasResolvedWrappingOptions: hasResolvedRemoteWrappingOptions,
            flowers: Array(flowerRecords),
            bouquets: Array(bouquetRecords),
            wrappingOptions: Array(wrappingRecords),
            currentSelections: StorefrontAssistantContext.CurrentSelections(
                purchaseType: selectedPurchaseType,
                recipient: selectedRecipient,
                occasion: selectedOccasion,
                color: selectedColor,
                budget: selectedBudget
            )
        )
    }

    private var checkoutPickupDate: Date {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let todayThreePM = calendar.date(
            bySettingHour: 15,
            minute: 0,
            second: 0,
            of: now
        ) ?? now

        if now < todayThreePM {
            return todayThreePM
        }

        return calendar.date(byAdding: .day, value: 1, to: todayThreePM) ?? todayThreePM
    }

    private var demoCustomerName: String {
        let trimmedName = profileDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, trimmedName != "訪客" else {
            return "Demo Customer"
        }

        return trimmedName
    }

    private var demoCustomerPhone: String {
        let trimmedPhone = profileRecord?.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedPhone.isEmpty {
            return trimmedPhone
        }

        return "+852 0000 0000"
    }

    private func generateSourceOrderId() -> String {
        let rawValue = Int(Date().timeIntervalSince1970) % 10_000
        return String(format: "#%04d", rawValue)
    }

    func isRestockReminderEnabled(for flower: Flower) -> Bool {
        restockReminderTargets.contains(reminderTarget(for: flower))
    }

    func isRestockReminderEnabled(for product: BouquetProduct) -> Bool {
        restockReminderTargets.contains(reminderTarget(for: product))
    }

    func isRestockReminderEnabled(for option: BouquetWrappingOption) -> Bool {
        restockReminderTargets.contains(reminderTarget(for: option))
    }

    func toggleRestockReminder(for flower: Flower) {
        toggleRestockReminderTarget(reminderTarget(for: flower))
    }

    func toggleRestockReminder(for product: BouquetProduct) {
        toggleRestockReminderTarget(reminderTarget(for: product))
    }

    func toggleRestockReminder(for option: BouquetWrappingOption) {
        toggleRestockReminderTarget(reminderTarget(for: option))
    }

    func availableStock(for flower: Flower) -> Int? {
        if let inventoryCode = normalizedInventoryCode(flower.inventoryCode),
           let inventoryStock = inventoryStocksByCode[inventoryCode] {
            return inventoryStock
        }

        return flower.stockQuantity
    }

    func availableStock(for option: BouquetWrappingOption) -> Int? {
        if let inventoryCode = normalizedInventoryCode(option.inventoryCode),
           let inventoryStock = inventoryStocksByCode[inventoryCode] {
            return inventoryStock
        }

        return option.stockQuantity
    }

    func availableStock(for product: BouquetProduct) -> Int? {
        if let flower = singleFlower(for: product) {
            return flower.stockQuantity
        }

        let requiredInventoryItems = product.inventoryItems.filter { $0.quantity > 0 }
        guard !requiredInventoryItems.isEmpty else { return nil }

        var remainingCounts: [Int] = []
        for item in requiredInventoryItems {
            guard let flower = matchedFlower(for: item),
                  let stockQuantity = flower.stockQuantity else {
                return nil
            }

            remainingCounts.append(stockQuantity / item.quantity)
        }

        return remainingCounts.min()
    }

    func stockText(for flower: Flower) -> String {
        if let stockQuantity = availableStock(for: flower) {
            return "剩餘\(stockQuantity)\(flower.unitDisplayName)"
        }

        if hasResolvedInventory {
            return "庫存記錄未匹配"
        }

        return "剩餘庫存待同步"
    }

    func stockText(for option: BouquetWrappingOption) -> String {
        if let stockQuantity = availableStock(for: option) {
            return "剩餘\(stockQuantity)款"
        }

        if hasResolvedInventory {
            return "庫存記錄未匹配"
        }

        return "剩餘庫存待同步"
    }

    func stockText(for product: BouquetProduct) -> String {
        if let stockQuantity = availableStock(for: product) {
            return "剩餘\(stockQuantity)\(stockUnitLabel(for: product))"
        }

        if hasResolvedInventory {
            return "庫存記錄未匹配"
        }

        return "剩餘庫存待同步"
    }

    func canIncrementDIYQuantity(for flower: Flower) -> Bool {
        guard let stockQuantity = availableStock(for: flower) else { return true }
        return quantity(for: flower) < stockQuantity
    }

    func canIncrementCartQuantity(for product: BouquetProduct) -> Bool {
        guard let stockQuantity = availableStock(for: product) else { return true }
        return cartQuantity(for: product.id) < stockQuantity
    }

    func canSelectWrappingOption(_ option: BouquetWrappingOption) -> Bool {
        guard let stockQuantity = availableStock(for: option) else { return true }
        return stockQuantity > 0
    }

    func isSoldOut(_ product: BouquetProduct) -> Bool {
        availableStock(for: product) == 0
    }

    private func matchedFlower(for item: BouquetItemData) -> Flower? {
        availableFlowers.first(where: { $0.id == item.flowerId })
            ?? availableFlowers.first(where: { $0.name == item.flowerName })
    }

    private func singleFlower(for product: BouquetProduct) -> Flower? {
        guard product.inventoryItems.count == 1,
              let item = product.inventoryItems.first,
              item.quantity == 1 else {
            return nil
        }

        return matchedFlower(for: item)
    }

    private func stockUnitLabel(for product: BouquetProduct) -> String {
        if let flower = singleFlower(for: product) {
            return flower.unitDisplayName
        }

        return "束"
    }

    private func normalizedInventoryCode(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func reminderTarget(for flower: Flower) -> RestockReminderTarget {
        RestockReminderTarget(kind: .flower, referenceID: flower.id, title: flower.name)
    }

    private func reminderTarget(for product: BouquetProduct) -> RestockReminderTarget {
        RestockReminderTarget(kind: .product, referenceID: product.id, title: product.name)
    }

    private func reminderTarget(for option: BouquetWrappingOption) -> RestockReminderTarget {
        RestockReminderTarget(kind: .wrapping, referenceID: option.id, title: option.name)
    }

    private func toggleRestockReminderTarget(_ target: RestockReminderTarget) {
        if let existingIndex = restockReminderTargets.firstIndex(of: target) {
            restockReminderTargets.remove(at: existingIndex)
            unreadRestockReminderKeys.remove(target.id)
            lastKnownReminderAvailabilityByKey.removeValue(forKey: target.id)
        } else {
            restockReminderTargets.append(target)
            lastKnownReminderAvailabilityByKey[target.id] = isRestockTargetAvailable(target)
        }

        persistRestockReminderState()
    }

    private func evaluateRestockReminders() {
        guard !restockReminderTargets.isEmpty else { return }
        var fulfilledTargetIDs = Set<String>()

        for target in restockReminderTargets {
            let currentAvailability = isRestockTargetAvailable(target)
            let previousAvailability = lastKnownReminderAvailabilityByKey[target.id]

            if currentAvailability && hasRestockNotification(for: target) {
                fulfilledTargetIDs.insert(target.id)
                lastKnownReminderAvailabilityByKey[target.id] = currentAvailability
                continue
            }

            if previousAvailability == false && currentAvailability {
                unreadRestockReminderKeys.insert(target.id)
                appendRestockNotification(for: target)
                fulfilledTargetIDs.insert(target.id)
            }

            lastKnownReminderAvailabilityByKey[target.id] = currentAvailability
        }

        if !fulfilledTargetIDs.isEmpty {
            restockReminderTargets.removeAll { fulfilledTargetIDs.contains($0.id) }
            for targetID in fulfilledTargetIDs {
                lastKnownReminderAvailabilityByKey.removeValue(forKey: targetID)
            }
        }

        persistRestockReminderState()
    }

    private func isRestockTargetAvailable(_ target: RestockReminderTarget) -> Bool {
        switch target.kind {
        case .flower:
            guard let flower = availableFlowers.first(where: { $0.id == target.referenceID }) else {
                return false
            }
            return (availableStock(for: flower) ?? 0) > 0
        case .product:
            guard let product = resolveProduct(withID: target.referenceID) else {
                return false
            }
            return (availableStock(for: product) ?? 0) > 0
        case .wrapping:
            guard let option = availableWrappingOptions.first(where: { $0.id == target.referenceID }) else {
                return false
            }
            return (availableStock(for: option) ?? 0) > 0
        }
    }

    private func resolveProduct(withID productID: String) -> BouquetProduct? {
        if selectedProduct.id == productID {
            return selectedProduct
        }

        if let availableProduct = availableBouquetProducts.first(where: { $0.id == productID }) {
            return availableProduct
        }

        return cartItems.first(where: { $0.product.id == productID })?.product
    }

    private func loadPersistedRestockReminderState() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()

        if let targetsData = defaults.data(forKey: reminderTargetsStorageKey),
           let targets = try? decoder.decode([RestockReminderTarget].self, from: targetsData) {
            restockReminderTargets = targets
        }

        if let unreadKeys = defaults.array(forKey: unreadReminderStorageKey) as? [String] {
            unreadRestockReminderKeys = Set(unreadKeys)
        }

        if let availability = defaults.dictionary(forKey: reminderAvailabilityStorageKey) as? [String: Bool] {
            lastKnownReminderAvailabilityByKey = availability
        }

        if let messagesData = defaults.data(forKey: notificationMessagesStorageKey),
           let messages = try? decoder.decode([StorefrontNotificationMessage].self, from: messagesData) {
            notificationMessages = messages.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func persistRestockReminderState() {
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()

        if let targetsData = try? encoder.encode(restockReminderTargets) {
            defaults.set(targetsData, forKey: reminderTargetsStorageKey)
        }

        defaults.set(Array(unreadRestockReminderKeys), forKey: unreadReminderStorageKey)
        defaults.set(lastKnownReminderAvailabilityByKey, forKey: reminderAvailabilityStorageKey)

        if let messagesData = try? encoder.encode(notificationMessages) {
            defaults.set(messagesData, forKey: notificationMessagesStorageKey)
        }
    }

    func markNotificationAsRead(_ message: StorefrontNotificationMessage) {
        guard let index = notificationMessages.firstIndex(where: { $0.id == message.id }) else { return }
        guard notificationMessages[index].isUnread else { return }

        notificationMessages[index].isUnread = false

        if !notificationMessages.contains(where: { $0.referenceID == message.referenceID && $0.isUnread }) {
            unreadRestockReminderKeys.remove(message.referenceID)
        }

        persistRestockReminderState()
    }

    private func appendRestockNotification(for target: RestockReminderTarget) {
        let message = StorefrontNotificationMessage(
            id: UUID().uuidString,
            kind: .restock,
            senderName: "蔚蘭園",
            title: target.title,
            body: "\(target.title) 到貨提醒❤️",
            referenceID: target.id,
            createdAt: Date(),
            isUnread: true
        )

        notificationMessages.insert(message, at: 0)
    }

    private func hasRestockNotification(for target: RestockReminderTarget) -> Bool {
        notificationMessages.contains { message in
            message.kind == .restock && message.referenceID == target.id
        }
    }

    private func unitPrice(for product: BouquetProduct) -> Double {
        let digits = product.priceText
            .replacingOccurrences(of: "HKD", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(digits) ?? 0
    }

    private func currencyText(_ amount: Double) -> String {
        "HKD \(Int(amount.rounded()))"
    }

    private func timeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct BouquetProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let descriptionLines: [String]
    let longDescription: [String]
    let priceText: String
    let imageURL: String
    let accent: Color
    let inventoryItems: [BouquetItemData]

    init(
        id: String,
        name: String,
        tagline: String,
        descriptionLines: [String],
        longDescription: [String],
        priceText: String,
        imageURL: String,
        accent: Color,
        inventoryItems: [BouquetItemData] = []
    ) {
        self.id = id
        self.name = name
        self.tagline = tagline
        self.descriptionLines = descriptionLines
        self.longDescription = longDescription
        self.priceText = priceText
        self.imageURL = imageURL
        self.accent = accent
        self.inventoryItems = inventoryItems
    }
    
    static var defaultFeatured: BouquetProduct {
        catalog.first ?? defaultSelection
    }
    
    static var defaultSelection: BouquetProduct {
        catalog.count > 1 ? catalog[1] : catalog[0]
    }

    static let catalog: [BouquetProduct] = [
        BouquetProduct(
            id: "sweet-heart",
            name: "甜美心意",
            tagline: "經典粉玫瑰花束",
            descriptionLines: ["粉紅玫瑰 + 綠葉", "韓式白色花紙包裝"],
            longDescription: [
                "溫柔的粉白色調，適合生日與紀念日。",
                "用柔軟包裝和細緻花材營造輕盈感。"
            ],
            priceText: "HKD 228",
            imageURL: "https://www.figma.com/api/mcp/asset/f9bdb990-ab18-4d77-9aca-3c53b85afc20",
            accent: FigmaPalette.softPink
        ),
        BouquetProduct(
            id: "pink-whisper",
            name: "粉戀花語",
            tagline: "柔和粉白玫瑰的浪漫花束",
            descriptionLines: ["混合玫瑰花束", "粉紅玫瑰 · 白玫瑰 · 松蟲草 · 銀葉菊", "柔和粉彩浪漫風格"],
            longDescription: [
                "這款花束設計輕柔浪漫，優雅自然。",
                "非常適合表達感謝、慶祝特別時刻，",
                "或送上一份貼心的驚喜。"
            ],
            priceText: "HKD 258",
            imageURL: "https://www.figma.com/api/mcp/asset/6bee21c5-2d7a-4f8c-8115-769110f594cd",
            accent: FigmaPalette.softPink
        ),
        BouquetProduct(
            id: "blush-dream",
            name: "柔粉花語",
            tagline: "韓系粉色系花束",
            descriptionLines: ["玫瑰主花", "柔霧粉包裝"],
            longDescription: [
                "適合送給喜歡輕甜感的她。",
                "整體視覺乾淨柔和。"
            ],
            priceText: "HKD 238",
            imageURL: "https://www.figma.com/api/mcp/asset/cf706344-fed3-4df3-9cda-5fdff93daa77",
            accent: FigmaPalette.softPink
        ),
        BouquetProduct(
            id: "romance-note",
            name: "浪漫序曲",
            tagline: "粉白漸層花束",
            descriptionLines: ["花束搭配", "適合告白與慶祝"],
            longDescription: [
                "粉色調帶出溫柔氛圍，",
                "整體更有儀式感。"
            ],
            priceText: "HKD 268",
            imageURL: "https://www.figma.com/api/mcp/asset/3e92a05f-059d-48bb-a553-35bf73e588ae",
            accent: FigmaPalette.softPink
        ),
        BouquetProduct(
            id: "morning-bloom",
            name: "晨曦花園",
            tagline: "柔和花束提案",
            descriptionLines: ["配色自然", "適合日常驚喜"],
            longDescription: [
                "清新的外觀更適合輕鬆場合。",
                "有自然柔和的花園感。"
            ],
            priceText: "HKD 218",
            imageURL: "https://www.figma.com/api/mcp/asset/5c968d9b-35d0-4454-848f-58dd8ddf4bf6",
            accent: FigmaPalette.softPink
        ),
        BouquetProduct(
            id: "misty-petal",
            name: "雲霧花影",
            tagline: "柔粉包裝花束",
            descriptionLines: ["浪漫配色", "乾淨層次"],
            longDescription: [
                "適合送給偏愛簡潔視覺的人。",
                "畫面感柔和輕盈。"
            ],
            priceText: "HKD 248",
            imageURL: "https://www.figma.com/api/mcp/asset/18434872-64eb-4b57-9db0-81b1721c071a",
            accent: FigmaPalette.softPink
        )
    ]

    static func fromFlower(_ flower: Flower) -> BouquetProduct {
        BouquetProduct(
            id: "flower-\(flower.id)",
            name: flower.name,
            tagline: flower.englishName,
            descriptionLines: [flower.categoryDisplayName, flower.description],
            longDescription: [flower.description],
            priceText: "HKD \(Int(flower.price.rounded()))",
            imageURL: flower.imageURL?.absoluteString ?? "",
            accent: FigmaPalette.softPink,
            inventoryItems: [
                BouquetItemData(
                    flowerId: flower.id,
                    flowerName: flower.name,
                    flowerEmoji: flower.emoji,
                    flowerPrice: flower.price,
                    quantity: 1,
                    positionX: 0,
                    positionY: 0,
                    scale: 1,
                    rotation: 0
                )
            ]
        )
    }
    
    static func fromBouquet(_ bouquet: BouquetData, availableFlowers: [Flower]) -> BouquetProduct {
        let storedDescription = sanitizedLines(bouquet.descriptionLines)
        let derivedFlowerLines: [String] = bouquet.items
            .compactMap { item -> String? in
                let storedName = sanitizedText(item.flowerName)
                let resolvedName = storedName
                    ?? availableFlowers.first(where: { $0.id == item.flowerId })?.name
                guard let resolvedName else { return nil }
                return "\(resolvedName) x\(item.quantity)"
            }
        let descriptionLines = storedDescription.isEmpty
            ? Array((derivedFlowerLines + wrapSummaryLine(from: bouquet)).prefix(3))
            : storedDescription
        
        let storedLongDescription = sanitizedLines(bouquet.longDescription)
        let longDescription = storedLongDescription.isEmpty
            ? fallbackLongDescription(for: bouquet, descriptionLines: descriptionLines)
            : storedLongDescription
        
        let trimmedTagline = sanitizedText(bouquet.tagline)
        let resolvedTagline = trimmedTagline
            ?? descriptionLines.first
            ?? "来自数据库的真实花束"
        
        let resolvedImageURL = sanitizedText(bouquet.imageURL)
            ?? imageURL(for: bouquet, availableFlowers: availableFlowers)
            ?? ""
        
        let resolvedPrice = bouquet.totalPrice > 0
            ? bouquet.totalPrice
            : computedPrice(for: bouquet, availableFlowers: availableFlowers)
        
        return BouquetProduct(
            id: bouquet.id ?? "bouquet-\(bouquet.name)",
            name: bouquet.name,
            tagline: resolvedTagline,
            descriptionLines: descriptionLines.isEmpty ? ["店铺真实花束"] : descriptionLines,
            longDescription: longDescription,
            priceText: "HKD \(Int(resolvedPrice.rounded()))",
            imageURL: resolvedImageURL,
            accent: FigmaPalette.softPink,
            inventoryItems: bouquet.items
        )
    }
    
    private static func sanitizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
    
    private static func sanitizedLines(_ values: [String]?) -> [String] {
        (values ?? []).compactMap { sanitizedText($0) }
    }
    
    private static func wrapSummaryLine(from bouquet: BouquetData) -> [String] {
        guard let wrapping = sanitizedText(bouquet.wrappingStyle) else {
            return []
        }
        return ["包装：\(wrapping)"]
    }
    
    private static func imageURL(for bouquet: BouquetData, availableFlowers: [Flower]) -> String? {
        for item in bouquet.items {
            if let matchedFlower = availableFlowers.first(where: { $0.id == item.flowerId }),
               let imageURL = sanitizedText(matchedFlower.imageURL?.absoluteString) {
                return imageURL
            }
            
            if let matchedFlower = availableFlowers.first(where: { $0.name == item.flowerName }),
               let imageURL = sanitizedText(matchedFlower.imageURL?.absoluteString) {
                return imageURL
            }
        }
        return nil
    }

    private static func computedPrice(for bouquet: BouquetData, availableFlowers: [Flower]) -> Double {
        bouquet.items.reduce(0) { partial, item in
            let fallbackPrice = item.flowerPrice
            let matchedFlowerPrice = availableFlowers.first(where: { $0.id == item.flowerId })?.price
                ?? availableFlowers.first(where: { $0.name == item.flowerName })?.price
                ?? fallbackPrice
            return partial + (matchedFlowerPrice * Double(item.quantity))
        }
    }
    
    private static func fallbackLongDescription(for bouquet: BouquetData, descriptionLines: [String]) -> [String] {
        var lines = descriptionLines
        
        if let note = sanitizedText(bouquet.note) {
            lines.append(note)
        }
        
        if lines.isEmpty {
            lines.append("花店根据数据库真实花材组合而成。")
        }
        
        return Array(lines.prefix(3))
    }
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: BouquetProduct
    var quantity: Int
}

enum CheckoutPaymentMethod: String, CaseIterable, Identifiable {
    case alipayHK = "支付寶香港"
    case applePay = "Apple Pay"
    case octopus = "八達通"
    case wechatPay = "微信支付"
    case more = "更多付款方式"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .alipayHK, .octopus, .wechatPay:
            return "camera.macro"
        case .applePay:
            return "apple.logo"
        case .more:
            return "ellipsis.circle"
        }
    }
}

struct CheckoutBreakdownLine: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let amount: Double
}

struct StorefrontTrackingOrder {
    struct ItemSnapshot: Identifiable {
        let id = UUID()
        let name: String
        let quantity: Int
        let unitPrice: Double
        let imageURL: String
    }

    let documentID: String
    let sourceOrderId: String
    let createdAt: Date
    let pickupDate: Date
    let pickupLocation: String
    let pickupWindowText: String
    let note: String
    let paymentMethod: CheckoutPaymentMethod
    let items: [ItemSnapshot]
    let totalPrice: Double

    var primaryItem: ItemSnapshot? {
        items.first
    }

    var title: String {
        guard let primaryItem else {
            return "花禮訂單"
        }

        if items.count == 1 {
            return primaryItem.name
        }

        return "\(primaryItem.name) 等\(items.count)件花禮"
    }
}

struct RestockReminderTarget: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case flower
        case product
        case wrapping
    }

    let kind: Kind
    let referenceID: String
    let title: String

    var id: String {
        "\(kind.rawValue):\(referenceID)"
    }
}

struct StorefrontNotificationMessage: Codable, Identifiable, Hashable {
    enum Kind: String, Codable {
        case restock
    }

    let id: String
    let kind: Kind
    let senderName: String
    let title: String
    let body: String
    let referenceID: String
    let createdAt: Date
    var isUnread: Bool
}

private struct MainFlowScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        ZStack {
            switch appModel.overlayScreen {
            case .productDetail:
                ProductDetailScreen(appModel: appModel)
            case .assistantJourney:
                AssistantJourneyScreen(appModel: appModel)
            case .farm:
                FarmScreen(appModel: appModel)
            case .checkout:
                CheckoutScreen(appModel: appModel)
            case .orderTracking:
                OrderTrackingScreen(appModel: appModel)
            case .orderHistory:
                OrderHistoryScreen(appModel: appModel)
            case .editProfile:
                ProfileEditScreen(appModel: appModel)
            case .notifications:
                NotificationsScreen(appModel: appModel)
            case nil:
                switch appModel.activeTab {
                case .home:
                    HomeScreen(appModel: appModel)
                case .browse:
                    BrowseScreen(appModel: appModel)
                case .assistant:
                    AssistantIntroScreen(appModel: appModel)
                case .cart:
                    CartScreen(appModel: appModel)
                case .profile:
                    ProfileScreen(appModel: appModel)
                }
            }
        }
        .animation(.easeInOut(duration: 0.22), value: appModel.activeTab)
        .animation(.easeInOut(duration: 0.22), value: appModel.overlayScreen != nil)
    }
}

private struct NotificationsScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: appModel.activeTab, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Button(action: appModel.closeOverlay) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FigmaPalette.palePink)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        NotificationBellButton(
                            unreadCount: appModel.unreadNotificationCount,
                            size: 30,
                            action: appModel.openNotifications
                        )
                    }
                    .padding(.top, 18)

                    Text("我的消息")
                        .font(.system(size: 29, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 26)

                    if appModel.notificationMessages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 30, weight: .regular))
                                .foregroundColor(.black.opacity(0.45))

                            Text("暫時還沒有新消息")
                                .font(.system(size: 16, weight: .bold))

                            Text("勾選到貨提醒後，補貨時消息會顯示在這裡。")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 48)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(appModel.notificationMessages) { message in
                                NotificationMessageRow(message: message) {
                                    appModel.markNotificationAsRead(message)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

private struct NotificationMessageRow: View {
    let message: StorefrontNotificationMessage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(FigmaPalette.softPink.opacity(0.55))
                            .frame(width: 47, height: 47)

                        Image(systemName: "storefront.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text(message.senderName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)

                            Spacer()

                            Text(timestampText)
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.black)
                        }

                        Text(message.body)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if message.isUnread {
                        Text("1")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(Color(red: 1.0, green: 0.45, blue: 0.47))
                            )
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 18)

                Rectangle()
                    .fill(Color.black.opacity(0.22))
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var timestampText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd H:mm"
        return formatter.string(from: message.createdAt)
    }
}

private struct WelcomeScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                BrandGlowBackground()
                    .frame(height: 86)

                VStack(spacing: 10) {
                    Text("蔚蘭園")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)

                    Text("Wai Lan Garden")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)

                    Text("每一次，都為你打造完美花束")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black)
                }
                .padding(.top, 8)

                RemoteAssetImage(
                    urlString: "https://www.figma.com/api/mcp/asset/71798e89-6195-4613-ad54-6063dab6c251",
                    fallbackSystemName: "gift.fill",
                    contentMode: .fit
                )
                .frame(height: 380)
                .padding(.top, 18)
                .padding(.horizontal, 10)

                VStack(spacing: 20) {
                    SoftActionButton(title: "電郵 / 電話登入", isEnabled: true) {
                        appModel.showEmailLogin(mode: .login)
                    }

                    SoftActionButton(title: "註冊帳戶", isEnabled: true) {
                        appModel.showEmailLogin(mode: .register)
                    }

                    SoftActionButton(title: "以訪客身份繼續", isEnabled: true) {
                        appModel.enterAsGuest()
                    }

                    Button("忘記密碼？") {}
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.black)
                        .padding(.top, -4)
                }
                .padding(.horizontal, 58)
                .padding(.top, 18)
                .padding(.bottom, 44)
            }
            .frame(maxWidth: 402)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .background(Color.white)
    }
}

private struct EmailLoginScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                BrandGlowBackground()
                    .frame(height: 72)

                VStack(spacing: 10) {
                    Text("蔚蘭園")
                        .font(.system(size: 16, weight: .regular))
                    Text("Wai Lan Garden")
                        .font(.system(size: 36, weight: .bold))
                    Text("每一次，都為您打造完美花束")
                        .font(.system(size: 16, weight: .regular))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text(appModel.authEntryMode.formTitle)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 30)

                    Text(appModel.authEntryMode.descriptionText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("電郵")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.top, 6)

                    SoftInputField(text: $appModel.email, placeholder: "")

                    Text("密碼")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.top, 8)

                    SoftInputField(text: $appModel.password, placeholder: "", isSecure: true)

                    if appModel.authEntryMode == .login {
                        Button("忘記密碼？") {}
                            .buttonStyle(.plain)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }

                    SoftActionButton(
                        title: appModel.isAuthenticating
                            ? appModel.authEntryMode.loadingTitle
                            : appModel.authEntryMode.primaryActionTitle,
                        isEnabled: appModel.canSubmitAuthForm
                    ) {
                        appModel.submitAuthForm()
                    }
                    .padding(.top, 10)

                    if appModel.isAuthenticating {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.top, 4)
                    }

                    HStack(spacing: 4) {
                        Spacer()

                        Text(appModel.authEntryMode.secondaryPrompt)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.black.opacity(0.75))

                        Button(appModel.authEntryMode.secondaryActionTitle) {
                            appModel.switchAuthEntryMode()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(FigmaPalette.hotPink)
                        .disabled(appModel.isAuthenticating)
                        .opacity(appModel.isAuthenticating ? 0.45 : 1)

                        Spacer()
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 54)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 402)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Button {
                    appModel.backToWelcome()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FigmaPalette.palePink)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(appModel.isAuthenticating)
                .opacity(appModel.isAuthenticating ? 0.45 : 1)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 14)
            .background(Color.clear)
        }
        .background(Color.white)
    }
}

private struct HomeScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel
    private let featuredAutoplayTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        MainScreenContainer(selectedTab: .home, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            Text("蔚蘭園")
                                .font(.system(size: 14, weight: .regular))

                            Spacer()

                            NotificationBellButton(
                                unreadCount: appModel.unreadNotificationCount,
                                size: 30,
                                action: appModel.openNotifications
                            )
                        }

                        Text("每一次，\n都為您打造完美花束")
                            .font(.system(size: 29, weight: .bold))
                            .lineSpacing(2)
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("前往瀏覽鮮花")
                            .font(.system(size: 16, weight: .bold))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 18) {
                                ForEach(HomeFlowerStrip.items, id: \.self) { imageURL in
                                    Button {
                                        appModel.selectTab(.browse)
                                    } label: {
                                        RemoteAssetImage(
                                            urlString: imageURL,
                                            fallbackSystemName: "leaf",
                                            contentMode: .fill
                                        )
                                        .frame(width: 65, height: 65)
                                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(FigmaPalette.softPink, lineWidth: 1)
                        )
                        .shadow(color: FigmaPalette.softPink.opacity(0.5), radius: 5, x: 0, y: 0)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 19) {
                            PromoCard(
                                title: "打造你的專屬小花園!",
                                subtitle: "每次購買都能獲得花園積分，在你的專屬小花園種下新的花朵！",
                                imageURL: "https://www.figma.com/api/mcp/asset/06569cce-e730-4552-8119-356e260defbf",
                                width: 313
                            ) {
                                appModel.selectTab(.profile)
                            }

                            if let promotionalProduct = appModel.promotionalBouquetProduct {
                                PromoCard(
                                    title: promotionalProduct.name,
                                    subtitle: ([promotionalProduct.tagline] + Array(promotionalProduct.descriptionLines.prefix(1))).joined(separator: " · "),
                                    imageURL: promotionalProduct.imageURL,
                                    width: 311
                                ) {
                                    appModel.openProduct(promotionalProduct, from: .home)
                                }
                            }
                        }
                    }

                    if let featuredProduct = appModel.featuredBouquetProduct {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 34, style: .continuous)
                                .fill(FigmaPalette.softPink)

                            VStack(alignment: .leading, spacing: 0) {
                                Text("本月精選花束")
                                    .font(.system(size: 16, weight: .bold))
                                    .padding(.top, 24)
                                    .padding(.leading, 23)

                                HStack {
                                    Spacer()

                                    RemoteAssetImage(
                                        urlString: featuredProduct.imageURL,
                                        fallbackSystemName: "gift.fill",
                                        contentMode: .fit
                                    )
                                    .frame(width: 124, height: 143)
                                    .padding(.top, 8)

                                    Spacer()
                                }

                                Spacer()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(featuredProduct.name)
                                        .font(.system(size: 14, weight: .regular))
                                    Text(([featuredProduct.tagline] + Array(featuredProduct.descriptionLines.prefix(2))).joined(separator: "\n"))
                                        .font(.system(size: 10, weight: .regular))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 23)
                                .padding(.bottom, 20)
                            }

                            HStack(spacing: 0) {
                                Button {
                                    appModel.showPreviousFeaturedProduct()
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 242)
                                }
                                .buttonStyle(.plain)

                                Button {
                                    appModel.browseFeaturedProduct()
                                } label: {
                                    Color.clear
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)

                                Button {
                                    appModel.showNextFeaturedProduct()
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 242)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(height: 242)
                    }
                }
                .padding(.horizontal, 29)
                .padding(.top, 22)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
        .onReceive(featuredAutoplayTimer) { _ in
            appModel.showNextFeaturedProduct()
        }
    }
}

private struct BrowseScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .browse, appModel: appModel) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Button {
                        appModel.selectTab(.home)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FigmaPalette.palePink)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    VStack(spacing: 2) {
                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))
                        Text(appModel.browseMode == .materials ? "鮮花花材" : "經典花束")
                            .font(.system(size: 26, weight: .bold))
                    }

                    Spacer()

                    Button {
                        appModel.openDirectDIYFlow(from: .browse)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12, weight: .bold))
                            Text("DIY")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(
                            Capsule(style: .continuous)
                                .stroke(Color.black, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 14)

                HStack(spacing: 12) {
                    BrowseModeTabButton(
                        title: "鮮花花材",
                        isSelected: appModel.browseMode == .materials
                    ) {
                        appModel.browseMode = .materials
                    }

                    BrowseModeTabButton(
                        title: "經典花束",
                        isSelected: appModel.browseMode == .bouquets
                    ) {
                        appModel.browseMode = .bouquets
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)

                if appModel.browseMode == .materials {
                    MaterialsPane(appModel: appModel)
                } else {
                    ClassicBouquetsPane(appModel: appModel)
                }
            }
        }
    }
}

private struct MaterialsPane: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    FlowerSidebarButton(
                        title: "全部",
                        isSelected: appModel.selectedFlowerCategory == nil
                    ) {
                        appModel.selectedFlowerCategory = nil
                    }

                    ForEach(appModel.diyFlowerCategories, id: \.self) { category in
                        FlowerSidebarButton(
                            title: category.displayName,
                            isSelected: appModel.selectedFlowerCategory == category
                        ) {
                            appModel.selectedFlowerCategory = category
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }
            .frame(width: 102)
            .background(FigmaPalette.softPink.opacity(0.45))

            ScrollView(showsIndicators: false) {
                Group {
                    if let stateMessage = appModel.flowerCatalogStateMessage {
                        Text(stateMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 12)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(appModel.filteredFlowers) { flower in
                        DIYFlowerCard(
                            flower: flower,
                            quantity: appModel.cartQuantity(for: flower),
                            stockText: appModel.stockText(for: flower),
                            canIncrement: appModel.canIncrementCartQuantity(for: BouquetProduct.fromFlower(flower)),
                            canDecrement: appModel.cartQuantity(for: flower) > 0,
                            showsRestockReminder: (appModel.availableStock(for: flower) ?? 0) == 0,
                            isRestockReminderEnabled: appModel.isRestockReminderEnabled(for: flower),
                            onToggleRestockReminder: {
                                appModel.toggleRestockReminder(for: flower)
                            },
                            onIncrement: {
                                appModel.addFlowerToCart(flower)
                            },
                            onDecrement: {
                                appModel.removeFlowerFromCart(flower)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(maxWidth: 402, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 10) {
            BrowseCartQuickBar(appModel: appModel)
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .background(Color.white)
        }
    }
}

private struct BrowseCartQuickBar: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    private var totalQuantity: Int {
        appModel.cartItems.reduce(0) { $0 + $1.quantity }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(totalQuantity > 0 ? "已選 \(totalQuantity) 件" : "尚未選花")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(appModel.cartTotalPriceText)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            Button {
                appModel.proceedToCart()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("前往購物車")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.black)
                )
            }
            .buttonStyle(.plain)
            .opacity(appModel.cartItems.isEmpty ? 0.45 : 1)
            .disabled(appModel.cartItems.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FigmaPalette.softPink.opacity(0.75))
        )
    }
}

private struct ClassicBouquetsPane: View {
    @ObservedObject var appModel: FigmaCustomerAppModel
    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                if appModel.availableBouquetProducts.isEmpty {
                    Text("Firestore 的 bouquets 暂时没有可展示的经典花束。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(appModel.availableBouquetProducts.prefix(6)) { product in
                            ClassicBouquetTile(
                                product: product,
                                stockText: appModel.stockText(for: product),
                                isSoldOut: appModel.isSoldOut(product),
                                isRestockReminderEnabled: appModel.isRestockReminderEnabled(for: product)
                            ) {
                                appModel.openProduct(product, from: .browse)
                            } onToggleRestockReminder: {
                                appModel.toggleRestockReminder(for: product)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                DIYPromptCard {
                    appModel.openDirectDIYFlow(from: .browse)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .padding(.vertical, 8)
        }
    }
}

private struct ProductDetailScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: appModel.activeTab, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Button {
                            appModel.closeOverlay()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(FigmaPalette.palePink)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        NotificationBellButton(
                            unreadCount: appModel.unreadNotificationCount,
                            size: 30,
                            action: appModel.openNotifications
                        )
                    }
                    .padding(.horizontal, 33)
                    .padding(.top, 22)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))
                        Text(appModel.selectedProduct.name)
                            .font(.system(size: 29, weight: .bold))
                        Text(appModel.selectedProduct.tagline)
                            .font(.system(size: 11, weight: .regular))
                    }
                    .padding(.horizontal, 55)
                    .padding(.top, 10)

                    ZStack(alignment: .topTrailing) {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(FigmaPalette.softPink)
                            .frame(height: 461)
                            .shadow(color: .white, radius: 10, x: 0, y: 4)

                        Button {
                            appModel.addSelectedProductToCart()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 29, height: 29)
                                Image(systemName: "cart")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!appModel.canIncrementCartQuantity(for: appModel.selectedProduct))
                        .opacity(appModel.canIncrementCartQuantity(for: appModel.selectedProduct) ? 1 : 0.45)
                        .padding(.top, 18)
                        .padding(.trailing, 20)

                        VStack(spacing: 16) {
                            RemoteAssetImage(
                                urlString: appModel.selectedProduct.imageURL,
                                fallbackSystemName: "gift.fill",
                                contentMode: .fit
                            )
                            .frame(width: 190, height: 190)
                            .padding(.top, 52)

                            Text(appModel.selectedProduct.priceText)
                                .font(.system(size: 15, weight: .bold))

                            Text(appModel.stockText(for: appModel.selectedProduct))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black.opacity(0.72))

                            VStack(spacing: 4) {
                                ForEach(appModel.selectedProduct.descriptionLines, id: \.self) { line in
                                    Text(line)
                                        .font(.system(size: line == appModel.selectedProduct.descriptionLines.first ? 16 : 14, weight: .regular))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.horizontal, 22)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 45)
                    .padding(.top, 18)

                    VStack(spacing: 12) {
                        SmallCapsuleButton(
                            title: "加入購物車",
                            filled: true,
                            isEnabled: appModel.canIncrementCartQuantity(for: appModel.selectedProduct)
                        ) {
                            appModel.addSelectedProductToCart()
                        }

                        SmallCapsuleButton(
                            title: "前往付款",
                            filled: false,
                            isEnabled: appModel.canIncrementCartQuantity(for: appModel.selectedProduct)
                        ) {
                            appModel.proceedToCheckout()
                        }

                        if appModel.isSoldOut(appModel.selectedProduct) {
                            RestockReminderToggle(
                                isSelected: appModel.isRestockReminderEnabled(for: appModel.selectedProduct)
                            ) {
                                appModel.toggleRestockReminder(for: appModel.selectedProduct)
                            }
                        }
                    }
                    .padding(.top, 14)
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 2) {
                        ForEach(appModel.selectedProduct.longDescription, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 13, weight: .regular))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
                    .padding(.horizontal, 46)
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct AssistantIntroScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .assistant, appModel: appModel) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Spacer()

                    NotificationBellButton(
                        unreadCount: appModel.unreadNotificationCount,
                        size: 30,
                        action: appModel.openNotifications
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text("蔚蘭園")
                        .font(.system(size: 14, weight: .regular))
                    Text("AI 聊天助手")
                        .font(.system(size: 29, weight: .bold))
                }
                .padding(.horizontal, 51)
                .padding(.top, 8)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle().stroke(FigmaPalette.softPink, lineWidth: 2)
                            )
                        RemoteAssetImage(
                            urlString: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787",
                            fallbackSystemName: "sparkles",
                            contentMode: .fit
                        )
                        .padding(10)
                    }
                    .frame(width: 49, height: 49)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 3) {
                            Circle().fill(Color.gray.opacity(0.25)).frame(width: 7, height: 7)
                            Circle().fill(Color.gray.opacity(0.25)).frame(width: 11, height: 11)
                            Circle().fill(Color.gray.opacity(0.25)).frame(width: 14, height: 14)
                        }

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                            .frame(width: 228, height: 56)
                            .overlay(alignment: .leading) {
                                Text("你好！我是你的 AI 花藝助手。我會按購買類型、對象、場合、顏色與預算逐步推薦。")
                                    .font(.system(size: 11, weight: .bold))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 14)
                            }

                        VStack(spacing: 12) {
                            if appModel.hasAssistantRecommendationProgress {
                                AssistantChoiceButton(title: "繼續上次推薦") {
                                    appModel.openCustomBouquetFlow(from: .assistant)
                                }

                                AssistantChoiceButton(title: "重新開始推薦") {
                                    appModel.startAssistantRecommendationFlow(from: .assistant)
                                }
                            } else {
                                AssistantChoiceButton(title: "開始推薦") {
                                    appModel.startAssistantRecommendationFlow(from: .assistant)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 21)
                .padding(.top, 44)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: 402)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct AssistantJourneyScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel
    @State private var pendingStep: Int?
    @State private var customRecipientText = ""
    @State private var customOccasionText = ""
    @State private var customColorText = ""

    private let purchaseTypeOptions = ["單枝花", "花束", "自訂"]
    private let recipientOptions = ["伴侶", "朋友", "家人", "同事"]
    private let occasionOptions = ["生日", "紀念日", "畢業", "感謝"]
    private let colorOptions = ["粉色", "白綠", "紅色", "暖黃色"]
    private let budgetOptions = ["小於港幣100元", "港幣100-200元", "港幣200-300元", "港幣300元以上"]
    private let assistantQuickPrompts = [
        "现在有哪些花材有货？",
        "预算 HKD 200 左右送朋友可以怎么选？",
        "帮我推荐适合生日的花束",
        "有哪些包装纸可以选？"
    ]

    var body: some View {
        MainScreenContainer(selectedTab: appModel.activeTab, appModel: appModel) {
            switch appModel.assistantFlowStage {
            case .chat:
                assistantChatContent
            case .diy(let step):
                DIYBouquetDesignContent(appModel: appModel, step: step)
            case .preview:
                DIYBouquetPreviewContent(appModel: appModel)
            }
        }
    }

    private var canConfirmCustomRecipient: Bool {
        !customRecipientText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canConfirmCustomOccasion: Bool {
        !customOccasionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canConfirmCustomColor: Bool {
        !customColorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var assistantChatContent: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        Button {
                            appModel.closeOverlay()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FigmaPalette.palePink)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        NotificationBellButton(
                            unreadCount: appModel.unreadNotificationCount,
                            size: 30,
                            action: appModel.openNotifications
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))
                        Text("AI 聊天助手")
                            .font(.system(size: 29, weight: .bold))
                    }
                    .padding(.horizontal, 51)

                    AssistantConversationBlock(
                        title: "你好！我是你的 AI 花藝助手。我會先整理你的需求，最後再根據真實資料庫給你推薦。請先選擇購買類型。",
                        iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                    ) {
                        if appModel.assistantConversationStep >= 1 {
                            OptionGrid(
                                options: purchaseTypeOptions,
                                selection: Binding(
                                    get: { appModel.selectedPurchaseType },
                                    set: { appModel.selectedPurchaseType = $0 }
                                )
                            ) { option in
                                choosePurchaseType(option)
                            }
                        }
                    }

                    if pendingStep == 2 {
                        TypingIndicatorBubble()
                    }

                    if appModel.assistantConversationStep >= 2 {
                        AssistantReplyBubble(text: "想找 \(appModel.selectedPurchaseType)。")

                        AssistantConversationBlock(
                            title: "收花對象是誰？你可以點選常見選項，也可以直接輸入。",
                            iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                        ) {
                            VStack(spacing: 12) {
                                OptionGrid(
                                    options: recipientOptions,
                                    selection: Binding(
                                        get: { appModel.selectedRecipient },
                                        set: { appModel.selectedRecipient = $0 }
                                    )
                                ) { option in
                                    chooseRecipient(option)
                                }

                                freeTextInput(
                                    text: $customRecipientText,
                                    placeholder: "或輸入其他收花對象",
                                    buttonTitle: "確認收花對象",
                                    isEnabled: canConfirmCustomRecipient,
                                    action: confirmCustomRecipient
                                )
                            }
                        }
                    }

                    if pendingStep == 3 {
                        TypingIndicatorBubble()
                    }

                    if appModel.assistantConversationStep >= 3 {
                        AssistantReplyBubble(text: "收花對象是 \(appModel.selectedRecipient)。")

                        AssistantConversationBlock(
                            title: "這次送花場合是什麼？你可以點選，也可以自行輸入。",
                            iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                        ) {
                            VStack(spacing: 12) {
                                OptionGrid(
                                    options: occasionOptions,
                                    selection: Binding(
                                        get: { appModel.selectedOccasion },
                                        set: { appModel.selectedOccasion = $0 }
                                    )
                                ) { option in
                                    chooseOccasion(option)
                                }

                                freeTextInput(
                                    text: $customOccasionText,
                                    placeholder: "或輸入其他送花場合",
                                    buttonTitle: "確認送花場合",
                                    isEnabled: canConfirmCustomOccasion,
                                    action: confirmCustomOccasion
                                )
                            }
                        }
                    }

                    if pendingStep == 4 {
                        TypingIndicatorBubble()
                    }

                    if appModel.assistantConversationStep >= 4 {
                        AssistantReplyBubble(text: "送花場合是 \(appModel.selectedOccasion)。")

                        AssistantConversationBlock(
                            title: "想偏向什麼顏色？你可以點選，也可以自行輸入。",
                            iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                        ) {
                            VStack(spacing: 12) {
                                OptionGrid(
                                    options: colorOptions,
                                    selection: Binding(
                                        get: { appModel.selectedColor },
                                        set: { appModel.selectedColor = $0 }
                                    )
                                ) { option in
                                    chooseColor(option)
                                }

                                freeTextInput(
                                    text: $customColorText,
                                    placeholder: "或輸入其他顏色偏好",
                                    buttonTitle: "確認顏色偏好",
                                    isEnabled: canConfirmCustomColor,
                                    action: confirmCustomColor
                                )
                            }
                        }
                    }

                    if pendingStep == 5 {
                        TypingIndicatorBubble()
                    }

                    if appModel.assistantConversationStep >= 5 {
                        AssistantReplyBubble(text: "顏色偏好是 \(appModel.selectedColor)。")

                        AssistantConversationBlock(
                            title: "最後一題，請選擇預算範圍。完成後我會根據真實資料庫整理推薦。",
                            iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                        ) {
                            OptionGrid(
                                options: budgetOptions,
                                selection: Binding(
                                    get: { appModel.selectedBudget },
                                    set: { appModel.selectedBudget = $0 }
                                )
                            ) { option in
                                chooseBudget(option)
                            }
                        }
                    }

                    if pendingStep == 6 || appModel.isGeneratingAssistantRecommendation {
                        TypingIndicatorBubble(text: "我正在根據真實資料庫整理最後推薦...")
                    }

                    if appModel.assistantConversationStep >= 6 {
                        AssistantReplyBubble(text: "預算範圍是 \(appModel.selectedBudget)。")

                        AssistantConversationBlock(
                            title: "這是我根據你剛剛的選擇，結合資料庫整理出的最後推薦。",
                            iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                        ) {
                            VStack(spacing: 12) {
                                if let recommendation = appModel.assistantRecommendationText {
                                    AssistantSummaryBubble(
                                        title: "AI 推薦",
                                        summaryText: recommendation
                                    )
                                } else if let errorMessage = appModel.assistantErrorMessage {
                                    AssistantSummaryBubble(
                                        title: "AI 暫時不可用",
                                        summaryText: errorMessage
                                    )

                                    AssistantRecommendationBubble(
                                        suggestedDesign: appModel.suggestedDesignText,
                                        recommendedFlowers: appModel.recommendedFlowerTypes,
                                        estimatedPrice: appModel.estimatedPriceText,
                                        browseLinkTitle: "先去 DIY 挑花材",
                                        onOpenBrowse: appModel.proceedToDIYDesigner
                                    )
                                }

                                HStack(spacing: 10) {
                                    AssistantChoiceButton(title: "進入 DIY 選花") {
                                        appModel.proceedToDIYDesigner()
                                    }

                                    AssistantChoiceButton(title: "重新選擇") {
                                        appModel.resetAssistantSelections()
                                        appModel.resetAssistantChat()
                                        syncCustomInputsFromSelection()
                                        pendingStep = nil
                                    }
                                }
                            }
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("assistant-bottom")
                }
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: appModel.assistantConversationStep) {
                scrollToBottom(proxy)
            }
            .onChange(of: pendingStep) {
                scrollToBottom(proxy)
            }
            .task {
                syncCustomInputsFromSelection()
                if appModel.assistantConversationStep < 1 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        appModel.assistantConversationStep = 1
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func freeTextInput(
        text: Binding<String>,
        placeholder: String,
        buttonTitle: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 10) {
            SoftInputField(text: text, placeholder: placeholder)
                .onSubmit {
                    action()
                }

            SoftActionButton(title: buttonTitle, isEnabled: isEnabled) {
                action()
            }
            .frame(maxWidth: 160)
        }
    }

    private func syncCustomInputsFromSelection() {
        customRecipientText = recipientOptions.contains(appModel.selectedRecipient) ? "" : appModel.selectedRecipient
        customOccasionText = occasionOptions.contains(appModel.selectedOccasion) ? "" : appModel.selectedOccasion
        customColorText = colorOptions.contains(appModel.selectedColor) ? "" : appModel.selectedColor
    }

    private func choosePurchaseType(_ option: String) {
        appModel.selectedPurchaseType = option
        reveal(step: 2)
    }

    private func chooseRecipient(_ option: String) {
        customRecipientText = ""
        appModel.selectedRecipient = option
        reveal(step: 3)
    }

    private func confirmCustomRecipient() {
        let trimmedRecipient = customRecipientText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRecipient.isEmpty else { return }
        appModel.selectedRecipient = trimmedRecipient
        reveal(step: 3)
    }

    private func chooseOccasion(_ option: String) {
        customOccasionText = ""
        appModel.selectedOccasion = option
        reveal(step: 4)
    }

    private func confirmCustomOccasion() {
        let trimmedOccasion = customOccasionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOccasion.isEmpty else { return }
        appModel.selectedOccasion = trimmedOccasion
        reveal(step: 4)
    }

    private func chooseColor(_ option: String) {
        customColorText = ""
        appModel.selectedColor = option
        reveal(step: 5)
    }

    private func confirmCustomColor() {
        let trimmedColor = customColorText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedColor.isEmpty else { return }
        appModel.selectedColor = trimmedColor
        reveal(step: 5)
    }

    private func chooseBudget(_ option: String) {
        appModel.selectedBudget = option
        pendingStep = 6
        appModel.clearAssistantRecommendation()
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            await appModel.generateAssistantRecommendation()
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    appModel.assistantConversationStep = 6
                }
                pendingStep = nil
            }
        }
    }

    private func reveal(step: Int) {
        guard appModel.assistantConversationStep < step else { return }
        pendingStep = step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.25)) {
                appModel.assistantConversationStep = step
            }
            pendingStep = nil
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("assistant-bottom", anchor: .bottom)
            }
        }
    }
}

private struct CartScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .cart, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))

                        Spacer()

                        NotificationBellButton(
                            unreadCount: appModel.unreadNotificationCount,
                            size: 28,
                            action: appModel.openNotifications
                        )
                    }
                    .padding(.top, 18)

                    Text("購物車")
                        .font(.system(size: 29, weight: .bold))

                    if appModel.cartItems.isEmpty {
                        EmptyCartCard {
                            appModel.selectTab(.browse)
                        }
                    } else {
                        VStack(spacing: 16) {
                            ForEach(appModel.cartItems) { item in
                                CartItemCard(
                                    item: item,
                                    stockText: appModel.stockText(for: item.product),
                                    canIncrement: appModel.canIncrementCartQuantity(for: item.product),
                                    onIncrement: {
                                        appModel.addProductToCart(item.product)
                                    },
                                    onDecrement: {
                                        appModel.removeProductFromCart(item.product)
                                    }
                                )
                            }

                            VStack(spacing: 10) {
                                HStack {
                                    Text("合計")
                                        .font(.system(size: 18, weight: .bold))
                                    Spacer()
                                    Text(totalPriceText)
                                        .font(.system(size: 22, weight: .bold))
                                }

                                SoftActionButton(title: "前往付款", isEnabled: true) {
                                    appModel.openCheckout()
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(FigmaPalette.softPink.opacity(0.55))
                            )
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }

    private var totalPriceText: String {
        let total = appModel.cartItems.reduce(0) { partial, item in
            partial + numericPrice(from: item.product.priceText) * item.quantity
        }
        return "HKD \(total)"
    }

    private func numericPrice(from priceText: String) -> Int {
        Int(priceText.replacingOccurrences(of: "HKD ", with: "")) ?? 0
    }
}

private struct CheckoutScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .cart, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    FigmaHeader(
                        brand: "蔚蘭園",
                        title: "結賬頁面",
                        subtitle: nil,
                        showBack: true,
                        showBell: true,
                        unreadNotificationCount: appModel.unreadNotificationCount,
                        onBellTap: appModel.openNotifications,
                        onBack: appModel.dismissCheckout
                    )
                    .padding(.top, 18)

                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 17, weight: .regular))
                        VStack(spacing: 0) {
                            Text("到店自取")
                                .font(.system(size: 18, weight: .bold))
                            Text("暫不支持配送")
                                .font(.system(size: 9, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    CheckoutSummaryCard(appModel: appModel)

                    Button(action: appModel.toggleCheckoutPriceDetails) {
                        Text(appModel.isShowingCheckoutPriceDetails ? "點擊收起價格明細" : "點擊展開價格明細")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, -8)

                    if appModel.isShowingCheckoutPriceDetails {
                        CheckoutPriceBreakdownCard(appModel: appModel)
                    } else {
                        VStack(alignment: .leading, spacing: 18) {
                            CheckoutInfoSection(
                                title: "地點：",
                                value: appModel.checkoutPickupLocation
                            )

                            CheckoutInfoSection(
                                title: "預計取貨時間",
                                value: appModel.checkoutPickupTimeText
                            )

                            VStack(alignment: .leading, spacing: 8) {
                                Text("備註：")
                                    .font(.system(size: 12, weight: .bold))

                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.black, lineWidth: 1)
                                    .frame(height: 62)
                                    .overlay(alignment: .leading) {
                                        Text(appModel.checkoutSpecialRequests)
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 16)
                                            .lineLimit(2)
                                    }
                            }

                            Text(appModel.checkoutPickupWindowText)
                                .font(.system(size: 15, weight: .regular))

                            CheckoutPaymentMethodCard(appModel: appModel)

                            SoftActionButton(
                                title: appModel.isSubmittingPayment
                                    ? "模擬付款中..."
                                    : "模擬付款（\(appModel.selectedPaymentMethod.rawValue)）",
                                isEnabled: !appModel.isSubmittingPayment
                            ) {
                                appModel.submitDemoPayment()
                            }

                            Text("演示用假支付，不會真的扣款；付款成功後會把訂單寫入 Firebase。")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)

                            if let paymentErrorMessage = appModel.paymentErrorMessage {
                                Text(paymentErrorMessage)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
    }
}

private struct CheckoutSummaryCard: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(FigmaPalette.softPink)
            .overlay {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white)
                        .frame(width: 118, height: 106)
                        .overlay {
                            RemoteAssetImage(
                                urlString: appModel.checkoutProductImageURL,
                                fallbackSystemName: "gift.fill",
                                contentMode: .fit
                            )
                            .padding(14)
                        }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(appModel.checkoutProductTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        Text(appModel.checkoutProductSubtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)

                        HStack(alignment: .bottom) {
                            if let primaryItem = appModel.checkoutPrimaryItem,
                               appModel.cartItems.count == 1 {
                                QuantityControl(
                                    quantity: primaryItem.quantity,
                                    onIncrement: {
                                        appModel.addProductToCart(primaryItem.product)
                                    },
                                    onDecrement: {
                                        appModel.removeProductFromCart(primaryItem.product)
                                    },
                                    canIncrement: appModel.canIncrementCartQuantity(for: primaryItem.product),
                                    canDecrement: primaryItem.quantity > 0,
                                    style: .compact
                                )
                            } else {
                                Text("共 \(appModel.cartItems.reduce(0) { $0 + $1.quantity }) 件")
                                    .font(.system(size: 12, weight: .bold))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(appModel.cartTotalPriceText)
                                    .font(.system(size: 18, weight: .bold))
                                if let primaryItem = appModel.checkoutPrimaryItem {
                                    Text(appModel.stockText(for: primaryItem.product))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.black.opacity(0.65))
                                }
                                Text("點擊展開價格明細")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .frame(height: 133)
    }
}

private struct CheckoutInfoSection: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct CheckoutPriceBreakdownCard: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1.2)
            )
            .shadow(color: FigmaPalette.softPink.opacity(0.55), radius: 14, x: 0, y: 6)
            .overlay {
                VStack(spacing: 18) {
                    Text("價格明細")
                        .font(.system(size: 20, weight: .bold))

                    ForEach(appModel.checkoutBreakdownLines) { line in
                        VStack(spacing: 6) {
                            Text(line.title)
                                .font(.system(size: 15, weight: .bold))
                            Text(line.detail)
                                .font(.system(size: 14, weight: .bold))
                            Text("= HKD \(Int(line.amount.rounded()))")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }

                    Divider()

                    HStack {
                        Text("總計")
                            .font(.system(size: 16, weight: .bold))
                        Spacer()
                        Text(appModel.cartTotalPriceText)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 26)
            }
            .frame(minHeight: 340)
    }
}

private struct CheckoutPaymentMethodCard: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1.2)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white)
            )
            .overlay {
                VStack(spacing: 0) {
                    ForEach(Array(CheckoutPaymentMethod.allCases.enumerated()), id: \.offset) { index, method in
                        CheckoutPaymentMethodRow(
                            method: method,
                            isSelected: appModel.selectedPaymentMethod == method
                        ) {
                            appModel.selectPaymentMethod(method)
                        }

                        if index < CheckoutPaymentMethod.allCases.count - 1 {
                            Divider()
                                .padding(.leading, 28)
                                .padding(.trailing, 18)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .frame(minHeight: 236)
    }
}

private struct CheckoutPaymentMethodRow: View {
    let method: CheckoutPaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: method.iconName)
                    .font(.system(size: 19, weight: .regular))
                    .foregroundColor(FigmaPalette.hotPink)
                    .frame(width: 24)

                Text(method.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 26)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }
}

private struct OrderTrackingScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .cart, appModel: appModel) {
            if let order = appModel.submittedTrackingOrder {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        HStack(alignment: .top) {
                            Button(action: appModel.dismissTracking) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(FigmaPalette.palePink)
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            NotificationBellButton(
                                unreadCount: appModel.unreadNotificationCount,
                                size: 30,
                                action: appModel.openNotifications
                            )
                        }
                        .padding(.top, 18)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("付款成功")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(FigmaPalette.hotPink)

                            Text("訂單已建立")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.black)

                            Text("花藝師已收到你的訂單，以下是目前的配送與取貨安排。")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        OrderTrackingSummaryCard(order: order)

                        VStack(spacing: 12) {
                            TrackingMetaCard(
                                iconName: "number",
                                title: "訂單號碼",
                                value: order.sourceOrderId
                            )
                            TrackingMetaCard(
                                iconName: "calendar",
                                title: "下單時間",
                                value: dateTimeText(from: order.createdAt)
                            )
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            Text("配送 / 取貨資訊")
                                .font(.system(size: 18, weight: .bold))

                            CheckoutInfoSection(
                                title: "地點",
                                value: order.pickupLocation
                            )

                            CheckoutInfoSection(
                                title: "預計取貨時間",
                                value: "\(dateText(from: order.pickupDate)) · \(order.pickupWindowText)"
                            )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .fill(FigmaPalette.softPink.opacity(0.26))
                        )

                        if !order.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("備註")
                                    .font(.system(size: 14, weight: .bold))
                                Text(order.note)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black.opacity(0.78))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1)
                                    )
                            )
                        }

                        VStack(alignment: .leading, spacing: 18) {
                            Text("訂單進度")
                                .font(.system(size: 18, weight: .bold))

                            ForEach(Array(progressSteps(for: order).enumerated()), id: \.offset) { index, step in
                                OrderTimelineStepView(
                                    step: step,
                                    isLast: index == progressSteps(for: order).count - 1
                                )
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                                        .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1.2)
                                )
                                .shadow(color: FigmaPalette.softPink.opacity(0.45), radius: 12, x: 0, y: 6)
                        )

                        SoftActionButton(title: "返回首頁", isEnabled: true) {
                            appModel.dismissTracking()
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 26)
                    .frame(maxWidth: 402)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            } else {
                VStack(spacing: 18) {
                    Text("目前沒有可顯示的訂單進度。")
                        .font(.system(size: 18, weight: .bold))
                    SoftActionButton(title: "返回首頁", isEnabled: true) {
                        appModel.dismissTracking()
                    }
                }
                .padding(32)
            }
        }
    }

    private func progressSteps(for order: StorefrontTrackingOrder) -> [TrackingStep] {
        let preparingDate = order.createdAt.addingTimeInterval(60 * 60)
        let readyDate = order.createdAt.addingTimeInterval(110 * 60)

        return [
            TrackingStep(
                title: "系統接收到訂單 · \(timeText(from: order.createdAt))",
                subtitle: "你的訂單已確認",
                isCompleted: true
            ),
            TrackingStep(
                title: "花束準備中 · \(timeText(from: preparingDate))",
                subtitle: "花藝師正在製作你的花束",
                isCompleted: true
            ),
            TrackingStep(
                title: "可到店取貨 · \(timeText(from: readyDate))",
                subtitle: "你可以到店取花，取單號碼\(order.sourceOrderId.replacingOccurrences(of: "#", with: ""))",
                isCompleted: true
            ),
            TrackingStep(
                title: "已取貨",
                subtitle: "預計取貨時間：\(order.pickupWindowText)",
                isCompleted: false
            )
        ]
    }

    private func timeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateTimeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func dateText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

private struct OrderTrackingSummaryCard: View {
    let order: StorefrontTrackingOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 116, height: 116)
                    .overlay {
                        RemoteAssetImage(
                            urlString: order.primaryItem?.imageURL ?? "",
                            fallbackSystemName: "gift.fill",
                            contentMode: .fit
                        )
                        .padding(14)
                    }

                VStack(alignment: .leading, spacing: 8) {
                    OrderStatusBadge(statusText: "待取貨")

                    Text(order.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("付款方式 · \(order.paymentMethod.rawValue)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("總額 HKD \(Int(order.totalPrice.rounded()))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }

                Spacer(minLength: 0)
            }

            if !order.items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("訂單內容")
                        .font(.system(size: 14, weight: .bold))
                    ForEach(order.items) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("x\(item.quantity)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(FigmaPalette.softPink)
        )
    }
}

private struct TrackingMetaCard: View {
    let iconName: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(FigmaPalette.hotPink)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1)
                )
        )
    }
}

private struct OrderTimelineStepView: View {
    let step: TrackingStep
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(step.isCompleted ? FigmaPalette.softPink : Color.white)
                        .frame(width: 28, height: 28)
                    Image(systemName: step.isCompleted ? "checkmark" : "clock")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(step.isCompleted ? FigmaPalette.hotPink : .gray)
                }

                if !isLast {
                    Rectangle()
                        .fill(step.isCompleted ? FigmaPalette.softPink : Color.gray.opacity(0.25))
                        .frame(width: 2, height: 44)
                        .padding(.top, 6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Text(step.subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct TrackingStep {
    let title: String
    let subtitle: String
    let isCompleted: Bool
}

private struct OrderHistoryScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .profile, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        Button(action: appModel.closeOverlay) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FigmaPalette.palePink)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))

                        Spacer()
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("歷史訂單")
                            .font(.system(size: 29, weight: .bold))

                        Text("查看這位用戶的所有歷史訂單與目前狀態。")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }

                    if appModel.isLoadingUserOrders && appModel.userOrders.isEmpty {
                        VStack(spacing: 14) {
                            ProgressView()
                            Text("正在載入你的歷史訂單...")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                    } else if let errorMessage = appModel.userOrdersErrorMessage,
                              appModel.userOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("訂單暫時載入失敗")
                                .font(.system(size: 18, weight: .bold))
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            SoftActionButton(title: "重新整理", isEnabled: true) {
                                appModel.openOrderHistory()
                            }
                        }
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(FigmaPalette.softPink.opacity(0.24))
                        )
                    } else if appModel.userOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("暫時未有歷史訂單")
                                .font(.system(size: 18, weight: .bold))
                            Text("完成下單後，這裡會顯示所有訂單與對應狀態。")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        .padding(22)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(FigmaPalette.softPink.opacity(0.24))
                        )
                    } else {
                        Text("共 \(appModel.userOrders.count) 筆訂單")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)

                        ForEach(Array(appModel.userOrders.enumerated()), id: \.offset) { _, order in
                            OrderHistoryCard(order: order, appModel: appModel)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct OrderHistoryCard: View {
    let order: OrderData
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.bouquetData.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(order.sourceOrderId ?? "未有訂單號碼")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                OrderStatusBadge(statusText: order.status)
            }

            VStack(alignment: .leading, spacing: 10) {
                OrderHistoryInfoRow(title: "下單時間", value: dateTimeText(from: order.createdAt))
                OrderHistoryInfoRow(title: "送貨日期", value: dateTimeText(from: order.deliveryDate))
                OrderHistoryInfoRow(title: "收貨資料", value: "\(order.customerName) · \(order.customerPhone)")
                OrderHistoryInfoRow(title: "地址", value: order.deliveryAddress)
                OrderHistoryInfoRow(title: "總額", value: "HKD \(Int(order.bouquetData.totalPrice.rounded()))")
            }

            if !order.bouquetData.items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("花禮內容")
                        .font(.system(size: 14, weight: .bold))

                    ForEach(Array(order.bouquetData.items.prefix(4).enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(item.flowerEmoji) \(item.flowerName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text("x\(item.quantity)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black.opacity(0.7))
                        }
                    }

                    if order.bouquetData.items.count > 4 {
                        Text("另有 \(order.bouquetData.items.count - 4) 項花材")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            if order.status == OrderStatus.cancelled.rawValue {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(red: 0.13, green: 0.31, blue: 0.67))
                    Text("退款已原路返回")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.13, green: 0.31, blue: 0.67))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.87, green: 0.92, blue: 1.0))
                )
            } else if appModel.canCancelOrder(order) {
                Button {
                    appModel.cancelPendingOrder(order)
                } label: {
                    HStack(spacing: 8) {
                        if appModel.cancellingOrderID == order.id {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(appModel.cancellingOrderID == order.id ? "取消中..." : "取消訂單")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                }
                .buttonStyle(.bordered)
                .tint(Color(red: 0.70, green: 0.34, blue: 0.51))
                .disabled(appModel.cancellingOrderID == order.id)
            }

            if !order.specialRequests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("備註")
                        .font(.system(size: 13, weight: .bold))
                    Text(order.specialRequests)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(FigmaPalette.softPink.opacity(0.8), lineWidth: 1)
                )
                .shadow(color: FigmaPalette.softPink.opacity(0.35), radius: 10, x: 0, y: 5)
        )
    }

    private func dateTimeText(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }
}

private struct OrderHistoryInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ProfileScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .profile, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        Color.clear
                            .frame(width: 28, height: 28)

                        Spacer()

                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))

                        Spacer()

                        Button(action: appModel.openProfileEditor) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 16)

                    Text("用戶資料")
                        .font(.system(size: 29, weight: .bold))
                        .frame(maxWidth: .infinity)

                    HStack(alignment: .top, spacing: 30) {
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.18))
                                    .frame(width: 66, height: 66)
                                RemoteAssetImage(
                                    urlString: "https://www.figma.com/api/mcp/asset/70697015-d51b-45e8-9f4b-c325f0020d25",
                                    fallbackSystemName: "person.fill",
                                    contentMode: .fit
                                )
                                .frame(width: 39, height: 39)
                            }

                            Text(appModel.profileDisplayName)
                                .font(.system(size: 13, weight: .regular))
                        }

                        Button {
                            appModel.openFarm()
                        } label: {
                            VStack(spacing: 10) {
                                RemoteAssetImage(
                                    urlString: "https://www.figma.com/api/mcp/asset/f891dc4f-4ea4-459c-87d3-7541f282893f",
                                    fallbackSystemName: "leaf.circle",
                                    contentMode: .fill
                                )
                                .frame(width: 118, height: 115)
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                                Text("管理我的花園")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.black)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 16) {
                        ProfileInfoRow(title: "名稱", value: appModel.profileDisplayName, action: appModel.openProfileEditor)
                        ProfileInfoRow(title: "電郵", value: appModel.profileEmailText, action: appModel.openProfileEditor)
                        ProfileInfoRow(title: "電話號碼", value: appModel.profilePhoneText, action: appModel.openProfileEditor)

                        if appModel.isLoadingProfile {
                            Text("正在同步你的個人資料...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        } else if let profileError = appModel.profileSaveErrorMessage,
                                  appModel.profileRecord == nil {
                            Text(profileError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("我的訂單")
                            .font(.system(size: 14, weight: .bold))

                        Button(action: appModel.openOrderHistory) {
                            ProfileDetailLine(
                                icon: "📦",
                                title: "訂單紀錄",
                                subtitle: orderSubtitle,
                                showsChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        ProfileDetailLine(
                            icon: "📍",
                            title: "送貨地址",
                            subtitle: "管理已儲存的地址",
                            showsChevron: false
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔔 通知")
                            .font(.system(size: 14, weight: .bold))
                        Text("🙋幫助與支援")
                            .font(.system(size: 14, weight: .bold))
                        ProfileDetailLine(icon: "💬", title: "聯絡店舖", subtitle: nil, showsChevron: false)
                        ProfileDetailLine(
                            icon: "❓",
                            title: "常見問題",
                            subtitle: "關於訂單與送貨的常見問題。",
                            showsChevron: false
                        )
                    }

                    Button {
                        appModel.logout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 15, weight: .bold))

                            Text("登出帳戶")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(FigmaPalette.hotPink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(FigmaPalette.hotPink.opacity(0.35), lineWidth: 1)
                        )
                        .shadow(color: FigmaPalette.softPink.opacity(0.45), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var orderSubtitle: String {
        if appModel.isLoadingUserOrders {
            return "正在載入你的訂單..."
        }

        if let errorMessage = appModel.userOrdersErrorMessage,
           appModel.userOrders.isEmpty {
            return errorMessage
        }

        if appModel.userOrders.isEmpty {
            return "查看過往訂單與目前狀態"
        }

        return "共 \(appModel.userOrders.count) 筆訂單，查看全部狀態"
    }
}

private struct ProfileEditScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .profile, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        Button(action: appModel.closeOverlay) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(FigmaPalette.palePink)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))

                        Spacer()
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("編輯資料")
                            .font(.system(size: 29, weight: .bold))

                        Text("修改後會同步到個人頁面，後續下單也會優先使用這些聯絡資料。")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        ProfileEditorField(
                            title: "名稱",
                            placeholder: "例如：陳小美",
                            text: $appModel.profileDraftName
                        )

                        ProfileEditorField(
                            title: "聯絡電郵",
                            placeholder: "name@example.com",
                            text: $appModel.profileDraftEmail,
                            keyboardType: .emailAddress
                        )

                        ProfileEditorField(
                            title: "電話號碼",
                            placeholder: "+852 9123 4567",
                            text: $appModel.profileDraftPhone,
                            keyboardType: .phonePad
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .stroke(FigmaPalette.softPink.opacity(0.75), lineWidth: 1)
                            )
                    )

                    if let errorMessage = appModel.profileSaveErrorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    SoftActionButton(
                        title: appModel.isSavingProfile ? "儲存中..." : "儲存修改",
                        isEnabled: appModel.canSaveProfileChanges,
                        action: appModel.saveProfileChanges
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct ProfileEditorField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .autocorrectionDisabled(keyboardType == .emailAddress)
                .padding(.horizontal, 16)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(FigmaPalette.softPink.opacity(0.24))
                )
        }
    }
}

private struct OrderStatusBadge: View {
    let statusText: String

    var body: some View {
        Text(statusText)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundColor)
            )
    }

    private var foregroundColor: Color {
        switch statusText {
        case OrderStatus.pending.rawValue, "待取貨":
            return Color(red: 0.70, green: 0.34, blue: 0.51)
        case OrderStatus.confirmed.rawValue, OrderStatus.preparing.rawValue:
            return Color(red: 0.14, green: 0.40, blue: 0.31)
        case OrderStatus.ready.rawValue, OrderStatus.delivered.rawValue:
            return Color(red: 0.13, green: 0.31, blue: 0.67)
        case OrderStatus.cancelled.rawValue:
            return Color(red: 0.45, green: 0.29, blue: 0.29)
        default:
            return .black
        }
    }

    private var backgroundColor: Color {
        switch statusText {
        case OrderStatus.pending.rawValue, "待取貨":
            return FigmaPalette.softPink.opacity(0.8)
        case OrderStatus.confirmed.rawValue, OrderStatus.preparing.rawValue:
            return Color(red: 0.86, green: 0.96, blue: 0.90)
        case OrderStatus.ready.rawValue, OrderStatus.delivered.rawValue:
            return Color(red: 0.87, green: 0.92, blue: 1.0)
        case OrderStatus.cancelled.rawValue:
            return Color(red: 0.97, green: 0.90, blue: 0.90)
        default:
            return Color.gray.opacity(0.15)
        }
    }
}

private struct FarmScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .profile, appModel: appModel) {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .top) {
                    Button {
                        appModel.closeOverlay()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FigmaPalette.palePink)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("蔚蘭園")
                        .font(.system(size: 14, weight: .regular))

                    Spacer()

                    Image(systemName: "info.circle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(.black)
                }
                .padding(.top, 16)

                Text("我的花園")
                    .font(.system(size: 29, weight: .bold))
                    .frame(maxWidth: .infinity)

                RemoteAssetImage(
                    urlString: "https://www.figma.com/api/mcp/asset/49ae62df-e45f-47b4-baac-8d079a0ba448",
                    fallbackSystemName: "leaf.fill",
                    contentMode: .fill
                )
                .frame(height: 315)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 402)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

private struct MainScreenContainer<Content: View>: View {
    let selectedTab: FigmaCustomerAppModel.MainTab
    @ObservedObject var appModel: FigmaCustomerAppModel
    @ViewBuilder let content: Content

    init(
        selectedTab: FigmaCustomerAppModel.MainTab,
        appModel: FigmaCustomerAppModel,
        @ViewBuilder content: () -> Content
    ) {
        self.selectedTab = selectedTab
        self.appModel = appModel
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                Color.white
                    .frame(height: proxy.safeAreaInsets.top)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .ignoresSafeArea(edges: .top)
            }
            .allowsHitTesting(false)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FigmaBottomNavBar(selectedTab: selectedTab) { tab in
                appModel.selectTab(tab)
            }
            .padding(.bottom, 8)
        }
    }
}

private struct NotificationBellIcon: View {
    let unreadCount: Int
    var size: CGFloat = 30

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell.fill")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(.black)

            if unreadCount > 0 {
                Text(unreadBadgeText)
                    .font(.system(size: max(9, size * 0.28), weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: max(16, size * 0.5), minHeight: max(16, size * 0.5))
                    .padding(.horizontal, unreadCount > 9 ? 4 : 0)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.black)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white, lineWidth: 1.2)
                    )
                    .offset(x: size * 0.14, y: -size * 0.12)
            }
        }
        .frame(width: size + 6, height: size + 4, alignment: .center)
    }

    private var unreadBadgeText: String {
        unreadCount > 99 ? "99+" : "\(unreadCount)"
    }
}

private struct NotificationBellButton: View {
    let unreadCount: Int
    var size: CGFloat = 30
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            NotificationBellIcon(unreadCount: unreadCount, size: size)
        }
        .buttonStyle(.plain)
    }
}

private struct FigmaHeader: View {
    let brand: String
    let title: String
    let subtitle: String?
    let showBack: Bool
    let showBell: Bool
    var unreadNotificationCount = 0
    var onBellTap: (() -> Void)? = nil
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                if showBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FigmaPalette.palePink)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if showBell {
                    NotificationBellButton(
                        unreadCount: unreadNotificationCount,
                        size: 30,
                        action: onBellTap ?? {}
                    )
                }
            }

            Text(brand)
                .font(.system(size: 14, weight: .regular))

            Text(title)
                .font(.system(size: 29, weight: .bold))
                .lineSpacing(2)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
            }
        }
    }
}

private struct PromoCard: View {
    let title: String
    let subtitle: String
    let imageURL: String
    let width: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .leading) {
                RemoteAssetImage(
                    urlString: imageURL,
                    fallbackSystemName: "leaf.circle.fill",
                    contentMode: .fill
                )
                .frame(width: width, height: 93)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.10),
                        Color.black.opacity(0.36)
                    ],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .frame(width: width, height: 93)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .frame(width: width, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct BrowseModeTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? FigmaPalette.softPink.opacity(0.8) : Color.gray.opacity(0.08))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct BrowsePromptCard: View {
    let onCreate: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(FigmaPalette.hotPink)

            Text("找不到理想的花束？")
                .font(.system(size: 16, weight: .bold))

            Text("只需幾個步驟，\n打造專屬花束。")
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)

            Button("前往定製您的專屬花束", action: onCreate)
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(FigmaPalette.hotPink)
                .underline()

            Button("返回", action: onClose)
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: 179)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

private struct ClassicBouquetCard: View {
    let product: BouquetProduct
    let onOpen: () -> Void
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(FigmaPalette.softPink.opacity(0.75))
                .frame(width: 116, height: 116)
                .overlay {
                    RemoteAssetImage(
                        urlString: product.imageURL,
                        fallbackSystemName: "gift.fill",
                        contentMode: .fit
                    )
                    .padding(10)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text(product.tagline)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text(product.priceText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                HStack(spacing: 10) {
                    Button(action: onOpen) {
                        Capsule(style: .continuous)
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 72, height: 30)
                            .overlay {
                                Text("查看")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                            }
                    }
                    .buttonStyle(.plain)

                    Button(action: onAdd) {
                        Capsule(style: .continuous)
                            .fill(Color.black)
                            .frame(width: 72, height: 30)
                            .overlay {
                                Text("加入")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(FigmaPalette.softPink, lineWidth: 1)
                )
        )
    }
}

private struct ClassicBouquetTile: View {
    let product: BouquetProduct
    let stockText: String
    let isSoldOut: Bool
    let isRestockReminderEnabled: Bool
    let action: () -> Void
    let onToggleRestockReminder: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .fill(FigmaPalette.softPink.opacity(0.55))
                            .frame(height: 164)

                        RemoteAssetImage(
                            urlString: product.imageURL,
                            fallbackSystemName: "gift.fill",
                            contentMode: .fit
                        )
                        .padding(18)
                        .frame(height: 146)
                    }

                    VStack(spacing: 4) {
                        Text(product.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                        Text(product.priceText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black.opacity(0.72))
                        Text(stockText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSoldOut ? .red.opacity(0.82) : .black.opacity(0.6))
                    }
                }
            }
            .buttonStyle(.plain)

            if isSoldOut {
                RestockReminderToggle(
                    isSelected: isRestockReminderEnabled,
                    action: onToggleRestockReminder
                )
            }
        }
    }
}

private struct DIYPromptCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(FigmaPalette.hotPink)

            Text("找不到理想的花束？")
                .font(.system(size: 16, weight: .bold))

            Text("只需幾個步驟，\n打造專屬花束。")
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)

            Button("前往定製您的專屬花束", action: action)
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(FigmaPalette.hotPink)
                .underline()

            Text("或使用右上角 DIY 入口")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.black.opacity(0.58))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(FigmaPalette.softPink, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 12, x: 0, y: 6)
    }
}

private struct AssistantChoiceButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                .frame(width: 154, height: 35)
                .overlay {
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct AssistantPromptChip: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(FigmaPalette.softPink.opacity(0.85))
                )
        }
        .buttonStyle(.plain)
    }
}

private struct AssistantConversationBlock<Content: View>: View {
    let title: String
    let iconURL: String
    @ViewBuilder let content: Content

    init(
        title: String,
        iconURL: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.iconURL = iconURL
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(FigmaPalette.softPink, lineWidth: 2))
                    .frame(width: 49, height: 49)

                RemoteAssetImage(
                    urlString: iconURL,
                    fallbackSystemName: "sparkles",
                    contentMode: .fit
                )
                .padding(10)
                .frame(width: 49, height: 49)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 3) {
                    Circle().fill(Color.gray.opacity(0.25)).frame(width: 7, height: 7)
                    Circle().fill(Color.gray.opacity(0.25)).frame(width: 11, height: 11)
                    Circle().fill(Color.gray.opacity(0.25)).frame(width: 14, height: 14)
                }
                .padding(.leading, 6)

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 13)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
                    )

                content
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct AssistantReplyBubble: View {
    let text: String

    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                )

            ZStack {
                Circle()
                    .fill(FigmaPalette.softPink.opacity(0.55))
                    .frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black.opacity(0.75))
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct OptionGrid: View {
    let options: [String]
    @Binding var selection: String
    var onSelect: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            ForEach(optionRows.indices, id: \.self) { rowIndex in
                let row = optionRows[rowIndex]

                if row.count == 1 {
                    HStack {
                        Spacer()
                        optionButton(row[0], isSingle: true)
                        Spacer()
                    }
                } else {
                    HStack(spacing: 10) {
                        ForEach(row, id: \.self) { option in
                            optionButton(option, isSingle: false)
                        }
                    }
                }
            }
        }
    }

    private var optionRows: [[String]] {
        stride(from: 0, to: options.count, by: 2).map { index in
            Array(options[index..<min(index + 2, options.count)])
        }
    }

    private func optionButton(_ option: String, isSingle: Bool) -> some View {
        Button {
            selection = option
            onSelect?(option)
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(selection == option ? FigmaPalette.softPink : Color(red: 0.95, green: 0.95, blue: 0.95))
                .frame(width: isSingle ? 116 : nil, height: 35)
                .frame(maxWidth: isSingle ? nil : .infinity)
                .overlay {
                    Text(option)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
        }
        .buttonStyle(.plain)
    }
}

private struct TypingIndicatorBubble: View {
    var text = "正在整理你的需求..."

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(FigmaPalette.softPink, lineWidth: 2))
                    .frame(width: 49, height: 49)

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black.opacity(0.72))
            }

            HStack(spacing: 10) {
                ProgressView()
                    .tint(.black.opacity(0.7))
                Text(text)
                    .font(.system(size: 11, weight: .bold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
            )
        }
        .padding(.horizontal, 24)
    }
}

private struct AssistantSummaryBubble: View {
    let title: String
    let summaryText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Text(summaryText)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.black.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
        )
    }
}

private struct AssistantRecommendationBubble: View {
    let suggestedDesign: String
    let recommendedFlowers: [String]
    let estimatedPrice: String
    let browseLinkTitle: String
    let onOpenBrowse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("推薦結果")
                .font(.system(size: 15, weight: .bold))

            recommendationLine(title: "Suggested bouquet design", value: suggestedDesign)
            recommendationLine(title: "Recommended flower types", value: recommendedFlowers.joined(separator: "、"))
            recommendationLine(title: "Estimated price", value: estimatedPrice)

            Button(action: onOpenBrowse) {
                HStack(spacing: 6) {
                    Text(browseLinkTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .underline()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.07, green: 0.30, blue: 0.26))
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.85, green: 0.85, blue: 0.85))
        )
    }

    private func recommendationLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
            Text(value)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.black.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum DIYStep: Int, Equatable {
    case flowers = 1
    case wrapping
    case card
    case confirm

    var title: String {
        switch self {
        case .flowers:
            return "步驟一：選擇花材種類"
        case .wrapping:
            return "步驟二：選擇包裝紙"
        case .card:
            return "步驟三：撰寫賀卡"
        case .confirm:
            return "步驟四：確認花束"
        }
    }

    var progress: CGFloat {
        switch self {
        case .flowers:
            return 0.26
        case .wrapping:
            return 0.58
        case .card:
            return 0.82
        case .confirm:
            return 0.96
        }
    }

    var next: DIYStep? {
        switch self {
        case .flowers:
            return .wrapping
        case .wrapping:
            return .card
        case .card:
            return .confirm
        case .confirm:
            return nil
        }
    }

    var previous: DIYStep? {
        switch self {
        case .flowers:
            return nil
        case .wrapping:
            return .flowers
        case .card:
            return .wrapping
        case .confirm:
            return .card
        }
    }
}

struct SelectedFlowerLine: Identifiable {
    let flower: Flower
    let quantity: Int

    var id: String { flower.id }
    var subtotal: Double { Double(quantity) * flower.price }
}

struct BouquetWrappingOption: Identifiable, Equatable {
    let id: String
    let name: String
    let imageURL: String
    let price: Double
    let stockQuantity: Int?
    let inventoryCode: String?
    
    init(
        id: String,
        name: String,
        imageURL: String,
        price: Double,
        stockQuantity: Int? = nil,
        inventoryCode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.price = price
        self.stockQuantity = stockQuantity
        self.inventoryCode = inventoryCode
    }
    
    init(_ data: StorefrontWrappingOptionData) {
        self.id = data.id
        self.name = data.name
        self.imageURL = data.imageURL
        self.price = data.price
        self.stockQuantity = data.stockQuantity
        self.inventoryCode = data.inventoryCode
    }
    
    var hasReferenceImage: Bool {
        !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var referenceURL: URL? {
        URL(string: imageURL.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static let options: [BouquetWrappingOption] = [
        BouquetWrappingOption(id: "pearl-white", name: "珍珠白", imageURL: "https://www.figma.com/api/mcp/asset/c272f95b-2672-4259-afd4-47d0c823b04e", price: 18),
        BouquetWrappingOption(id: "blush-pink", name: "柔粉", imageURL: "https://www.figma.com/api/mcp/asset/f1de3fe9-bb61-4ab0-843c-f655b597bbc1", price: 28),
        BouquetWrappingOption(id: "mist-lilac", name: "雾紫", imageURL: "https://www.figma.com/api/mcp/asset/db278570-ba57-4f41-95a6-f84015089b74", price: 26),
        BouquetWrappingOption(id: "champagne-gold", name: "香槟金", imageURL: "https://www.figma.com/api/mcp/asset/129bb7e4-e81c-461d-b7f0-e131d7d848f4", price: 30),
        BouquetWrappingOption(id: "midnight-black", name: "经典黑", imageURL: "https://www.figma.com/api/mcp/asset/a226c571-2fcf-4c5c-acd5-415845eb150a", price: 32),
        BouquetWrappingOption(id: "fog-gray", name: "雾灰", imageURL: "https://www.figma.com/api/mcp/asset/e7139e31-f1ae-44dd-9271-02d1cc18343c", price: 24)
    ]
}

struct CardBlessingTemplate: Identifiable {
    let id: String
    let message: String

    static let templates: [CardBlessingTemplate] = [
        CardBlessingTemplate(id: "graduation", message: "恭喜你畢業！祝你在人生的新階段一切順利、幸福美滿。"),
        CardBlessingTemplate(id: "gratitude", message: "感謝你一直以來的付出，你的善意對我意義重大。"),
        CardBlessingTemplate(id: "love", message: "送上滿滿的愛與祝福，你讓每一天都更美好。")
    ]
}

private struct DIYBouquetDesignContent: View {
    @ObservedObject var appModel: FigmaCustomerAppModel
    let step: DIYStep

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DIYFlowHeader(
                    unreadNotificationCount: appModel.unreadNotificationCount,
                    onBellTap: appModel.openNotifications,
                    onBack: appModel.closeOverlay
                )
                DIYProgressSection(
                    step: step,
                    priceText: "HKD \(Int(appModel.diyTotalPrice.rounded()))",
                    onPrevious: handleProgressBack,
                    onNext: handleNext,
                    showsPrevious: true,
                    showsNext: step.next != nil,
                    previousEnabled: true,
                    nextEnabled: nextEnabled
                )

                switch step {
                case .flowers:
                    flowerSelectionContent
                case .wrapping:
                    wrappingSelectionContent
                case .card:
                    greetingCardContent
                case .confirm:
                    confirmationContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 402)
            .frame(maxWidth: .infinity)
        }
    }

    private var nextEnabled: Bool {
        switch step {
        case .flowers:
            return appModel.canAdvanceFromFlowerStep
        case .wrapping:
            return appModel.canAdvanceFromWrappingStep
        case .card:
            return true
        case .confirm:
            return false
        }
    }

    private var flowerSelectionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            DIYAssistantSummaryCard(
                title: "AI 摘要",
                subtitle: appModel.diyAssistantSummaryText,
                detail: appModel.diyAssistantSummaryDetail
            )

            HStack(alignment: .top, spacing: 14) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(appModel.diyFlowerCategories, id: \.self) { category in
                            FlowerSidebarButton(
                                title: category.displayName,
                                isSelected: appModel.selectedDIYFlowerCategory == category
                            ) {
                                appModel.selectedDIYFlowerCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                }
                .frame(width: 92, height: 510)
                .background(FigmaPalette.softPink.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 14) {
                    ForEach(appModel.diyFlowers) { flower in
                        DIYFlowerCard(
                            flower: flower,
                            quantity: appModel.quantity(for: flower),
                            stockText: appModel.stockText(for: flower),
                            canIncrement: appModel.canIncrementDIYQuantity(for: flower),
                            canDecrement: appModel.quantity(for: flower) > 0,
                            showsRestockReminder: (appModel.availableStock(for: flower) ?? 0) == 0,
                            isRestockReminderEnabled: appModel.isRestockReminderEnabled(for: flower),
                            onToggleRestockReminder: {
                                appModel.toggleRestockReminder(for: flower)
                            },
                            onIncrement: {
                                appModel.increaseFlowerQuantity(flower)
                            },
                            onDecrement: {
                                appModel.decreaseFlowerQuantity(flower)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var wrappingSelectionContent: some View {
        Group {
            if appModel.availableWrappingOptions.isEmpty {
                Text("请先在 Firestore 的 wrapping_options collection 配好包装名称、价格和参考图。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 24) {
                    ForEach(appModel.availableWrappingOptions) { option in
                        DIYWrappingOptionCard(
                            option: option,
                            isSelected: appModel.selectedWrappingOptionID == option.id,
                            stockText: appModel.stockText(for: option),
                            canIncrement: appModel.canSelectWrappingOption(option),
                            showsRestockReminder: (appModel.availableStock(for: option) ?? 0) == 0,
                            isRestockReminderEnabled: appModel.isRestockReminderEnabled(for: option),
                            onToggleRestockReminder: {
                                appModel.toggleRestockReminder(for: option)
                            },
                            onIncrement: {
                                if appModel.canSelectWrappingOption(option) {
                                    appModel.selectedWrappingOptionID = option.id
                                }
                            },
                            onDecrement: {
                                if appModel.selectedWrappingOptionID == option.id {
                                    appModel.selectedWrappingOptionID = nil
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private var greetingCardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("為花束附上一段個人祝福")
                .font(.system(size: 14, weight: .medium))

            VStack(alignment: .leading, spacing: 10) {
                DIYCheckboxRow(
                    title: "不用，謝謝",
                    isSelected: !appModel.includeGreetingCard
                ) {
                    appModel.toggleGreetingCard(false)
                }

                DIYCheckboxRow(
                    title: "是的，加入賀卡",
                    isSelected: appModel.includeGreetingCard
                ) {
                    appModel.toggleGreetingCard(true)
                }
            }

            ZStack(alignment: .topLeading) {
                if appModel.cardMessage.isEmpty {
                    Text("範例：「畢業快樂！為你感到驕傲。」")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.black.opacity(0.55))
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                }

                TextEditor(text: $appModel.cardMessage)
                    .font(.system(size: 14, weight: .regular))
                    .frame(height: 130)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.white)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black.opacity(0.55), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(!appModel.includeGreetingCard)
            .opacity(appModel.includeGreetingCard ? 1 : 0.55)

            VStack(alignment: .leading, spacing: 12) {
                Text("快速祝福：")
                    .font(.system(size: 14, weight: .bold))

                ForEach(CardBlessingTemplate.templates) { template in
                    DIYBlessingTemplateRow(
                        text: template.message,
                        isSelected: appModel.selectedBlessingTemplateID == template.id
                    ) {
                        appModel.applyBlessingTemplate(template)
                    }
                }
            }

            RemoteAssetImage(
                urlString: "https://www.figma.com/api/mcp/asset/698fbb1b-dea1-4652-a36b-1715b1f4fac6",
                fallbackSystemName: "envelope.fill",
                contentMode: .fill
            )
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var confirmationContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(FigmaPalette.hotPink)
                    .frame(width: 44)

                Text("你的第一束自訂花束！")
                    .font(.system(size: 26, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(appModel.customBouquetHeadline)
                    .font(.system(size: 20, weight: .semibold))

                ForEach(appModel.selectedDIYFlowers) { line in
                    Text("\(line.quantity) 枝 \(line.flower.name)")
                        .font(.system(size: 16, weight: .regular))
                }

                if let wrapping = appModel.selectedWrappingOption {
                    Text("包裝：\(wrapping.name)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }

                if appModel.includeGreetingCard {
                    Text("賀卡：已加入")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("價格明細")
                    .font(.system(size: 20, weight: .bold))

                ForEach(appModel.selectedDIYFlowers) { line in
                    HStack {
                        Text(line.flower.name)
                        Spacer()
                        Text("\(line.quantity) x HKD \(Int(line.flower.price.rounded()))")
                    }
                    .font(.system(size: 15, weight: .medium))
                }

                HStack {
                    Text("花藝製作費")
                    Spacer()
                    Text("HKD \(Int(appModel.arrangementFee.rounded()))")
                }
                .font(.system(size: 15, weight: .medium))

                HStack {
                    Text("包裝紙")
                    Spacer()
                    Text("HKD \(Int(appModel.wrappingFee.rounded()))")
                }
                .font(.system(size: 15, weight: .medium))

                HStack {
                    Text("賀卡（可選）")
                    Spacer()
                    Text("HKD \(Int(appModel.greetingCardFee.rounded()))")
                }
                .font(.system(size: 15, weight: .medium))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(FigmaPalette.softPink.opacity(0.35))
            )

            ForEach(appModel.missingPreviewReferenceMessages, id: \.self) { message in
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }

            if let errorMessage = appModel.previewErrorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            }

            Button {
                Task {
                    await appModel.generateDIYPreview()
                }
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black, lineWidth: 1)
                    .frame(height: 48)
                    .overlay {
                        HStack(spacing: 8) {
                            if appModel.isGeneratingPreview {
                                ProgressView()
                                    .tint(.black)
                            }
                            Text(appModel.isGeneratingPreview ? "正在生成預覽..." : "預覽你的花束")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(appModel.isGeneratingPreview || !appModel.canGenerateDIYPreview)

            Button {
                appModel.addCustomBouquetToCart()
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.black, lineWidth: 1)
                    .frame(height: 48)
                    .overlay {
                        Text("加入購物車")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private func handleProgressBack() {
        appModel.stepBackInDIYFlow(from: step)
    }

    private func handleNext() {
        guard let nextStep = step.next else { return }
        switch step {
        case .flowers:
            guard appModel.canAdvanceFromFlowerStep else { return }
        case .wrapping:
            guard appModel.canAdvanceFromWrappingStep else { return }
        case .card, .confirm:
            break
        }
        appModel.navigateToDIYStep(nextStep)
    }
}

private struct DIYBouquetPreviewContent: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                DIYFlowHeader(
                    unreadNotificationCount: appModel.unreadNotificationCount,
                    onBellTap: appModel.openNotifications
                ) {
                    appModel.closeOverlay()
                }

                DIYProgressSection(
                    step: .confirm,
                    priceText: "HKD \(Int(appModel.diyTotalPrice.rounded()))",
                    onPrevious: appModel.returnToConfirmStep,
                    onNext: nil,
                    showsPrevious: true,
                    showsNext: false,
                    previousEnabled: true,
                    nextEnabled: false
                )

                ZStack {
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(FigmaPalette.softPink)

                    VStack(spacing: 16) {
                        previewImage

                        VStack(spacing: 8) {
                            Button {
                                Task {
                                    await appModel.generateDIYPreview()
                                }
                            } label: {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.45))
                                    .frame(height: 38)
                                    .overlay {
                                        HStack(spacing: 8) {
                                            if appModel.isGeneratingPreview {
                                                ProgressView()
                                                    .tint(.white)
                                            }
                                            Text(appModel.isGeneratingPreview ? "重新生成中..." : "重新生成預覽")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)

                            Text("預覽剩餘次數：1 次")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))

                            Button {
                                appModel.returnToConfirmStep()
                            } label: {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.white.opacity(0.45))
                                    .frame(height: 38)
                                    .overlay {
                                        Text("編輯設計")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 62)

                        Button {
                            appModel.addCustomBouquetToCart()
                        } label: {
                            Capsule(style: .continuous)
                                .fill(Color.black)
                                .frame(height: 44)
                                .overlay {
                                    Text("加入購物車")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 62)

                        Button {
                            appModel.addCustomBouquetToCartAndProceedToCheckout()
                        } label: {
                            Capsule(style: .continuous)
                                .stroke(Color.black, lineWidth: 1)
                                .frame(height: 44)
                                .overlay {
                                    Text("前往付款")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.black)
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 62)

                        Button {
                            appModel.presentPreviewDisclaimerOverlay()
                        } label: {
                            HStack(spacing: 6) {
                                Text("免責聲明")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "exclamationmark.circle")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.red.opacity(0.82))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 26)
                    .padding(.horizontal, 18)

                    if appModel.showPreviewDisclaimer {
                        DIYPreviewDisclaimerOverlay {
                            appModel.dismissPreviewDisclaimerOverlay()
                        }
                        .padding(.horizontal, 18)
                    }
                }
                .frame(height: 560)

                if let errorMessage = appModel.previewErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 30)
            .frame(maxWidth: 402)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var previewImage: some View {
        if let preview = appModel.generatedPreview {
            AsyncImage(url: preview.imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                        .overlay(Image(systemName: "photo"))
                @unknown default:
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.55))
                }
            }
            .frame(height: 250)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.55))
                .frame(height: 250)
                .overlay {
                    Text("預覽圖載入中")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                }
        }
    }
}

private struct DIYFlowHeader: View {
    let unreadNotificationCount: Int
    let onBellTap: () -> Void
    let onBack: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(FigmaPalette.palePink)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Spacer()

            NotificationBellButton(
                unreadCount: unreadNotificationCount,
                size: 30,
                action: onBellTap
            )
        }
        .overlay(alignment: .leading) {
            VStack(alignment: .leading, spacing: 2) {
                Text("蔚蘭園")
                    .font(.system(size: 14, weight: .regular))
                Text("DIY 花束設計")
                    .font(.system(size: 29, weight: .bold))
            }
            .padding(.leading, 28)
            .offset(y: 38)
        }
        .padding(.top, 18)
        .padding(.bottom, 42)
    }
}

private struct DIYProgressSection: View {
    let step: DIYStep
    let priceText: String
    let onPrevious: (() -> Void)?
    let onNext: (() -> Void)?
    let showsPrevious: Bool
    let showsNext: Bool
    let previousEnabled: Bool
    let nextEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title)
                .font(.system(size: 14, weight: .bold))

            HStack(spacing: 12) {
                if showsPrevious, let onPrevious {
                    Button(action: onPrevious) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(previousEnabled ? .black : .black.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(!previousEnabled)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .stroke(Color.black, lineWidth: 1)
                            .frame(height: 15)

                        Capsule(style: .continuous)
                            .fill(Color.black)
                            .frame(width: max(30, proxy.size.width * step.progress), height: 7)
                            .padding(.leading, 6)
                            .padding(.vertical, 4)

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(FigmaPalette.hotPink)
                            .offset(x: max(18, proxy.size.width * step.progress) - 18, y: 1)
                    }
                }
                .frame(height: 16)

                if showsNext, let onNext {
                    Button(action: onNext) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(nextEnabled ? .black : .black.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(!nextEnabled)
                }
            }

            HStack {
                Spacer()
                Text(priceText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black)
                    .clipShape(Capsule(style: .continuous))
                Spacer()
            }
        }
    }
}

private struct DIYAssistantSummaryCard: View {
    let title: String
    let subtitle: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FigmaPalette.softPink.opacity(0.35))
        )
    }
}

private struct DIYFlowerCard: View {
    let flower: Flower
    let quantity: Int
    let stockText: String
    var canIncrement = true
    var canDecrement = true
    var showsRestockReminder = false
    var isRestockReminderEnabled = false
    var onToggleRestockReminder: (() -> Void)?
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            flowerImage
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(flower.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                        Text("\(flower.categoryDisplayName) · \(flower.unitDisplayName)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("HKD \(Int(flower.price.rounded())) / \(flower.unitDisplayName)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                }

                Text(stockText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)

                if showsRestockReminder, let onToggleRestockReminder {
                    RestockReminderToggle(
                        isSelected: isRestockReminderEnabled,
                        action: onToggleRestockReminder
                    )
                } else {
                    DIYMiniStepper(
                        quantity: quantity,
                        canIncrement: canIncrement,
                        canDecrement: canDecrement,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }

    @ViewBuilder
    private var flowerImage: some View {
        if let imageURL = flower.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(flower.color.opacity(0.18))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    fallbackImage
                @unknown default:
                    fallbackImage
                }
            }
        } else {
            fallbackImage
        }
    }

    private var fallbackImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(flower.color.opacity(0.18))
            Text(flower.emoji)
                .font(.system(size: 38))
        }
    }
}

private struct DIYWrappingOptionCard: View {
    let option: BouquetWrappingOption
    let isSelected: Bool
    let stockText: String
    let canIncrement: Bool
    var showsRestockReminder = false
    var isRestockReminderEnabled = false
    var onToggleRestockReminder: (() -> Void)?
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            RemoteAssetImage(
                urlString: option.imageURL,
                fallbackSystemName: "gift",
                contentMode: .fill
            )
            .frame(height: 138)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(option.name)
                .font(.system(size: 14, weight: .bold))

            Text(stockText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.black.opacity(0.68))

            if showsRestockReminder, let onToggleRestockReminder {
                RestockReminderToggle(
                    isSelected: isRestockReminderEnabled,
                    action: onToggleRestockReminder
                )
            } else {
                DIYMiniStepper(
                    quantity: isSelected ? 1 : 0,
                    canIncrement: canIncrement,
                    canDecrement: isSelected,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isSelected ? Color.black : Color.clear, lineWidth: 1.2)
                )
        )
    }
}

private struct RestockReminderToggle: View {
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text("到貨提醒")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(FigmaPalette.hotPink)
            }
            .padding(.horizontal, 18)
            .frame(height: 31)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct DIYMiniStepper: View {
    let quantity: Int
    var canIncrement = true
    var canDecrement = true
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onDecrement) {
                Text("−")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .disabled(!canDecrement)
            .opacity(canDecrement ? 1 : 0.3)

            Text("\(quantity)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black)
                .frame(minWidth: 14)

            Button(action: onIncrement) {
                Text("+")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
            .disabled(!canIncrement)
            .opacity(canIncrement ? 1 : 0.3)
        }
    }
}

private struct DIYCheckboxRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isSelected ? .black : .gray)

                Text(title)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DIYBlessingTemplateRow: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(isSelected ? .black : .gray)
                    .padding(.top, 2)

                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DIYPreviewDisclaimerOverlay: View {
    let onDismiss: () -> Void

    var body: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay {
                VStack(spacing: 14) {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.red.opacity(0.72))
                        }
                        .buttonStyle(.plain)
                    }

                    Text("免責聲明")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red.opacity(0.75))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("• 本頁面所展示的花束效果圖為 AI 生成的示意圖，僅用於幫助顧客想像花束設計的整體效果。")
                        Text("• 由於花材本身的自然差異，實際花束在花朵大小、形狀及排列方式上可能會與預覽略有不同。")
                        Text("• 花材的顏色與質感可能會因季節供應情況或店內燈光環境而出現輕微差異。")
                        Text("• 所有花束均由花藝師手工製作，因此在最終呈現的排列細節上出現少量變化屬正常情況。")
                        Text("• 若部分花材因季節或供應問題暫時缺貨，花店可能會以相似花材替代，但會盡量保持整體風格與設計一致。")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red.opacity(0.74))
                    .multilineTextAlignment(.center)

                    Button(action: onDismiss) {
                        Capsule(style: .continuous)
                            .fill(FigmaPalette.softPink)
                            .frame(height: 38)
                            .overlay {
                                Text("我知道了，查看完整預覽")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
            }
    }
}

private struct AIResultPanel: View {
    let requirement: String
    @ObservedObject var previewViewModel: AIBouquetPreviewViewModel
    let onGenerate: () -> Void
    let onUsePreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AI 成品預覽")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Text("預覽剩餘次數：2 次")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("生成需求")
                    .font(.system(size: 13, weight: .bold))
                Text(requirement)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FigmaPalette.softPink.opacity(0.35))
            )

            if !previewViewModel.selectedSelections.isEmpty {
                FlowTagSection(
                    title: "資料庫推薦花材",
                    tags: previewViewModel.selectedSelections.map {
                        "\($0.flower.name) x\($0.quantity)"
                    }
                )
            }

            VStack(spacing: 12) {
                SecureField("ARK API Key", text: $previewViewModel.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(FigmaPalette.softPink, lineWidth: 1)
                    )

                TextField("模型名稱", text: $previewViewModel.modelName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(FigmaPalette.softPink, lineWidth: 1)
                    )

                Button(action: onGenerate) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black)
                        .frame(height: 48)
                        .overlay {
                            HStack(spacing: 8) {
                                if previewViewModel.isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 14, weight: .bold))
                                }

                                Text(previewViewModel.isGenerating ? "正在生成預覽..." : "生成 AI 花束預覽")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                        }
                }
                .buttonStyle(.plain)
            }

            Group {
                if let generatedPreview = previewViewModel.generatedPreview {
                    VStack(alignment: .leading, spacing: 14) {
                        AsyncImage(url: generatedPreview.imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            case .failure:
                                previewPlaceholder
                            @unknown default:
                                previewPlaceholder
                            }
                        }
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        HStack(spacing: 14) {
                            SmallCapsuleButton(title: "加入購物車", filled: true, action: onUsePreview)
                            SmallCapsuleButton(title: "重新生成", filled: false, action: onGenerate)
                        }
                    }
                } else {
                    previewPlaceholder
                }
            }

            if let errorMessage = previewViewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.red)
            }
        }
    }

    private var previewPlaceholder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(FigmaPalette.softPink.opacity(0.22))
            .frame(height: 220)
            .overlay {
                VStack(spacing: 10) {
                    if previewViewModel.isGenerating {
                        ProgressView()
                        Text("正在向生成模型請求真實花束預覽")
                            .font(.system(size: 13, weight: .medium))
                    } else {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 34, weight: .regular))
                        Text("接入 API 後，這裡會顯示真實生成的花束預覽")
                            .font(.system(size: 13, weight: .medium))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 22)
                    }
                }
                .foregroundColor(.black.opacity(0.6))
            }
    }
}

private struct FlowTagSection: View {
    let title: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold))

            FlexibleTagStack(tags: tags)
        }
    }
}

private struct FlexibleTagStack: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(tags, size: 2), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(FigmaPalette.softPink.opacity(0.5))
                            )
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func chunked(_ tags: [String], size: Int) -> [[String]] {
        stride(from: 0, to: tags.count, by: size).map {
            Array(tags[$0..<min($0 + size, tags.count)])
        }
    }
}

private struct FlowerSidebarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .black : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.white : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct FlowerCatalogCard: View {
    let flower: Flower
    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)

                Text(flower.emoji)
                    .font(.system(size: 32))
            }
            .padding(.top, 2)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flower.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(flower.englishName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 10) {
                    Text("$\(Int(flower.price.rounded())) / \(flower.unitDisplayName)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)

                    Spacer(minLength: 8)

                    QuantityControl(
                        quantity: quantity,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                        collapsedWhenZero: true
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(FigmaPalette.softPink, lineWidth: 1)
                )
        )
    }
}

private struct EmptyCartCard: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(FigmaPalette.softPink)
                .frame(height: 250)
                .overlay {
                    VStack(spacing: 14) {
                        Image(systemName: "cart")
                            .font(.system(size: 40, weight: .regular))
                        Text("購物車還是空的")
                            .font(.system(size: 22, weight: .bold))
                        Text("先去挑一束喜歡的花吧。")
                            .font(.system(size: 14, weight: .regular))
                    }
                }

            SoftActionButton(title: "前往瀏覽鮮花", isEnabled: true, action: action)
        }
    }
}

private struct CartItemCard: View {
    let item: CartItem
    let stockText: String
    let canIncrement: Bool
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(FigmaPalette.softPink)
                .frame(width: 132, height: 132)
                .overlay {
                    RemoteAssetImage(
                        urlString: item.product.imageURL,
                        fallbackSystemName: "gift.fill",
                        contentMode: .fit
                    )
                    .padding(12)
                }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.product.name)
                    .font(.system(size: 20, weight: .bold))

                Text(item.product.tagline)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)

                Text(item.product.priceText)
                    .font(.system(size: 17, weight: .bold))

                Text(stockText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black.opacity(0.65))

                QuantityControl(
                    quantity: item.quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                    canIncrement: canIncrement,
                    canDecrement: item.quantity > 0,
                    style: .compact
                )
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(FigmaPalette.softPink, lineWidth: 1)
                )
        )
    }
}

private struct QuantityControl: View {
    enum Style {
        case regular
        case compact
    }

    let quantity: Int
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    var canIncrement = true
    var canDecrement = true
    var style: Style = .regular
    var collapsedWhenZero = false

    var body: some View {
        Group {
            if collapsedWhenZero && quantity == 0 {
                Button(action: onIncrement) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 30, height: 30)
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canIncrement)
                .opacity(canIncrement ? 1 : 0.45)
            } else {
                HStack(spacing: style == .regular ? 6 : 6) {
                    quantityButton(symbol: "minus", action: onDecrement, isEnabled: quantity > 0 && canDecrement)

                    Text("\(quantity)")
                        .font(.system(size: style == .regular ? 13 : 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(minWidth: style == .regular ? 16 : 14)

                    quantityButton(symbol: "plus", action: onIncrement, isEnabled: canIncrement)
                }
                .padding(.horizontal, style == .regular ? 8 : 7)
                .frame(height: style == .regular ? 30 : 28)
                .background(
                    Capsule(style: .continuous)
                        .fill(FigmaPalette.softPink.opacity(0.4))
                )
            }
        }
    }

    private func quantityButton(symbol: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(style == .regular ? Color.white.opacity(0.96) : Color.white)
                    .frame(width: style == .regular ? 18 : 16, height: style == .regular ? 18 : 16)
                Image(systemName: symbol)
                    .font(.system(size: style == .regular ? 8 : 7, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

private struct ProfileInfoRow: View {
    let title: String
    let value: String
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FigmaPalette.softPink.opacity(0.8), lineWidth: 1)
                )
        )
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
            HStack(alignment: .top, spacing: 10) {
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FigmaPalette.hotPink)
                    .padding(.top, 1)
            }
        }
    }
}

private struct ProfileDetailLine: View {
    let icon: String
    let title: String
    let subtitle: String?
    var showsChevron = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(icon) \(title)")
                    .font(.system(size: 12, weight: .bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FigmaPalette.softPink.opacity(0.8), lineWidth: 1)
                )
        )
    }
}

private struct SoftInputField: View {
    @Binding var text: String
    let placeholder: String
    var isSecure = false

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 18)
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 149 / 255, green: 130 / 255, blue: 146 / 255).opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 167 / 255, green: 137 / 255, blue: 137 / 255).opacity(0.7), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 4)
    }
}

private struct SoftActionButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isEnabled ? Color.white : FigmaPalette.softPink.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(red: 167 / 255, green: 137 / 255, blue: 137 / 255).opacity(0.7), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 4)
                .frame(height: 42)
                .overlay {
                    Text(title)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(isEnabled ? .black : .black.opacity(0.2))
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct SmallCapsuleButton: View {
    let title: String
    let filled: Bool
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule(style: .continuous)
                .fill(filled ? (isEnabled ? Color.black : Color.black.opacity(0.2)) : Color.white)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isEnabled ? Color.black : Color.black.opacity(0.2), lineWidth: filled ? 0 : 1)
                )
                .frame(width: 97, height: 24)
                .overlay {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(
                            filled
                                ? (isEnabled ? .white : .white.opacity(0.75))
                                : (isEnabled ? .black : .black.opacity(0.3))
                        )
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct BrandGlowBackground: View {
    private let hearts: [(CGFloat, CGFloat)] = [
        (0.12, 0.30),
        (0.28, 0.52),
        (0.84, 0.82),
        (0.76, 0.48)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(FigmaPalette.softPink.opacity(0.72))
                    .blur(radius: 50)
                    .frame(width: 288, height: 257)
                    .offset(x: -proxy.size.width * 0.34, y: -34)

                Circle()
                    .fill(FigmaPalette.softPink.opacity(0.72))
                    .blur(radius: 50)
                    .frame(width: 230, height: 237)
                    .rotationEffect(.degrees(8.4))
                    .offset(x: proxy.size.width * 0.34, y: 206)

                ForEach(Array(hearts.enumerated()), id: \.offset) { _, point in
                    Image(systemName: "heart")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(.white.opacity(0.72))
                        .position(x: proxy.size.width * point.0, y: proxy.size.height * point.1)
                }
            }
        }
    }
}

private struct RemoteAssetImage: View {
    let urlString: String
    let fallbackSystemName: String
    let contentMode: ContentMode

    var body: some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            case .empty:
                placeholder
            case .failure:
                placeholder
            @unknown default:
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.05))

            Image(systemName: fallbackSystemName)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.black.opacity(0.45))
        }
    }
}

private struct FigmaBottomNavBar: View {
    let selectedTab: FigmaCustomerAppModel.MainTab
    let onSelect: (FigmaCustomerAppModel.MainTab) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(leadingGroups, id: \.self) { group in
                BottomNavGroup(tabs: group, selectedTab: selectedTab, onSelect: onSelect)
            }

            BottomNavSelectedButton(tab: selectedTab) {
                onSelect(selectedTab)
            }

            ForEach(trailingGroups, id: \.self) { group in
                BottomNavGroup(tabs: group, selectedTab: selectedTab, onSelect: onSelect)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .frame(maxWidth: 402)
        .frame(maxWidth: .infinity)
        .background(Color.clear)
    }

    private var leadingGroups: [[FigmaCustomerAppModel.MainTab]] {
        switch selectedTab {
        case .browse:
            return []
        case .assistant:
            return [[.browse]]
        case .home:
            return [[.browse, .assistant]]
        case .cart:
            return [[.browse, .assistant, .home]]
        case .profile:
            return [[.browse, .assistant, .home, .cart]]
        }
    }

    private var trailingGroups: [[FigmaCustomerAppModel.MainTab]] {
        switch selectedTab {
        case .browse:
            return [[.assistant, .home, .cart, .profile]]
        case .assistant:
            return [[.home, .cart, .profile]]
        case .home:
            return [[.cart, .profile]]
        case .cart:
            return [[.profile]]
        case .profile:
            return []
        }
    }
}

private struct BottomNavGroup: View {
    let tabs: [FigmaCustomerAppModel.MainTab]
    let selectedTab: FigmaCustomerAppModel.MainTab
    let onSelect: (FigmaCustomerAppModel.MainTab) -> Void

    var body: some View {
        HStack(spacing: 24) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    onSelect(tab)
                } label: {
                    Image(systemName: tab.symbolName)
                        .font(font(for: tab))
                        .foregroundColor(.white)
                        .frame(width: tab == .browse ? 37 : 32, height: 37)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(height: 50)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var horizontalPadding: CGFloat {
        tabs.count == 1 ? 18 : 22
    }

    private func font(for tab: FigmaCustomerAppModel.MainTab) -> Font {
        switch tab {
        case .browse:
            return .system(size: 30, weight: .regular)
        case .assistant:
            return .system(size: 24, weight: .regular)
        case .home:
            return .system(size: 32, weight: .bold)
        case .cart:
            return .system(size: 24, weight: .regular)
        case .profile:
            return .system(size: 28, weight: .regular)
        }
    }
}

private struct BottomNavSelectedButton: View {
    let tab: FigmaCustomerAppModel.MainTab
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: tab.symbolName)
                .font(selectedFont)
                .foregroundColor(tab.selectedColor)
                .frame(width: 38, height: 38)
        }
        .buttonStyle(.plain)
    }

    private var selectedFont: Font {
        switch tab {
        case .browse:
            return .system(size: 32, weight: .regular)
        case .assistant:
            return .system(size: 28, weight: .regular)
        case .home:
            return .system(size: 34, weight: .bold)
        case .cart:
            return .system(size: 28, weight: .regular)
        case .profile:
            return .system(size: 30, weight: .regular)
        }
    }
}

private enum HomeFlowerStrip {
    static let items: [String] = [
        "https://www.figma.com/api/mcp/asset/e7d2b497-9bb1-4628-832f-96d4b9229da4",
        "https://www.figma.com/api/mcp/asset/3a16900a-6d67-4efb-a31f-99e12c65f8d5",
        "https://www.figma.com/api/mcp/asset/d4805143-4654-4ffa-b74d-02537a3c965b",
        "https://www.figma.com/api/mcp/asset/26ab7e9e-cefd-4918-849a-8d0d9af89003",
        "https://www.figma.com/api/mcp/asset/ee5b5642-f9f7-4540-9bae-b9ddb2a9a040"
    ]
}

private enum FigmaPalette {
    static let softPink = Color(red: 1.0, green: 235.0 / 255.0, blue: 252.0 / 255.0)
    static let palePink = Color(red: 1.0, green: 223.0 / 255.0, blue: 248.0 / 255.0)
    static let hotPink = Color(red: 211.0 / 255.0, green: 96.0 / 255.0, blue: 149.0 / 255.0)
}

#Preview {
    FigmaCustomerAppView()
}
