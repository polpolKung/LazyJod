import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/jod_mascot.dart';
import '../../../analytics/presentation/screens/dashboard_screen.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../ingestion/presentation/screens/album_picker_screen.dart';
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
        // Pre-load device albums with default bank folder selections
        await ref.read(ingestionProvider.notifier).loadAlbums();
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AlbumPickerScreen(isFirstLaunch: true),
            ),
          );
        }
      } else {
        ref.read(ingestionProvider.notifier).autoScanAndImportOnLaunch();
      }
    });
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cartoonOutline.withOpacity(0.12),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
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
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SafeArea(
          top: false,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cartoonOutline.withOpacity(0.14),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'ภาพรวม'),
                _buildNavItem(1, Icons.receipt_long_rounded, 'รายการ'),
                _buildNavItem(2, Icons.qr_code_scanner_rounded, 'สแกนสลิป'),
                _buildNavItem(3, Icons.category_rounded, 'หมวดหมู่'),
                _buildNavItem(4, Icons.settings_rounded, 'ตั้งค่า'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(color: AppColors.cartoonOutline, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected ? AppColors.cartoonOutline : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? AppColors.cartoonOutline : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
