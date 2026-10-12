# 🤖 AI Instruction / Autonomous Progress Tracking & Git Push Rule
> **CRITICAL DIRECTIVE FOR ALL FUTURE CHATS / SESSIONS:**
> You are working as the autonomous development assistant on the **"Income-Expense App" (เหมียวจด / LazyJod)** project.
>
> **MANDATORY RULES:**
> 1. **AUTONOMOUS PROGRESS UPDATE:** You must autonomously update or rewrite this `progress.md` file **EVERY SINGLE TIME** a feature, component, bug fix, or task is successfully implemented. Do NOT wait for the user to ask or remind you to do this.
> 2. **AUTONOMOUS GIT COMMIT & PUSH:** You must stage, commit with a clear descriptive message, and **PUSH TO GIT (`git push origin <branch>`) EVERY SINGLE TIME** a task, feature, or fix is done. Do NOT wait for the user to tell you to commit or push.
>
> **When a new chat starts with:** `"Read progress.md and continue."`
> 1. Read this `progress.md` file completely to grasp the codebase context, tech stack, architecture, and completed features.
> 2. Check the **Next Steps (📌)** section to know exactly where the project stands.
> 3. Proactively report your understanding and propose the next steps to proceed immediately.


---

# Project Progress — Lazy Jod (เลซี่จด)

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
  - `image_picker: ^1.1.2` (Direct multi-image gallery picker with Income/Expense type selector)
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
- **Phase:** Feature-Complete Core & Advanced Ingestion + Prominent Logo Mint Wallpaper & Cartoon Comic Doodle Line Art
- **Status:** Stable, Production-Ready, Tested (49/49 Unit Tests Passing 100%)
- **Recent Milestone:** Prominent Logo Mint & Cartoon Comic Doodle Line Art — background upgraded to distinct pastel mint from logo (`#BDE6D4`), cream white cards with bold 2.0px cartoon ink outlines (`#2A3830`), sticker offset shadows, and hand-drawn cartoon comic feel matching user reference images.

---

## 3. Completed Tasks (✅)

### Interactive Category Dashboard Navigation & Filtering (Latest)
- ✅ **Interactive Category Breakdown Chart & Legend (`category_pie_chart.dart`, `dashboard_screen.dart`):**
  - Enabled tap interaction on both the Pie Chart sections and the top 5 Category legend list rows.
  - Added clean visual feedback with ripple (`InkWell`), category percentage, amount, and cute chevron indicator (`Icons.chevron_right_rounded`).
  - Tapping any category on the dashboard automatically filters transactions by that specific category (`setCategory(category.categoryId)`) and smoothly navigates to `TransactionListScreen`.
- ✅ **Spending Insights Category Tile Navigation (`spending_insights_screen.dart`):**
  - Tapping any category tile in the detailed monthly category breakdown list sets the filter to that category and navigates to `TransactionListScreen`.
- ✅ **Active Filter Banner & Quick Clear in Transaction List (`transaction_list_screen.dart`):**
  - Added cute cartoon-styled active filter bar at the top of `TransactionListScreen` showing the currently filtered category name (e.g. `หมวดหมู่: อาหารและเครื่องดื่ม`).
  - Added one-tap "ล้างตัวกรอง" button inside the banner to quickly restore the full transaction list view without having to open the filter menu.
  - All 49/49 automated unit tests passing (100%).

### Zero-Click Scan Auto-Import & Launch/Category Bug Fixes
- ✅ **Fixed Launch Black Screen Bug (`launch_background.xml`, `launch_image.png`, `styles.xml`):**
  - Resolved black screen on app startup caused by `<bitmap>` attempting to decode adaptive XML icon `@mipmap/ic_launcher`. Added dedicated PNG raster `launch_image.png` and updated `values-night/styles.xml` to ensure clean mint theme background and logo display on all Android versions and dark mode settings.
- ✅ **Zero-Click Instant Slip Auto-Import (`ingestion_provider.dart`):**
  - Streamlined ingestion UX: once slip scanning finishes (whether from folders, gallery, or launch auto-scan), all valid non-duplicate slips are automatically imported directly into transactions without presenting intermediate confirmation checkbox screen.
  - Shows friendly notification banner (e.g. "จดสลิปใหม่ให้แล้ว X รายการเรียบร้อย! 🦥✨") which auto-dismisses after 4 seconds.
