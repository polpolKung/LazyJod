import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // Trigger zero-click auto-scan when app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ingestionProvider.notifier).autoScanAndImportOnLaunch();
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
