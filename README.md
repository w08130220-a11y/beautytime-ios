# BeautyTime iOS

BeautyTime 是一款美業預約平台 iOS 應用程式，提供消費者探索美容服務、線上預約、配對媒合等功能，同時為商家提供完整的店務管理系統。

## 功能特色

### 消費者端
- **探索服務** - 依分類（美甲、美睫、美髮、SPA 等）和地區瀏覽商家
- **線上預約** - 選擇服務、日期、設計師與時段，完成預約
- **配對媒合** - 發布需求，由商家主動報價
- **票券系統** - 購買、管理和使用儲值票券
- **我的預約** - 查看預約狀態、歷史紀錄

### 商家管理端
- **儀表板** - 營業數據總覽
- **排班管理** - 月曆/日檢視模式，管理員工班表
- **員工管理** - 新增員工、角色權限、薪資設定
- **服務管理** - 設定服務項目、價格、時長
- **客戶管理** - 客戶資料與備註
- **營收分析** - 營收、回客率、客單價等統計
- **行銷工具** - 行銷範本管理

## 技術架構

| 項目 | 說明 |
|------|------|
| 語言 | Swift |
| UI 框架 | SwiftUI |
| 最低版本 | iOS 17.0 |
| 架構模式 | MVVM + @Observable Stores |
| 後端 | RESTful API (Supabase) |
| 金流 | ECPay 綠界科技 |

### 第三方套件 (Swift Package Manager)

| 套件 | 用途 |
|------|------|
| [GoogleSignIn](https://github.com/google/GoogleSignIn-iOS) (v8.0+) | Google OAuth 登入 |
| [Kingfisher](https://github.com/onevcat/Kingfisher) (v8.0+) | 圖片載入與快取 |
| [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) (v4.2.2+) | 安全憑證儲存 |

## 專案結構

```
BeautyTime/
├── App/                    # 應用程式進入點與主要導覽
│   ├── BeautyTimeApp.swift # @main App struct
│   ├── ContentView.swift   # 根視圖（登入/主畫面切換）
│   └── MainTabView.swift   # Tab Bar 主導覽
├── Core/                   # 核心基礎設施
│   ├── Network/            # API 通訊層 (APIClient, APIEndpoints)
│   ├── Stores/             # 狀態管理 (@Observable stores)
│   ├── Models/             # 資料模型
│   ├── Utilities/          # 工具函式 (Formatters, Constants)
│   └── Extensions/         # Swift 擴充
├── Components/             # 共用 UI 元件
├── Features/               # 功能模組
│   ├── Auth/               # 登入/註冊
│   ├── Booking/            # 預約流程
│   ├── Explore/            # 探索商家
│   ├── MyBookings/         # 我的預約
│   ├── Match/              # 配對媒合
│   ├── Profile/            # 個人資料
│   ├── Provider/           # 商家詳情
│   ├── Voucher/            # 票券系統
│   ├── Manage/             # 商家管理後台
│   ├── Payment/            # 金流付款
│   └── Survey/             # 偏好問卷
└── Resources/              # 資源檔案
```

## 開發環境設定

### 系統需求

- macOS 14.0+
- Xcode 16.3+
- iOS 17.0+ 模擬器或實機

### 安裝步驟

1. Clone 專案
   ```bash
   git clone https://github.com/w08130220-a11y/beautytime-ios.git
   cd beautytime-ios
   ```

2. 使用 XcodeGen 產生專案檔（如需重新產生）
   ```bash
   brew install xcodegen
   xcodegen generate
   ```

3. 開啟專案
   ```bash
   open BeautyTime.xcodeproj
   ```

4. Xcode 會自動解析 Swift Package Manager 依賴套件

5. 選擇模擬器或連接實機，按 `Cmd + R` 執行

### 設定檔

- **`AppConfig.swift`** - API 基礎 URL、OAuth Client ID 等設定
- **`project.yml`** - XcodeGen 專案定義檔
- **`Info.plist`** - Google Sign-In URL Scheme 設定

## 測試

### 執行單元測試

在 Xcode 中按 `Cmd + U` 或使用命令列：

```bash
xcodebuild test \
  -scheme BeautyTime \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 測試結構

```
BeautyTimeTests/
├── APIEndpointsTests.swift      # API 端點測試
├── TokenManagerTests.swift      # Token 管理測試
├── FormattersTests.swift        # 格式化工具測試
├── ConstantsTests.swift         # 常數驗證測試
├── ModelsTests.swift            # 資料模型序列化測試
├── StoreTests.swift             # Store 狀態測試
└── ViewModelIntegrationTests.swift  # 整合測試
```

## API 文件

- 後端 API 規格：[`openapi.json`](openapi.json)
- 後端規格說明：[`backend-spec.md`](backend-spec.md)
- 前端開發指南：[`frontend-spec-guide.md`](frontend-spec-guide.md)