- ✅ **Fixed Category Custom Image Persistence (`category_edit_screen.dart`):**
  - Resolved bug where editing a category erased its custom uploaded image icon.
  - Correctly initialized `_customImagePath = c.customImagePath` in `initState` and copied picked image files permanently to `getApplicationDocumentsDirectory()/category_icons/` to guarantee permanent persistence.

### Brand Splash, Dynamic Calendar Badge & In-Place APK Updates
- ✅ **Theme Launch Splash Screen (`launch_background.xml`, `colors.xml`):**
  - Replaced native Android blank white launch screen with brand mint wallpaper (`#BDE6D4`) and centered Lazy Jod logo (`ic_launcher`), eliminating the white flash on app startup.
- ✅ **Dynamic Cartoon Calendar Badge (`dashboard_screen.dart`):**
  - Replaced static `📅` emoji (which had "17" permanently baked into the emoji glyph) with custom `_CartoonCalendarIcon` badge displaying the real day number (`DateTime.now().day`), cute coral red binder header, and cartoon ink outlines.
- ✅ **In-Place APK Update & Release Signing Key (`lazyjod.jks`, `build.gradle`, `build_apk.yml`):**
  - Created persistent production keystore `lazyjod.jks` and configured release signing in `build.gradle` to ensure identical cryptographic signatures across all builds.
  - Configured GitHub Actions to automatically pass `--build-number=${{ github.run_number }}` so `versionCode` increments on every build, allowing users to update APKs directly in-place without uninstalling and losing data.

### UX Enhancements, Color Wheel & Date-Based Scanning
- ✅ **Auto-Dismiss Scan Notification Banner (`ingestion_provider.dart`):**
  - Result banners (such as "ไม่พบสลิปใหม่ในวันนี้", "สแกนเสร็จสิ้น...", "นำเข้าข้อมูลสำเร็จ!") now disappear automatically after 4 seconds without forcing user to tap X.
- ✅ **Removed Redundant Privacy-First Card (`settings_screen.dart`):**
  - Cleaned up settings screen by removing the prominent green Privacy-First card.
- ✅ **Full Category Color Customization & Custom Image Upload (`category_edit_screen.dart`, `category_icon_bubble.dart`, `category_model.dart`):**
  - Added full HSV color palette sliders (เฉดสี, ความจัด, ความสว่าง) to tune any shade/hex desired.
  - Expanded theme-friendly preset swatches to 20 pastel shades matching app theme.
  - Added support for uploading custom icon images directly from device photo gallery via `ImagePicker`.
  - Updated `CategoryIconBubble` and `CategoryModel` serialization to render custom uploaded images alongside Material icons.
- ✅ **Date-Based Slip Scanning Replacement (`targeted_album_service.dart`, `ingestion_provider.dart`, `album_picker_screen.dart`, `settings_screen.dart`, `local_storage_service.dart`):**
  - Replaced arbitrary slip count limit (30, 50, 100) with intuitive date-based cut-off (`getScanFromDate` / `setScanFromDate`).
  - Scans only slips taken on or after the specified date (e.g. 7 days, 30 days, 90 days, 180 days, this year, or custom date via `showDatePicker`).
  - Added interactive date cut-off badge in `AlbumPickerScreen` bottom bar and in `SettingsScreen`.

### Scanner UX & Category Icon Accuracy Rework
- ✅ **Category Icon Accuracy (`category_model.dart`, `local_storage_service.dart`):**
  - Resolved mismatched icon glyphs in category picker (e.g. food showing TV monitor, transport showing dropper, bills showing flash off).
  - Implemented explicit ID-based `IconData get icon` mapper returning genuine `Icons.*_rounded` (restaurant, directions_car, shopping_bag, receipt_long, home, sports_esports, favorite, pets, payments, savings, account_balance_wallet).
  - Updated `CategoryModel.defaultCategories` and bumped `_currentCategoriesVersion` to `3` for seamless auto-migration.
