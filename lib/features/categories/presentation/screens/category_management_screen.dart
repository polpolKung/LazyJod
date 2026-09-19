import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import 'category_edit_screen.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการหมวดหมู่'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              title: Text(cat.nameThai, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text(
                cat.autoKeywords.isNotEmpty ? 'คีย์เวิร์ด: ${cat.autoKeywords.take(3).join(', ')}...' : 'ไม่มีคีย์เวิร์ดพิเศษ',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CategoryEditScreen(initialCategory: cat)),
                      );
                    },
                  ),
                  if (!cat.isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.expense),
                      onPressed: () {
                        ref.read(categoryProvider.notifier).deleteCategory(cat.id);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CategoryEditScreen()),
          );
        },
      ),
    );
  }
}
