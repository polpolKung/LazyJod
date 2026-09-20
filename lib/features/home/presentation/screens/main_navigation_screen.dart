import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../analytics/presentation/screens/dashboard_screen.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../ingestion/presentation/screens/slip_scanner_screen.dart';
import '../../../ingestion/providers/ingestion_provider.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionListScreen(),
    SlipScannerScreen(),
    CategoryManagementScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = LocalStorageService();
      final isFirst = await storage.isFirstLaunch();
      if (isFirst && mounted) {
        _showFirstLaunchScanDialog(context, storage);
      } else {
        ref.read(ingestionProvider.notifier).autoScanAndImportOnLaunch();
      }
    });
  }

  void _showFirstLaunchScanDialog(BuildContext context, LocalStorageService storage) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยินดีต้อนรับสู่ ขี้เกียจจด ✨',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'เลือกจำนวนสลิปที่ต้องการให้ระบบตรวจจับครั้งแรก',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildScanOption(ctx, storage, 30, '⚡ 30 สลิปล่าสุด', 'เร็วมาก (~5 วินาที)', isDark),
              _buildScanOption(ctx, storage, 50, '🚀 50 สลิปล่าสุด (แนะนำ)', 'รวดเร็วและครอบคลุม (~10 วินาที)', isDark, isRecommended: true),
              _buildScanOption(ctx, storage, 100, '📦 100 สลิปล่าสุด', 'สำหรับคนโอนบ่อย (~20 วินาที)', isDark),
              _buildScanOption(ctx, storage, 300, '🗄️ 300 สลิปล่าสุด', 'ตรวจจับย้อนหลังเยอะ (~1 นาที)', isDark),
              _buildScanOption(ctx, storage, 1000, '♾️ ทั้งหมด (สูงสุด 1,000)', 'อาจใช้เวลา 2-3 นาที', isDark),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanOption(
    BuildContext context,
    LocalStorageService storage,
    int count,
    String title,
    String subtitle,
    bool isDark, {
    bool isRecommended = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRecommended
            ? AppColors.primary.withOpacity(isDark ? 0.12 : 0.08)
            : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommended
              ? AppColors.primary.withOpacity(0.4)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: isRecommended ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isRecommended
                ? AppColors.primary
                : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isRecommended ? AppColors.primary : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        ),
        onTap: () async {
          Navigator.of(context).pop();
          await storage.setScanHistoryLimit(count);
          await storage.setFirstLaunchCompleted();
          ref.read(ingestionProvider.notifier).autoScanAndImportOnLaunch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingestionState = ref.watch(ingestionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Auto-scan status banner (with SafeArea and floating card style)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ingestionState.statusMessage.isNotEmpty && ingestionState.statusMessage != ''
                ? SafeArea(
                    bottom: false,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (ingestionState.isScanning)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          else
                            const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ingestionState.statusMessage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => ref.read(ingestionProvider.notifier).clearStatus(),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'ภาพรวม',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'รายการ',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'สแกนสลิป',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'หมวดหมู่',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}
