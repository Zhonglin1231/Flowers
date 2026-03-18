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
    }
}

@MainActor
final class FigmaCustomerAppModel: ObservableObject {
    enum AuthState {
        case welcome
        case emailLogin
        case main
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

    enum OverlayScreen {
        case productDetail
        case assistantJourney
        case farm
    }

    @Published var authState: AuthState = .welcome
    @Published var activeTab: MainTab = .home
    @Published var overlayScreen: OverlayScreen?
    @Published var email = ""
    @Published var password = ""
    @Published var selectedProduct = BouquetProduct.catalog[1]
    @Published var cartItems: [CartItem] = []
    @Published var showBrowsePrompt = true
    @Published var selectedOccasion = "生日驚喜"
    @Published var selectedPalette = "粉色"
    @Published var selectedMood = "浪漫"
    @Published var selectedBudget = "HKD 200 - 300"

    var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var recommendedBouquet: BouquetProduct {
        selectedProduct
    }

    func showEmailLogin() {
        authState = .emailLogin
    }

    func enterAsGuest() {
        authState = .main
        activeTab = .home
        overlayScreen = nil
    }

    func login() {
        guard canLogin else { return }
        authState = .main
        activeTab = .home
        overlayScreen = nil
    }

    func backToWelcome() {
        authState = .welcome
    }

    func selectTab(_ tab: MainTab) {
        activeTab = tab
        overlayScreen = nil
    }

    func openProduct(_ product: BouquetProduct, from tab: MainTab = .home) {
        selectedProduct = product
        activeTab = tab
        overlayScreen = .productDetail
    }

    func openCustomBouquetFlow() {
        activeTab = .assistant
        overlayScreen = .assistantJourney
    }

    func openFarm() {
        activeTab = .profile
        overlayScreen = .farm
    }

    func closeOverlay() {
        overlayScreen = nil
    }

    func addSelectedProductToCart() {
        if let index = cartItems.firstIndex(where: { $0.product.id == selectedProduct.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(product: selectedProduct, quantity: 1))
        }
    }

    func proceedToCart() {
        addSelectedProductToCart()
        activeTab = .cart
        overlayScreen = nil
    }

    func browseFeaturedProduct() {
        openProduct(BouquetProduct.catalog[0], from: .home)
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
}

struct CartItem: Identifiable {
    let id = UUID()
    let product: BouquetProduct
    var quantity: Int
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
                        appModel.showEmailLogin()
                    }

                    SoftActionButton(title: "註冊帳戶", isEnabled: true) {
                        appModel.showEmailLogin()
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
                    Text("電話/郵箱")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.top, 30)

                    SoftInputField(text: $appModel.email, placeholder: "")

                    Text("密碼")
                        .font(.system(size: 16, weight: .regular))
                        .padding(.top, 8)

                    SoftInputField(text: $appModel.password, placeholder: "", isSecure: true)

                    Button("忘記密碼？") {}
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)

                    SoftActionButton(title: "登入", isEnabled: appModel.canLogin) {
                        appModel.login()
                    }
                    .padding(.top, 10)
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

    var body: some View {
        MainScreenContainer(selectedTab: .home, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            Text("蔚蘭園")
                                .font(.system(size: 14, weight: .regular))

                            Spacer()

                            Image(systemName: "bell.fill")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.black)
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

                            PromoCard(
                                title: "母親節花束 9 折",
                                subtitle: "全場母親節精選花束 10% OFF",
                                imageURL: "https://www.figma.com/api/mcp/asset/10991474-1a42-49a2-a00a-5aec52f92f73",
                                width: 311
                            ) {
                                appModel.openProduct(BouquetProduct.catalog[1], from: .home)
                            }
                        }
                    }

                    Button {
                        appModel.browseFeaturedProduct()
                    } label: {
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
                                        urlString: "https://www.figma.com/api/mcp/asset/f9bdb990-ab18-4d77-9aca-3c53b85afc20",
                                        fallbackSystemName: "gift.fill",
                                        contentMode: .fit
                                    )
                                    .frame(width: 124, height: 143)
                                    .padding(.top, 8)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.trailing, 18)
                                }

                                Spacer()

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("甜美心意")
                                        .font(.system(size: 14, weight: .regular))
                                    Text("經典粉玫瑰花束\n（粉紅玫瑰 + 綠葉 + 韓式白色花紙包裝）")
                                        .font(.system(size: 10, weight: .regular))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(.leading, 23)
                                .padding(.bottom, 20)
                            }
                        }
                        .frame(height: 242)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 29)
                .padding(.top, 22)
                .padding(.bottom, 26)
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct BrowseScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    private let columns = [
        GridItem(.flexible(), spacing: 23),
        GridItem(.flexible(), spacing: 23)
    ]

    var body: some View {
        MainScreenContainer(selectedTab: .browse, appModel: appModel) {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        FigmaHeader(
                            brand: "蔚蘭園",
                            title: "每一次，\n都為你打造完美花束",
                            subtitle: nil,
                            showBack: true,
                            showBell: true,
                            onBack: {}
                        )

                        HStack(spacing: 8) {
                            FilterChip(title: "篩選", filled: true, symbol: "line.3.horizontal.decrease")
                            FilterChip(title: "玫瑰", filled: false, symbol: nil)
                            FilterChip(title: "粉色", filled: false, symbol: nil)
                            FilterChip(title: "浪漫", filled: false, symbol: nil)
                        }

                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(BouquetProduct.catalog.dropFirst()) { product in
                                Button {
                                    appModel.showBrowsePrompt = false
                                    appModel.openProduct(product, from: .browse)
                                } label: {
                                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                                        .fill(FigmaPalette.softPink)
                                        .frame(height: 164)
                                        .overlay {
                                            RemoteAssetImage(
                                                urlString: product.imageURL,
                                                fallbackSystemName: "gift.fill",
                                                contentMode: .fit
                                            )
                                            .padding(16)
                                            .opacity(appModel.showBrowsePrompt ? 0.18 : 1)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 26)
                    .frame(maxWidth: 402)
                    .frame(maxWidth: .infinity)
                }
                .blur(radius: appModel.showBrowsePrompt ? 2.4 : 0)

                if appModel.showBrowsePrompt {
                    BrowsePromptCard(
                        onCreate: {
                            appModel.showBrowsePrompt = false
                            appModel.openCustomBouquetFlow()
                        },
                        onClose: {
                            appModel.showBrowsePrompt = false
                        }
                    )
                    .padding(.horizontal, 40)
                }
            }
        }
    }
}

