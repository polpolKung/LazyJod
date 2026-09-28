import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/ingestion_provider.dart';
import '../../services/targeted_album_service.dart';

/// The 3 mutually-exclusive scan states for a single album.
enum _AlbumScanMode { none, expense, income }

class AlbumPickerScreen extends ConsumerWidget {
  const AlbumPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ingestionProvider);
    final notifier = ref.read(ingestionProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedExpenseCount = state.albums.where((a) => a.isSelected).length;
    final selectedIncomeCount = state.albums.where((a) => a.isIncomeSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกโฟลเดอร์สแกนสลิป'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? AppColors.darkSurface : AppColors.primaryLight.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'แตะที่ปุ่มด้านล่างแต่ละโฟลเดอร์เพื่อเลือก — ต้องเลือกเองทั้งหมด',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: state.albums.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('กำลังค้นหาอัลบั้มในอุปกรณ์...', style: TextStyle(fontSize: 13)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              itemCount: state.albums.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final album = state.albums[index];
                final mode = album.isIncomeSelected
                    ? _AlbumScanMode.income
                    : album.isSelected
                        ? _AlbumScanMode.expense
                        : _AlbumScanMode.none;

                return _AlbumTile(
                  album: album,
                  mode: mode,
                  isDark: isDark,
                  onModeChanged: (newMode) async {
                    if (newMode == mode) return; // No change

                    // Deselect from current mode first (if any)
                    if (album.isSelected) {
                      await notifier.toggleAlbumSelection(album.id, isIncome: false);
                    }
                    if (album.isIncomeSelected) {
                      await notifier.toggleAlbumSelection(album.id, isIncome: true);
                    }

                    // Then select new mode (if not "none")
                    if (newMode == _AlbumScanMode.expense) {
                      await notifier.toggleAlbumSelection(album.id, isIncome: false);
                    } else if (newMode == _AlbumScanMode.income) {
                      await notifier.toggleAlbumSelection(album.id, isIncome: true);
                    }
                  },
                );
              },
            ),

      // Bottom summary + save bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SummaryChip(
                    icon: Icons.arrow_upward_rounded,
                    label: 'รายจ่าย $selectedExpenseCount โฟลเดอร์',
                    color: selectedExpenseCount > 0 ? AppColors.expense : AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  _SummaryChip(
                    icon: Icons.arrow_downward_rounded,
                    label: 'รายรับ $selectedIncomeCount โฟลเดอร์',
                    color: selectedIncomeCount > 0 ? AppColors.income : AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    (selectedExpenseCount + selectedIncomeCount) == 0
                        ? 'ยืนยัน (ยังไม่ได้เลือกโฟลเดอร์)'
                        : 'ยืนยัน — สแกน ${selectedExpenseCount + selectedIncomeCount} โฟลเดอร์',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (selectedExpenseCount + selectedIncomeCount) > 0
                        ? AppColors.primary
                        : (isDark ? AppColors.darkSurface : Colors.grey.shade300),
                    foregroundColor: (selectedExpenseCount + selectedIncomeCount) > 0
                        ? Colors.black
                        : (isDark ? AppColors.darkTextMuted : Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Album tile ────────────────────────────────────────────────────────────────

class _AlbumTile extends StatelessWidget {
  final TargetedAlbumInfo album;
  final _AlbumScanMode mode;
  final bool isDark;
  final ValueChanged<_AlbumScanMode> onModeChanged;

  const _AlbumTile({
    required this.album,
    required this.mode,
    required this.isDark,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color? tileAccent;
    switch (mode) {
      case _AlbumScanMode.expense:
        borderColor = AppColors.expense;
        tileAccent = AppColors.expense.withOpacity(0.05);
      case _AlbumScanMode.income:
        borderColor = AppColors.income;
        tileAccent = AppColors.income.withOpacity(0.05);
      case _AlbumScanMode.none:
        borderColor = isDark ? AppColors.darkBorder : AppColors.border;
        tileAccent = null;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: tileAccent ?? (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: mode != _AlbumScanMode.none ? 1.8 : 1.0,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + hint badge + count
          Row(
            children: [
              // Album icon
              Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: mode == _AlbumScanMode.expense
                    ? AppColors.expense
                    : mode == _AlbumScanMode.income
                        ? AppColors.income
                        : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  album.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              // Hint badge (keyword-based suggestion — display only, doesn't auto-scan)
              if (album.isIncomeFolder)
                _HintBadge(label: '💰 เงินเข้า', color: AppColors.income)
              else if (album.isBankingFolder)
                _HintBadge(label: '🏦 ธนาคาร', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              '${album.assetCount} รูปภาพ',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3-state mode selector
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'ไม่เลือก',
                  icon: Icons.block_outlined,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                  activeColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  isActive: mode == _AlbumScanMode.none,
                  onTap: () => onModeChanged(_AlbumScanMode.none),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeButton(
                  label: '↑ รายจ่าย',
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.expense,
                  activeColor: AppColors.expense.withOpacity(0.15),
                  isActive: mode == _AlbumScanMode.expense,
                  onTap: () => onModeChanged(
                    mode == _AlbumScanMode.expense ? _AlbumScanMode.none : _AlbumScanMode.expense,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ModeButton(
                  label: '↓ รายรับ',
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.income,
                  activeColor: AppColors.income.withOpacity(0.15),
                  isActive: mode == _AlbumScanMode.income,
                  onTap: () => onModeChanged(
                    mode == _AlbumScanMode.income ? _AlbumScanMode.none : _AlbumScanMode.income,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 3-state button ────────────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color activeColor;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.activeColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.transparent,
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.25),
            width: isActive ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: isActive ? color : color.withOpacity(0.45)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? color : color.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hint badge ────────────────────────────────────────────────────────────────

class _HintBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _HintBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
