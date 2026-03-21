# Firebase 集成指南 - Flowers App

## 1. 安装 Firebase SDK

### 使用 Swift Package Manager (推荐)

1. 在 Xcode 中，点击 **File** → **Add Package Dependencies...**

2. 在搜索框中输入：
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```

3. 选择版本规则：**Up to Next Major Version**，然后点击 **Add Package**

4. 选择需要的库（勾选以下选项）：
   - ✅ FirebaseCore
   - ✅ FirebaseFirestore
   - ✅ FirebaseAuth（如需用户认证）

5. 点击 **Add Package** 完成安装

---

## 2. 创建 Firebase 项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)

2. 点击 **创建项目**，输入项目名称（如 `Flowers-App`）

3. 按照向导完成项目创建

---

## 3. 添加 iOS 应用

1. 在 Firebase Console 中，点击 **添加应用** → **iOS**

2. 输入 iOS Bundle ID：
   - 在 Xcode 中查看：选择项目 → **General** → **Bundle Identifier**
   - 例如：`com.yourname.Flowers`

3. 下载 `GoogleService-Info.plist` 文件

4. 将 `GoogleService-Info.plist` 拖入 Xcode 项目的 `Flowers` 文件夹
   - ⚠️ 确保勾选 **Copy items if needed**
   - ⚠️ 确保 **Add to targets** 选中了 `Flowers`

---

## 4. 配置 Firestore 数据库

1. 在 Firebase Console 中，点击左侧菜单的 **Firestore Database**

2. 点击 **创建数据库**

3. 选择 **以测试模式启动**（开发阶段使用）
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

4. 选择数据库位置（建议选择离用户最近的区域）

---

## 5. 数据库结构

应用使用以下集合（Collections）：

### flowers（花卉）
```json
{
  "name": "红玫瑰",
  "englishName": "Red Rose",
  "colorHex": "#FF0000",
  "price": 8.0,
  "emoji": "🌹",
  "category": "玫瑰",
  "description": "热情的红玫瑰，代表热烈的爱",
  "isAvailable": true,
  "stockQuantity": 100
}
```

### bouquets（保存的花束设计 / 店铺展示花束）
```json
{
  "name": "我的花束",
  "items": [...],
  "wrappingStyle": "牛皮纸",
  "ribbonColorHex": "#FFC0CB",
  "note": "生日快乐",
  "createdAt": Timestamp,
  "userId": "user_id",
  "totalPrice": 168.0,
  "imageURL": "https://...",
  "tagline": "柔和粉白玫瑰的浪漫花束",
  "descriptionLines": ["粉紅玫瑰 x6", "白玫瑰 x3", "韓式包裝"],
  "longDescription": ["適合生日與紀念日", "整體風格柔和自然"],
  "isPublished": true
}
```

### settings / ai_preview（商家维护 AI 预览配置）
文档路径：`settings/ai_preview`

```json
{
  "apiKey": "你的 Ark API Key",
  "modelName": "doubao-seedream-5-0-250428",
  "isEnabled": true
}
```

### settings / wrapping_options（DIY 包装配置）
文档路径：`settings/wrapping_options`

```json
{
  "options": [
    {
      "id": "pearl-white",
      "name": "珍珠白",
      "imageURL": "https://...",
      "price": 18
    }
  ]
}
```

### orders（订单）
```json
{
  "bouquetData": {...},
  "customerName": "张三",
  "customerPhone": "13800138000",
  "deliveryAddress": "北京市朝阳区...",
  "deliveryDate": Timestamp,
  "specialRequests": "请在下午3点前送达",
  "status": "pending",
  "createdAt": Timestamp,
  "userId": "user_id"
}
```

---

## 6. 初始化示例数据

首次运行时，可以在 `MainDesignView` 中调用以下方法来初始化花卉数据：

```swift
// 在适当的位置添加一个按钮或在 onAppear 中调用
viewModel.seedFlowersToFirebase()
```

或者在 Firebase Console 中手动添加数据。

---

## 7. 生产环境安全规则

在上线前，请更新 Firestore 安全规则：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 花卉数据：所有人可读，仅管理员可写
    match /flowers/{flowerId} {
      allow read: if true;
      allow write: if request.auth != null && 
                     get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 订单：用户只能读写自己的订单
    match /orders/{orderId} {
      allow read: if request.auth != null && 
                    (resource.data.userId == request.auth.uid || 
                     get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true);
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
                              get(/databases/$(database)/documents/admins/$(request.auth.uid)).data.isAdmin == true;
    }
    
    // 花束设计：用户只能读写自己的设计
    match /bouquets/{bouquetId} {
      allow read, write: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null;
    }
  }
}
```

---

## 8. 常见问题

### Q: 编译时提示找不到 Firebase 模块？
A: 确保已正确添加 Firebase SDK，并在文件顶部添加 `import FirebaseCore` 和 `import FirebaseFirestore`

### Q: 运行时崩溃，提示 FirebaseApp 未配置？
A: 确保 `GoogleService-Info.plist` 已正确添加到项目中，并且在 `FlowersApp.swift` 中调用了 `FirebaseApp.configure()`

### Q: 数据无法写入 Firestore？
A: 检查 Firestore 安全规则是否允许写入操作

---

## 9. 下一步

- [ ] 添加用户认证（Firebase Auth）
- [ ] 实现商家端管理界面
- [ ] 添加推送通知（Firebase Cloud Messaging）
- [ ] 添加图片存储（Firebase Storage）
- [ ] 实现订单实时状态更新
