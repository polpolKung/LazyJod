import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../analytics/presentation/screens/dashboard_screen.dart';
import '../../../categories/presentation/screens/category_management_screen.dart';
import '../../../ingestion/presentation/screens/slip_scanner_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../transactions/presentation/screens/transaction_entry_screen.dart';
import '../../../transactions/presentation/screens/transaction_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionListScreen(),
    SlipScannerScreen(),
    CategoryManagementScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'ภาพรวม',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'รายการ',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primary),
            label: 'สแกนสลิป',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: AppColors.primary),
            label: 'หมวดหมู่',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'ตั้งค่า',
          ),
        ],
      ),
    );
  }
}