private struct ProductDetailScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .home, appModel: appModel) {
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

                        Image(systemName: "bell.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.black)
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
                        SmallCapsuleButton(title: "加入購物車", filled: true) {
                            appModel.addSelectedProductToCart()
                        }

                        SmallCapsuleButton(title: "前往付款", filled: false) {
                            appModel.proceedToCart()
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
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(FigmaPalette.palePink)
                        .frame(width: 28, height: 28)

                    Spacer()

                    Image(systemName: "bell.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
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
                            .frame(width: 206, height: 42)
                            .overlay(alignment: .leading) {
                                Text("你好！我是你的 AI 花藝助手。請問您今天需要：")
                                    .font(.system(size: 11, weight: .bold))
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal, 14)
                            }

                        VStack(spacing: 12) {
                            AssistantChoiceButton(title: "購買單花") {
                                appModel.selectTab(.browse)
                            }
                            AssistantChoiceButton(title: "現成花束") {
                                appModel.selectTab(.browse)
                            }
                            AssistantChoiceButton(title: "定製花束") {
                                appModel.openCustomBouquetFlow()
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

    private let occasionOptions = ["生日驚喜", "紀念日", "感謝", "畢業", "求婚", "開張"]
    private let paletteOptions = ["粉色", "白色", "奶油白", "紫色"]
    private let moodOptions = ["浪漫", "溫柔", "清新", "高級感"]
    private let budgetOptions = ["HKD 100 - 200", "HKD 200 - 300", "HKD 300 - 500", "HKD 500+"]

    var body: some View {
        MainScreenContainer(selectedTab: .assistant, appModel: appModel) {
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

                        Image(systemName: "bell.fill")
                            .font(.system(size: 30, weight: .bold))
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
                        title: "你好！我是你的 AI 花藝助手，請問你想把花送給誰？",
                        iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                    ) {
                        OptionGrid(options: occasionOptions, selection: $appModel.selectedOccasion)
                    }

                    AssistantReplyBubble(text: "好呀，為 \(appModel.selectedOccasion) 準備一束花。你偏好什麼色系？")

                    AssistantConversationBlock(
                        title: "選擇花束主色調",
                        iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                    ) {
                        OptionGrid(options: paletteOptions, selection: $appModel.selectedPalette)
                    }

                    AssistantReplyBubble(text: "收到，主色會以 \(appModel.selectedPalette) 為主。想要什麼氣氛？")

                    AssistantConversationBlock(
                        title: "花束整體風格",
                        iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                    ) {
                        OptionGrid(options: moodOptions, selection: $appModel.selectedMood)
                    }

                    AssistantConversationBlock(
                        title: "預算範圍",
                        iconURL: "https://www.figma.com/api/mcp/asset/cfec918e-6097-49d9-a4cd-2e8498f3c787"
                    ) {
                        OptionGrid(options: budgetOptions, selection: $appModel.selectedBudget)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("AI 推薦花束")
                                .font(.system(size: 18, weight: .bold))
                            Spacer()
                            Text("預覽剩餘次數：2 次")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(FigmaPalette.softPink.opacity(0.6))

                            VStack(spacing: 12) {
                                RemoteAssetImage(
                                    urlString: appModel.recommendedBouquet.imageURL,
                                    fallbackSystemName: "gift.fill",
                                    contentMode: .fit
                                )
                                .frame(height: 180)

                                Text(appModel.recommendedBouquet.name)
                                    .font(.system(size: 22, weight: .bold))

                                Text("\(appModel.selectedPalette) · \(appModel.selectedMood) · \(appModel.selectedBudget)")
                                    .font(.system(size: 13, weight: .regular))
                                    .multilineTextAlignment(.center)

                                Text(appModel.recommendedBouquet.priceText)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .padding(22)
                        }
                        .frame(height: 330)

                        HStack(spacing: 14) {
                            SmallCapsuleButton(title: "加入購物車", filled: true) {
                                appModel.selectedProduct = appModel.recommendedBouquet
                                appModel.addSelectedProductToCart()
                            }

                            SmallCapsuleButton(title: "查看詳情", filled: false) {
                                appModel.selectedProduct = appModel.recommendedBouquet
                                appModel.openProduct(appModel.recommendedBouquet, from: .assistant)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 26)
                }
                .frame(maxWidth: 402)
                .frame(maxWidth: .infinity)
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

                        Image(systemName: "bell.fill")
                            .font(.system(size: 28, weight: .bold))
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
                                CartItemCard(item: item)
                            }

                            VStack(spacing: 10) {
                                HStack {
                                    Text("合計")
                                        .font(.system(size: 18, weight: .bold))
                                    Spacer()
                                    Text(totalPriceText)
                                        .font(.system(size: 22, weight: .bold))
                                }

                                SoftActionButton(title: "前往付款", isEnabled: true) {}
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

private struct ProfileScreen: View {
    @ObservedObject var appModel: FigmaCustomerAppModel

    var body: some View {
        MainScreenContainer(selectedTab: .profile, appModel: appModel) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(FigmaPalette.palePink)
                            .frame(width: 28, height: 28)

                        Spacer()

                        Text("蔚蘭園")
                            .font(.system(size: 14, weight: .regular))

                        Spacer()
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

                            Text("QQ Lee")
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

                    VStack(alignment: .leading, spacing: 20) {
                        ProfileInfoRow(title: "電郵", value: "QQQQLee@email.com")
                        ProfileInfoRow(title: "電話號碼", value: "+852 12345678")

                        VStack(alignment: .leading, spacing: 12) {
                            Text("我的訂單")
                                .font(.system(size: 14, weight: .bold))

                            ProfileDetailLine(icon: "📦", title: "訂單紀錄", subtitle: "查看過往訂單並可再次購買")
                            ProfileDetailLine(icon: "📍", title: "送貨地址", subtitle: "管理已儲存的地址")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("🔔 通知")
                                .font(.system(size: 14, weight: .bold))
                            Text("🙋幫助與支援")
                                .font(.system(size: 14, weight: .bold))
                            ProfileDetailLine(icon: "💬", title: "聯絡店舖", subtitle: nil)
                            ProfileDetailLine(icon: "❓", title: "常見問題", subtitle: "關於訂單與送貨的常見問題。")
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
        .background(Color.white)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FigmaBottomNavBar(selectedTab: selectedTab) { tab in
                appModel.selectTab(tab)
            }
            .padding(.bottom, 8)
        }
    }
}

private struct FigmaHeader: View {
    let brand: String
    let title: String
    let subtitle: String?
    let showBack: Bool
    let showBell: Bool
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
                    Image(systemName: "bell.fill")
                        .font(.system(size: 30, weight: .bold))
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

private struct FilterChip: View {
    let title: String
    let filled: Bool
    let symbol: String?

    var body: some View {
        HStack(spacing: 6) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 14, weight: filled ? .bold : .semibold))

            if !filled {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(filled ? Color.black : Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black, lineWidth: filled ? 0 : 1)
        )
        .foregroundColor(filled ? .white : .black)
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.86, green: 0.86, blue: 0.86))
                    .overlay(alignment: .leading) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, 16)
                    }
                    .frame(height: 54)

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
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.95, blue: 0.95))
                )
        }
        .padding(.horizontal, 24)
    }
}

private struct OptionGrid: View {
    let options: [String]
    @Binding var selection: String

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selection == option ? FigmaPalette.softPink : Color(red: 0.95, green: 0.95, blue: 0.95))
                        .frame(height: 38)
                        .overlay {
                            Text(option)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                        }
                }
                .buttonStyle(.plain)
            }
        }
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

                Text("數量 x\(item.quantity)")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
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

private struct ProfileInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
            HStack {
                Text(value)
                    .font(.system(size: 13, weight: .regular))
                Spacer()
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(FigmaPalette.hotPink)
            }
        }
    }
}

private struct ProfileDetailLine: View {
    let icon: String
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(icon) \(title)")
                .font(.system(size: 12, weight: .bold))
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
            }
        }
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule(style: .continuous)
                .fill(filled ? Color.black : Color.white)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.black, lineWidth: filled ? 0 : 1)
                )
                .frame(width: 97, height: 24)
                .overlay {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(filled ? .white : .black)
                }
        }
        .buttonStyle(.plain)
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
        .background(Color.white)
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