- ✅ **Slip Scanner Screen UX Overhaul (`slip_scanner_screen.dart`):**
  - Removed top privacy banner ("สแกนเฉพาะอัลบั้มที่เลือก (Privacy-First)...") to keep the interface clean and focused.
  - Added interactive active folders preview card showing selected expense and income folders.
  - Centered folder management button ("เลือกโฟลเดอร์ / อัลบั้มสลิปที่จะสแกน") directly alongside the scan action buttons.
- ✅ **First Launch Album Review Flow (`main_navigation_screen.dart`, `album_picker_screen.dart`):**
  - On first app launch, directly presents `AlbumPickerScreen(isFirstLaunch: true)` with detected banking folders pre-selected by default.
  - Users can clearly see which bank folders are included, add/remove folders, and tap "ยืนยันและเริ่มสแกนสลิป" to begin scanning immediately.

### Prominent Logo Mint & Cartoon Comic Line Art Rework
- ✅ **Logo Mint Wallpaper (`app_colors.dart`):**
  - App background upgraded from washed-out white to noticeable pastel mint wallpaper (`#BDE6D4`), matching the brand logo's mint background.
- ✅ **Cartoon Comic Ink Line Art (`app_colors.dart`, `app_theme.dart`):**
  - Added signature 2.0px dark ink cartoon outlines (`#2A3830`) on all cards, pods, floating dock, and inputs with sticker offset shadows (`Offset(0, 3-4)`).
- ✅ **Comic Panel Mascot & Pods (`jod_mascot.dart`, `dashboard_screen.dart`):**
  - Jod mascot styled like an authentic cartoon sticker panel with sleepy sloth avatar and ink-bordered pill badge.
  - Quick action buttons styled as cute squircle cartoon pods.
- ✅ **Floating Cartoon Dock (`main_navigation_screen.dart`):**
  - Floating pill dock with 2.0px cartoon ink border and sticker shadow on the mint wallpaper.
- ✅ **All 49/49 Unit Tests Passing (100%):** Verified zero regression across all core features.
    - Text: Forest Slate (`#2E3E33`) & Sage Muted (`#5D7766`, `#8BA694`)
    - Expense: Soft Strawberry Milk Pink (`#F28A94`)
    - Income: Fresh Matcha Green (`#65B880`)
    - Transfer: Soft Retro Blue (`#78B8CC`)
- ✅ **Single Unified Theme (No Dark/Light Mode Split):**
  - Unified `AppTheme.darkTheme` and `AppTheme.lightTheme` to both render the soothing matcha pastel palette, preventing OS-level dark mode from turning the app into harsh obsidian/neon.
  - Set `ThemeNotifier` default and state to `ThemeMode.light`.
  - Replaced dark mode toggle in Settings (`_ThemeToggleCard`) with an active theme badge: "ธีมหลัก: มัทฉะพาสเทล & น้องจ้อด 🌿 (ใช้งานอยู่ ✨)".
- ✅ **Retro Sticker Window & Card Styling (`jod_mascot.dart`, `dashboard_screen.dart`):**
  - Added retro 3-dot top window accent (pink, yellow, green dots + "LAZY JOD CLUB 🌿") to `JodMascotCard`.
  - Replaced hardcoded dark/gray gradients on dashboard overview cards with pure milk surface (`#FFFFFF`), matcha milk income box, and soft strawberry expense box.
- ✅ **Squircle Sticker Icon Bubble (`category_icon_bubble.dart`):**
  - Upgraded `CategoryIconBubble` to squircle sticker styling matching Image 3: smooth rounded squircle corners (`size * 0.34`), subtle ambient shadow, soft pastel blended backgrounds (`Color.alphaBlend`), and matching outline borders.

