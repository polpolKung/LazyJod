import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../widgets/icon_picker_dialog.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final CategoryModel? initialCategory;

  const CategoryEditScreen({super.key, this.initialCategory});

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _keywordsController;
  late CategoryType _type;
  late int _iconCodePoint;
  late int _colorValue;

  static const List<Color> _presetColors = [
    Color(0xFFFF7A45),
    Color(0xFF1890FF),
    Color(0xFF52C41A),
    Color(0xFFFAAD14),
    Color(0xFFEB2F96),
    Color(0xFF722ED1),
    Color(0xFF13C2C2),
    Color(0xFFF5222D),
    Color(0xFF2F54EB),
    Color(0xFFFA8C16),
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.initialCategory;
    if (c != null) {
      _nameController = TextEditingController(text: c.nameThai);
      _keywordsController = TextEditingController(text: c.autoKeywords.join(', '));
      _type = c.type;
      _iconCodePoint = c.iconCodePoint;
      _colorValue = c.colorValue;
    } else {
      _nameController = TextEditingController();
      _keywordsController = TextEditingController();
      _type = CategoryType.expense;
      _iconCodePoint = Icons.category.codePoint;
      _colorValue = _presetColors.first.value;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อหมวดหมู่')),
      );
      return;
    }

    final keywords = _keywordsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final model = CategoryModel(
      id: widget.initialCategory?.id ?? 'cat_${const Uuid().v4()}',
      nameThai: name,
      nameEnglish: name,
      iconCodePoint: _iconCodePoint,
      colorValue: _colorValue,
      type: _type,
      isDefault: widget.initialCategory?.isDefault ?? false,
      autoKeywords: keywords,
    );

    if (widget.initialCategory != null) {
      ref.read(categoryProvider.notifier).updateCategory(model);
    } else {
      ref.read(categoryProvider.notifier).addCategory(model);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCategory != null ? 'แก้ไขหมวดหมู่' : 'สร้างหมวดหมู่ใหม่'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon & Color Preview
            Center(
              child: GestureDetector(
                onTap: () async {
                  final icon = await showDialog<IconData>(
                    context: context,
                    builder: (_) => const IconPickerDialog(),
                  );
                  if (icon != null) {
                    setState(() => _iconCodePoint = icon.codePoint);
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(_colorValue).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(_colorValue), width: 2),
                  ),
                  child: Icon(
                    IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
                    color: Color(_colorValue),
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'แตะที่ไอคอนเพื่อเปลี่ยน',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อหมวดหมู่ (ภาษาไทย)',
                hintText: 'เช่น ค่านมลูก, ค่าบุฟเฟต์',
              ),
            ),
            const SizedBox(height: 20),

            // Color Palette Picker
            const Text(
              'เลือกสีประจำหมวดหมู่',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _presetColors.map((color) {
                final isSelected = color.value == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = color.value),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Smart Keywords for Auto-Categorization
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: 'คีย์เวิร์ดตรวจจับอัตโนมัติจากสลิป (คั่นด้วยจุลภาค ,)',
                hintText: 'เช่น ชาบู, หมูกระทะ, สุกี้, barbecue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
