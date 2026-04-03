# BeautyTime iOS - Xcode 專案設定指南

## 1. 建立 Xcode 專案

1. 開啟 Xcode → File → New → Project
2. 選擇 **iOS → App**
3. 設定：
   - Product Name: `BeautyTime`
   - Team: 你的開發團隊
   - Organization Identifier: `com.beautytime`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 16.0**
4. 儲存位置選擇此專案的**父目錄**（讓 Xcode 建立在 `beautytime-ios/` 下）

## 2. 加入原始碼

1. 在 Xcode 中，**刪除** 預設生成的 `ContentView.swift` 和 `BeautyTimeApp.swift`
2. 將 `BeautyTime/` 資料夾拖入 Xcode 專案導覽器
3. 確認 "Copy items if needed" **不勾選**（因為檔案已在正確位置）
4. 確認 "Add to targets" 勾選 `BeautyTime`

## 3. 加入 SPM 套件

File → Add Package Dependencies，加入以下套件：

| 套件 | URL | 版本 |
|------|-----|------|
| KeychainAccess | `https://github.com/kishikawakatsumi/KeychainAccess.git` | 4.2.2+ |
| Kingfisher | `https://github.com/onevcat/Kingfisher.git` | 7.0+ |

## 4. 設定 Info.plist

在 Target → Info 中加入以下 key：

```xml
<!-- 相機權限（QR Code 掃描用） -->
<key>NSCameraUsageDescription</key>
<string>需要相機權限來掃描 QR Code 兌換票券</string>

<!-- 相簿權限（上傳照片用） -->
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相簿權限來上傳作品集和頭像照片</string>
```

## 5. Build & Run

1. 選擇模擬器 (iPhone 15 Pro 建議)
2. Cmd + B 編譯
3. Cmd + R 執行

## 檔案結構總覽

```
BeautyTime/
├── App/                          # App 入口 (3 files)
│   ├── BeautyTimeApp.swift       # @main 進入點
│   ├── ContentView.swift         # 根視圖 (登入/主頁切換)
│   └── MainTabView.swift         # TabView (5 tabs)
├── Core/                         # 核心架構 (12 files)
│   ├── AppConfig.swift           # API URL 等設定
│   ├── Network/                  # 網路層
│   │   ├── APIClient.swift       # HTTP Client (actor)
│   │   ├── APIEndpoints.swift    # 所有 API 端點
│   │   ├── APIError.swift        # 錯誤類型
│   │   ├── HTTPMethod.swift      # HTTP 方法
│   │   └── TokenManager.swift    # JWT Keychain 管理
│   ├── Models/
│   │   └── Models.swift          # 所有資料模型
│   ├── Stores/                   # @Observable 狀態管理
│   │   ├── AuthStore.swift       # 認證狀態
│   │   ├── BookingFlowStore.swift # 預約流程
│   │   ├── ManageStore.swift     # 服務商管理
│   │   ├── ProviderStore.swift   # 服務商搜尋
│   │   └── UserStore.swift       # 用戶資料
│   └── Utilities/
│       ├── Constants.swift       # 列舉 & 常數
│       └── Formatters.swift      # 格式化工具
├── Features/                     # 功能模組 (44 files)
│   ├── Auth/                     # 認證 (3)
│   ├── Explore/                  # 探索 (3)
│   ├── Provider/                 # 服務商詳情 (3)
│   ├── Booking/                  # 預約流程 (6)
│   ├── MyBookings/               # 我的預約 (2)
│   ├── Match/                    # 媒合 (4)
│   ├── Voucher/                  # 票券 (2)
│   ├── Profile/                  # 個人檔案 (5)
│   ├── Manage/                   # 服務商管理 (13)
│   └── Payment/                  # 付款 (1)
├── Components/                   # 共用元件 (3 files)
│   ├── LoadingView.swift         # Loading, Empty, Error
│   ├── SearchBar.swift           # 搜尋欄, 評分星星
│   └── QRCodeView.swift          # QR Code 產生/掃描
└── Resources/                    # (待在 Xcode 中設定)
```

## 注意事項

- API Base URL 在 `Core/AppConfig.swift` 中設定
- 所有 API 回傳使用 `snake_case`，自動轉為 `camelCase`
- JWT Token 安全儲存在 Keychain
- 圖片使用 Kingfisher 載入（自帶快取）
- 所有網路狀態使用 `@Observable` 管理