### UI/UX Rework & Brand Transformation (Previous)
- ✅ **14 Distinctive Pastel Category Icons & Bubble Widget (`category_model.dart`, `category_icon_bubble.dart`):**
  - Replaced generic icons with expressive, semantically matching rounded icons and emoji metadata:
    - 🍜 Food & Drinks: `Icons.ramen_dining_rounded` (Pastel Salmon `#FFA07A`)
    - 🚊 Transportation: `Icons.commute_rounded` (Pastel Cyan `#48CAE4`)
    - 🛍️ Shopping: `Icons.shopping_bag_rounded` (Pastel Blossom `#FF85A1`)
    - 🦥 Uncategorized: `Icons.psychology_alt_rounded` (Pastel Sloth Honey `#FFB703`)
    - 🔄 Transfer: `Icons.swap_horizontal_circle_rounded` (Pastel Azure `#5AA9E6`)
    - ⚡ Bills & Utilities: `Icons.electric_bolt_rounded` (Pastel Amber `#F4A261`)
    - 🏡 Housing & Rent: `Icons.cottage_rounded` (Pastel Lavender `#A29BFE`)
    - 🎮 Entertainment: `Icons.sports_esports_rounded` (Pastel Lilac `#C77DFF`)
    - 🧴 Health & Beauty: `Icons.spa_rounded` (Pastel Spa Mint `#70C1B3`)
    - 🐾 Pets: `Icons.cruelty_free_rounded` (Pastel Caramel `#E0A96D`)
    - 💬 Other Expense: `Icons.bubble_chart_rounded` (Pastel Slate `#8E9AAF`)
    - 💵 Salary & Wages: `Icons.payments_rounded` (Pastel Emerald `#52B788`)
    - ✨ Bonus & Side Hustle: `Icons.auto_awesome_rounded` (Pastel Sunshine `#FEE440`)
    - 💰 Other Income: `Icons.price_check_rounded` (Pastel Ocean Mint `#56CFE1`)
  - Auto-migration versioning in `LocalStorageService` so returning users seamlessly receive the new pastel icons.
