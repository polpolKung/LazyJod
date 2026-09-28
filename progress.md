# 🤖 AI Instruction / Autonomous Progress Tracking Rule
> **CRITICAL DIRECTIVE FOR ALL FUTURE CHATS / SESSIONS:**
> You are working as the autonomous development assistant on the **"Income-Expense App" (เหมียวจด / LazyJod)** project.
>
> **MANDATORY RULE:** You must autonomously update or rewrite this `progress.md` file **EVERY SINGLE TIME** a feature, component, bug fix, or task is successfully implemented. Do NOT wait for the user to ask or remind you to do this. Whenever a task is done, update this file immediately as part of your completion workflow.
>
> **When a new chat starts with:** `"Read progress.md and continue."`
> 1. Read this `progress.md` file completely to grasp the codebase context, tech stack, architecture, and completed features.
> 2. Check the **Next Steps (📌)** section to know exactly where the project stands.
> 3. Proactively report your understanding and propose the next steps to proceed immediately.

---

# Project Progress — เหมียวจด (LazyJod)

## 1. Tech Stack & Environment
- **Framework:** Flutter (Channel stable, Dart 3.x)
- **Architecture:** Feature-first modular architecture with Riverpod state management (`flutter_riverpod: ^2.5.1`)
- **Local Storage & Database:**
  - `shared_preferences: ^2.2.3` (Offline persistence: Transactions, Categories, Budgets, Recurring rules, Album settings, Scanned Slip ID cache, Cloud OCR sync queue)
  - `path_provider: ^2.1.3` (Local file storage, temporary CSV exports)
- **OCR, Barcode & Vision Engine:**
  - `google_mlkit_text_recognition: ^0.13.0` (On-Device Local ML Kit Text Recognition)
  - `mobile_scanner: ^5.1.1` (Barcode / Mini-QR payload extractor for Thai slips)
  - `connectivity_plus: ^6.0.3` (Online/offline state detection)
  - Cloudflare Worker Proxy + Google Gemini 1.5 Flash Vision (`gemini_vision_proxy_service.dart`) for fallback name resolution
- **Media & Photo Library:**
  - `photo_manager: ^3.0.0` (Privacy-first targeted photo library access for banking & income albums)
  - `image_picker: ^1.1.2` (Direct multi-image gallery picker)
- **Notifications:**
  - `flutter_local_notifications: ^17.1.2` (Foreground/background scan progress & batch completion notifications)
- **Analytics, Charts & Document Processing:**
  - `fl_chart: ^0.68.0` (Spending Insights, Category Breakdown Pie Charts)
  - `syncfusion_flutter_pdf: ^26.1.41` (E-Statement PDF Parser for credit card & bank statements)
  - `share_plus: ^9.0.0` (Native file sharing for CSV exports)
  - `intl: ^0.19.0` (Thai locale formatting, currency `฿` & Buddhist calendar conversion)
  - `uuid: ^4.4.0` / `crypto: ^3.0.3` (SHA-256 slip deduplication)

---

## 2. Current Phase
- **Phase:** Feature-Complete Core & Advanced Ingestion (Zero-Click Auto-Accounting)
- **Status:** Stable, Production-Ready, Tested (38/38 Unit Tests Passing 100%)
- **Recent Milestone:** Optional Income Slip Scanning & Album Targeting completed and pushed to `main`.

---

## 3. Completed Tasks (✅)

### Ingestion & OCR Engine
- ✅ **16 Thai Banks & PromptPay Parser (`thai_bank_slip_parser.dart`):**
  - Fully supports KBANK, SCB, KTB, TTB, BBL, GSB, BAY, BAAC, KKP, CIMB, UOB, TISCO, LHB, GHB, TrueMoney, PromptPay.
  - Multi-pattern amount extraction (including Thai government welfare slips e.g. คนละครึ่ง / เป๋าตัง).
  - Thai date & time parser with Buddhist era converter (`2567-2569` ➔ CE).
  - Recipient & Sender name extraction with keyword filtering.
- ✅ **Hybrid OCR Architecture (`hybrid_ocr_service.dart`):**
  - Tier 1: QR & Barcode parsing (EMVCo PromptPay QR, BOT Mini-QR, TrueMoney, BOT biller).
  - Tier 2: Offline ML Kit OCR for Thai text.
  - Tier 3: QR + OCR payload merging.
  - Tier 4: Background cloud retry via Cloudflare Worker Gemini proxy when offline fallback occurs.
- ✅ **Multi-Tier Duplicate Prevention (`duplicate_detection_service.dart`):**
  - Tier 1: Exact image SHA-256 byte hash.
  - Tier 2: Bank transaction Ref ID match.
  - Tier 3: Heuristic fuzzy match (amount + recipient name similarity within ±3 minute window).
