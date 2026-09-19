import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/ingestion_provider.dart';

class AlbumPickerScreen extends ConsumerStatefulWidget {
  const AlbumPickerScreen({super.key});

  @override
  ConsumerState<AlbumPickerScreen> createState() => _AlbumPickerScreenState();
}

class _AlbumPickerScreenState extends ConsumerState<AlbumPickerScreen> {
  final TextEditingController _customFolderController = TextEditingController();

  @override
  void dispose() {
    _customFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ingestionProvider);
    final notifier = ref.read(ingestionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('โฟลเดอร์สแกนสลิป'),
      ),
      body: Column(
        children: [
          // Privacy Info Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'ความเป็นส่วนตัว 100%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'แอปจะเข้าถึงเฉพาะโฟลเดอร์ที่คุณเลือกเท่านั้น และไม่อ่านภาพส่วนตัวอื่นๆ ในเครื่องของคุณ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Custom Folder Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customFolderController,
                    decoration: const InputDecoration(
                      hintText: 'เพิ่มชื่อโฟลเดอร์ เช่น MyBankSlips',
                      prefixIcon: Icon(Icons.create_new_folder_outlined, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () {
                    final text = _customFolderController.text.trim();
                    if (text.isNotEmpty) {
                      _customFolderController.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เพิ่มโฟลเดอร์ "$text" ในรายการค้นหาแล้ว')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),

          // Albums List
          Expanded(
            child: state.albums.isEmpty
                ? const Center(
                    child: Text('กำลังค้นหาอัลบั้มในอุปกรณ์ หรือไม่พบอัลบั้มภาพ'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.albums.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final album = state.albums[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: CheckboxListTile(
                          value: album.isSelected,
                          onChanged: (_) => notifier.toggleAlbumSelection(album.id),
                          title: Row(
                            children: [
                              Text(album.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              if (album.isBankingFolder) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ธนาคาร',
                                    style: TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text('${album.assetCount} รูปภาพ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
