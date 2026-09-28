# Project Progress — เหมียวจด (LazyJod)

## 1. Tech Stack & Environment
- **Framework:** Flutter (Channel stable, Dart 3.x)
- **State Management:** Riverpod (`flutter_riverpod: ^2.5.1`)
- **Local Storage & Database:**
  - `shared_preferences: ^2.2.3` (Transactions, Categories, Budgets, Recurring rules, Album configurations, Scanned slip IDs, OCR queue)
  - `path_provider: ^2.1.3`
- **OCR, Barcode & Vision Engine:**
  - `google_mlkit_text_recognition: ^0.13.0` (On-Device Local ML Kit OCR)
  - `mobile_scanner: ^5.1.1` (Barcode / QR Scanner for Thai Slip Mini-QR, PromptPay EMV, BOT barcode)
  - `connectivity_plus: ^6.0.3`
  - Cloudflare Worker Proxy + Google Gemini 1.5 Flash Vision (`gemini_vision_proxy_service.dart`) for fallback name enhancement
- **Media & Photo Library:**
  - `photo_manager: ^3.0.0` (Targeted Banking & Income Album Ingestion)
  - `image_picker: ^1.1.2` (Direct Gallery Picking)
- **Notifications:**
  - `flutter_local_notifications: ^17.1.2` (Scan progress & batch completion notifications)
- **Analytics & PDF/Export:**
  - `fl_chart: ^0.68.0` (Spending Insights, Category Pie Charts)
  - `syncfusion_flutter_pdf: ^26.1.41` (E-Statement Statement PDF Parser)
  - `share_plus: ^9.0.0` (CSV Export sharing)
  - `intl: ^0.19.0` (Thai locale formatting, currency & relative dates)
  - `uuid: ^4.4.0` / `crypto: ^3.0.3` (SHA-256 slip deduplication)

---

## 2. Current Phase
- **Phase:** Feature-Complete Core & Advanced Ingestion (Zero-Click Auto-Accounting)
- **Status:** Stable, Production-Ready with Optional Income Slip Scanning added.

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
  - Skips personal photos and only reads targeted albums.
- ✅ **Optional Income Slip Scanning (`album_picker_screen.dart`, `slip_scanner_screen.dart`):**
  - Dual-tab album selection for **Expense** vs **Income (Optional)** folders.
  - Master toggle for income slip scanning.
  - Automatic detection of designated income folders (e.g. `สลิปเงินเข้า`, `สลิปขายของ`, `รายรับ`).
  - Income OCR recognition with sender extraction and automatic categorization (`cat_salary`, `cat_bonus`, `cat_other_income`).
  - Interactive slip type switching (`🟢 รายรับ`, `🔴 รายจ่าย`, `🔵 ย้ายเงิน`) directly from the scanner preview list.
  - Visual distinction in scanner UI (green `+฿` styling for income, breakdown in bottom action bar).

### Accounting & Features
- ✅ **Transaction Management:** Full CRUD, quick edit sheets, filtering by date/category/tags/bank, search.
- ✅ **Self-Transfer Detection (`isSelfTransfer`):** Automatically detects transfers between user's own bank accounts (`TransactionType.transfer`).
- ✅ **Budget & Spending Insights:** Category limits, progress cards, near-limit warning (>80%), exceeded alerts, pie charts.
- ✅ **E-Statement PDF Import (`statement_import_screen.dart`):** Parses credit card and bank statements.
- ✅ **In-App Calculator Pad:** Supports expressions, operator precedence, decimals.
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