- ✅ **Targeted Album Service (`targeted_album_service.dart`):**
  - Privacy-first folder targeting for both banking expense folders and custom income folders.
  - Skips personal photos and only reads whitelisted/selected albums.
- ✅ **Optional Income Slip Scanning (`album_picker_screen.dart`, `slip_scanner_screen.dart`):**
  - Dual-tab album selection for **Expense** vs **Income (Optional)** folders with master toggle.
  - Automatic detection of designated income folders (e.g. `สลิปเงินเข้า`, `สลิปขายของ`, `รายรับ`).
  - Income OCR recognition with sender extraction and automatic categorization (`cat_salary`, `cat_bonus`, `cat_other_income`).
  - Interactive slip type switching (`🟢 รายรับ`, `🔴 รายจ่าย`, `🔵 ย้ายเงิน`) directly from the scanner preview list.
  - Visual distinction in scanner UI (green `+฿` styling for income, breakdown in bottom action bar).

### Accounting & Core Features
- ✅ **Transaction Management:** Full CRUD, quick edit sheets, filtering by date/category/tags/bank, search.
- ✅ **Self-Transfer Detection (`isSelfTransfer`):** Automatically detects transfers between user's own bank accounts (`TransactionType.transfer`).
- ✅ **Budget & Spending Insights:** Category limits, progress cards, near-limit warning (>80%), exceeded alerts, pie charts.
- ✅ **E-Statement PDF Import (`statement_import_screen.dart`):** Parses credit card and bank statements.
- ✅ **In-App Calculator Pad:** Supports arithmetic expressions, operator precedence, decimals.
- ✅ **CSV Export:** Thai-compatible UTF-8 BOM CSV export for Excel.
- ✅ **Dark & Light Mode:** Obsidian dark theme (`#121212`, Mint `#00E599`) and clean light theme.

---

## 4. Database / State Schema

### `TransactionModel`
```dart
class TransactionModel {
  final String id;
  final TransactionType type; // expense, income, transfer
  final double amount;
  final DateTime dateTime;
  final String categoryId;
  final String note;
  final List<String> tags;
  final ThaiBank bankSource;
  final String? slipImagePath;
  final String? slipImageHash;
  final String? slipRefId;
  final bool isFromSlip;
}
```

### `CategoryModel`
```dart
class CategoryModel {
  final String id;
  final String nameThai;
  final String nameEnglish;
  final int iconCodePoint;
  final int colorValue;
  final CategoryType type; // expense, income
  final bool isDefault;
  final List<String> autoKeywords;
}
```

### `TargetedAlbumInfo`
```dart
class TargetedAlbumInfo {
  final String id;
  final String name;
  final int assetCount;
  final bool isBankingFolder;
  final bool isSelected;         // Selected for Expense scanning
  final bool isIncomeFolder;
  final bool isIncomeSelected;   // Selected for Income scanning
}
```

### `SlipParseResult`
```dart
class SlipParseResult {
  final String? id;
  final ThaiBank bank;
  final double amount;
  final DateTime dateTime;
  final String recipientName;
  final String? senderName;
  final String? refId;
  final String? suggestedCategoryId;
  final double confidenceScore;
  final String? imagePath;
  final String? imageHash;
  final String rawOcrText;
  final bool isDuplicate;
  final String? qrPayload;
  final TransactionType transactionType; // expense, income, transfer
}
```

### Local Storage Preferences (Keys)
- `lazyjod_transactions` (JSON array of `TransactionModel`)
- `lazyjod_categories` (JSON array of `CategoryModel`)
- `lazyjod_budgets` (JSON array of `BudgetModel`)
- `lazyjod_recurring` (JSON array of `RecurringRule`)
- `lazyjod_scanned_asset_ids` (Set of scanned asset IDs to skip re-OCR)
- `lazyjod_scan_limit` (Int: 30, 50, 100, 300, 500, 1000)
- `lazyjod_first_launch_done` (Bool)
- `lazyjod_ocr_sync_queue` (JSON array of `OcrSyncItem`)
- `lazyjod_enable_income_scan` (Bool: Optional Income Slip Scanning toggle)
- `lazyjod_income_folder_names` (StringList of income folder keywords)
- `lazyjod_expense_folder_names` (StringList of expense folder keywords)
- `lazyjod_selected_income_album_ids` (StringList of selected income album IDs)
- `lazyjod_selected_expense_album_ids` (StringList of selected expense album IDs)

---

## 5. Next Steps (📌)
1. **User Testing & Review:** Test the optional income scanning on real device with custom income albums.
2. **Batch Import Polish:** Option to mass-select / unselect income vs expense items in slip scanner screen.
3. **Monthly Financial Summary Report:** Monthly income vs expense breakdown report with visual comparison.