- ✅ **App Launcher Icon Automation:**
  - Automated generation from `assets/icons/iconApp.png` across all Android mipmap densities (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Configured adaptive icon with mint `#9BEAC2` background and centered mascot foreground.
  - **CI/CD Resource Fix:** Explicitly un-ignored `android/app/src/main/res/**` in `.gitignore` so all generated `ic_launcher_foreground.png` assets are tracked and linked properly by AAPT during `assembleRelease`.
- ✅ **App Renaming & APK Output Configuration:**
  - Renamed from "เหมียวจด" to **"Lazy Jod (เลซี่จด)"** across `AndroidManifest.xml`, `AppConstants`, navigation, dashboard, and settings.
  - Configured `android/app/build.gradle` `applicationVariants` to automatically output `LazyJod.apk`.
- ✅ **Cheeky Mascot "จ้อด" (Lazy Jod) Integration (`jod_mascot.dart`):**
  - Created `JodMascotAvatar` and `JodMascotCard` with situational humorous / lazy commentary.
  - Embedded Jod into `EmptyStateWidget`, Dashboard Header, Scan Screen, and Onboarding Welcome Sheet.

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
  - Tier 4: **Gemini Vision always runs when online** (not just on fallback names). Gemini is the primary name extraction source; local OCR provides amount/date/bank/refId. Offline: local OCR only.
  - `GeminiVisionProxyService.enhance()` now always carries `transactionType` from `localResult` to prevent income slips reverting to expense after Gemini re-parse.
- ✅ **Multi-Tier Duplicate Prevention (`duplicate_detection_service.dart`):**
  - Tier 1: Exact image SHA-256 byte hash.
  - Tier 2: Bank transaction Ref ID match.
  - Tier 3: Heuristic fuzzy match (amount + recipient name similarity within ±3 minute window).
- ✅ **Targeted Album Service (`targeted_album_service.dart`):**
  - Privacy-first folder targeting for both banking expense folders and custom income albums.
  - **Album Isolation Fix:** Albums matching income keywords or selected for income are strictly excluded from banking expense classification.
  - **Explicit-Only Scan Mode (UX Redesign):**
    - `fetchAssetsToScan` now scans **ONLY albums with IDs explicitly selected** by the user — zero keyword fallback. Unticking an album = not scanned, guaranteed.
    - `getAvailableAlbums`: On first launch (never configured), auto-selects known banking app albums (K PLUS, SCB EASY, Krungthai NEXT, etc.) as a sensible starting point. After user opens the picker and toggles anything, the system switches to **explicit-only mode** permanently.
    - `LocalStorageService.isScanAlbumsConfigured()` tracks whether user has ever explicitly configured albums.
  - Income folders NEVER auto-selected — user must explicitly choose.
- ✅ **Album Picker Screen UX Redesign (`album_picker_screen.dart`):**
  - **Replaced confusing 2-tab layout** (โฟลเดอร์รายจ่าย / โฟลเดอร์รายรับ) with a **single unified list**.
  - Each album now has a **3-state inline toggle**: `[ ไม่เลือก ] [ ↑ รายจ่าย ] [ ↓ รายรับ ]`.
  - Keyword-based badges (`🏦 ธนาคาร`, `💰 เงินเข้า`) are **display-only hints** — they never drive scanning.
  - Removed confusing custom folder keyword text input.
  - Clean bottom bar shows live count: "รายจ่าย X โฟลเดอร์ · รายรับ Y โฟลเดอร์" + "ยืนยัน" button.
- ✅ **Gallery Pick Type Selector (`slip_scanner_screen.dart`):**
  - Direct gallery picking now prompts the user via BottomSheet:
    - 🟢 **สลิปรายรับ (Income)** — processes all chosen images as income.
    - 🔴 **สลิปรายจ่าย (Expense)** — processes all chosen images as expense.
  - Added batch type switching chips at the top of the scan preview list.
  - Interactive per-item type switcher badge remains available.
- ✅ **Fixed Navigation Black Screen Bug (`slip_scanner_screen.dart`):**
  - Replaced unqualified `Navigator.pop()` with safe `canPop()` check.
- ✅ **Verified with Real User KTB Slip (`test_slips/Income/1790620289198.jpg`):**
  - Extracted: Bank KTB, Amount 2,000.00 THB, Ref `Afdc8e9b2a067421e`, Sender `นายทิพย์ ท***`, Recipient `นายฌานพล ทิพวัน`.
  - Transaction successfully generated with type `TransactionType.income`, note `รับเงินจาก: นายทิพย์ ท***`.
- ✅ **Scanner UI Streamlined (`slip_scanner_screen.dart`):**
  - Removed duplicate folder picker button. Unified folder management via the interactive folder overview card and single primary scan button.
- ✅ **KTB Bank Misidentification & Time Parsing Fix (`thai_bank_slip_parser.dart`):**
  - Prioritized header and sender ("จาก / from") lines over recipient lines when identifying bank, stopping destination account keywords from misidentifying Krungthai slips.
  - Strict time regex requiring valid 24-hr format or `น.` suffix, preventing decimal transfer amounts from being mistaken as transfer times.
- ✅ **Segmented Category Quick Picker (`category_quick_picker_sheet.dart`):**
  - Added clean segmented tab switcher (`💸 รายจ่าย` / `💰 รายรับ`), automatically defaulting to transaction's type (income or expense) when opened.
- ✅ **Seamless First-Launch Permissions (`album_picker_screen.dart`):**
  - Added AppLifecycleState resume detection: upon granting permission in Android dialog, album list refreshes automatically without needing manual tap.
- ✅ **Auto-Dismiss Scanner Banner (`main_navigation_screen.dart`, `ingestion_provider.dart`):**
  - Fixed persistent status banner on subsequent scans; automatically dismisses after 4 seconds.

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
- `lazyjod_income_folder_names` (StringList of income folder keywords)
- `lazyjod_expense_folder_names` (StringList of expense folder keywords)
- `lazyjod_selected_income_album_ids` (StringList of selected income album IDs)
- `lazyjod_selected_expense_album_ids` (StringList of selected expense album IDs)

---

## 5. Next Steps (📌)
1. **User Testing on Real Device:** Verify end-to-end user experience with both gallery picking and targeted album scan.
2. **Monthly Financial Summary Report:** Monthly income vs expense breakdown report with visual comparison.
3. **Transaction Search & Filter Enhancements:** Quick filter for income-only or expense-only in transaction list.
