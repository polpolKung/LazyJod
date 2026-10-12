import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../widgets/category_icon_bubble.dart';
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
  String? _customImagePath; // Path to a user-picked custom image icon

  /// Theme-matching pastel presets shown as quick swatches
  static const List<Color> _presetColors = [
    Color(0xFF56C596), // Pastel Mint Green (primary)
    Color(0xFF48CAE4), // Pastel Sky Cyan
    Color(0xFFFF85A1), // Pastel Blossom Pink
    Color(0xFFFFA07A), // Pastel Salmon Peach
    Color(0xFFFFB703), // Pastel Honey Gold
    Color(0xFFA29BFE), // Pastel Soft Lavender
    Color(0xFFC77DFF), // Pastel Lilac
    Color(0xFF70C1B3), // Pastel Spa Mint
    Color(0xFFF4A261), // Pastel Warm Amber
    Color(0xFFE0A96D), // Pastel Caramel
    Color(0xFF52B788), // Pastel Emerald
    Color(0xFF56CFE1), // Pastel Ocean Aqua
    Color(0xFFFF6B6B), // Coral Red
    Color(0xFFFFD166), // Sunflower Yellow
    Color(0xFF06D6A0), // Mint Teal
    Color(0xFF118AB2), // Steel Blue
    Color(0xFFEF476F), // Raspberry
    Color(0xFFB5838D), // Dusty Rose
    Color(0xFF6D6875), // Muted Mauve
    Color(0xFF588157), // Forest Green
  ];

  // HSV wheel state
  double _hue = 180.0;
  double _saturation = 0.45;
  double _brightness = 0.85;

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
      // Extract HSV from saved color
      final hsv = HSVColor.fromColor(Color(_colorValue));
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    } else {
      _nameController = TextEditingController();
      _keywordsController = TextEditingController();
      _type = CategoryType.expense;
      _iconCodePoint = Icons.category.codePoint;
      _colorValue = _presetColors.first.value;
      final hsv = HSVColor.fromColor(_presetColors.first);
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Color get _currentColor => HSVColor.fromAHSV(1.0, _hue, _saturation, _brightness).toColor();

  void _pickPresetColor(Color c) {
    final hsv = HSVColor.fromColor(c);
    setState(() {
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _brightness = hsv.value;
      _colorValue = c.value;
    });
  }

  void _updateColorFromHSV() {
    setState(() {
      _colorValue = _currentColor.value;
    });
  }

  Future<void> _pickCustomImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _customImagePath = picked.path;
      });
    }
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
      iconCodePoint: _customImagePath != null ? 0 : _iconCodePoint,
      colorValue: _colorValue,
      type: _type,
      isDefault: widget.initialCategory?.isDefault ?? false,
      autoKeywords: keywords,
      customImagePath: _customImagePath,
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
            // ── Icon Preview ──────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  // Icon bubble preview
                  GestureDetector(
                    onTap: _customImagePath != null ? null : () async {
                      final icon = await showDialog<IconData>(
                        context: context,
                        builder: (_) => const IconPickerDialog(),
                      );
                      if (icon != null) {
                        setState(() {
                          _iconCodePoint = icon.codePoint;
                          _customImagePath = null;
                        });
                      }
                    },
                    child: _customImagePath != null
                        ? Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.cartoonOutline, width: 2.0),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cartoonOutline.withOpacity(0.15),
                                  offset: const Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                              image: DecorationImage(
                                image: FileImage(File(_customImagePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : CategoryIconBubble(
                            overrideIcon: IconData(_iconCodePoint, fontFamily: 'MaterialIcons'),
                            overrideColor: _currentColor,
                            size: 80,
                            isSelected: true,
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Two buttons: pick icon / upload image
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final icon = await showDialog<IconData>(
                            context: context,
                            builder: (_) => const IconPickerDialog(),
                          );
                          if (icon != null) {
                            setState(() {
                              _iconCodePoint = icon.codePoint;
                              _customImagePath = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.grid_view_rounded, size: 16),
                        label: const Text('เลือกไอคอน', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _pickCustomImage,
                        icon: const Icon(Icons.photo_library_rounded, size: 16),
                        label: const Text('อัปโหลดรูป', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                      ),
                      if (_customImagePath != null)
                        TextButton.icon(
                          onPressed: () => setState(() => _customImagePath = null),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('ลบรูป', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Name ──────────────────────────────────────────────────────
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อหมวดหมู่ (ภาษาไทย)',
                hintText: 'เช่น ค่านมลูก, ค่าบุฟเฟต์',
              ),
            ),
            const SizedBox(height: 24),

            // ── Color Section ─────────────────────────────────────────────
            const Text(
              'เลือกสีประจำหมวดหมู่',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Preset swatches
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presetColors.map((color) {
                final isSelected = color.value == _colorValue;
                return GestureDetector(
                  onTap: () => _pickPresetColor(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.cartoonOutline, width: 2.5)
                          : Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom color wheel label
            Row(
              children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: _currentColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('ปรับสีเองได้ทุกเฉด', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),

            // Hue slider
            _ColorSliderRow(
              label: 'เฉดสี',
              value: _hue,
              min: 0,
              max: 360,
              gradient: const LinearGradient(colors: [
                Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF), Color(0xFFFF0000),
              ]),
              onChanged: (v) { _hue = v; _updateColorFromHSV(); },
            ),
            const SizedBox(height: 8),

            // Saturation slider
            _ColorSliderRow(
              label: 'ความจัด',
              value: _saturation,
              min: 0,
              max: 1,
              gradient: LinearGradient(colors: [
                Colors.white,
                HSVColor.fromAHSV(1, _hue, 1.0, _brightness).toColor(),
              ]),
              onChanged: (v) { _saturation = v; _updateColorFromHSV(); },
            ),
            const SizedBox(height: 8),

            // Brightness slider
            _ColorSliderRow(
              label: 'ความสว่าง',
              value: _brightness,
              min: 0,
              max: 1,
              gradient: LinearGradient(colors: [
                Colors.black,
                HSVColor.fromAHSV(1, _hue, _saturation, 1.0).toColor(),
              ]),
              onChanged: (v) { _brightness = v; _updateColorFromHSV(); },
            ),
            const SizedBox(height: 8),

            // Live color preview chip
            Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cartoonOutline, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '#${_colorValue.toRadixString(16).toUpperCase().substring(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _brightness > 0.5 ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Keywords ─────────────────────────────────────────────────
            TextField(
              controller: _keywordsController,
              decoration: const InputDecoration(
                labelText: 'คีย์เวิร์ดตรวจจับอัตโนมัติจากสลิป (คั่นด้วยจุลภาค ,)',
                hintText: 'เช่น ชาบู, หมูกระทะ, สุกี้, barbecue',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Helper widget: color slider row ──────────────────────────────────────────
class _ColorSliderRow extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;

  const _ColorSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.gradient,
    required this.onChanged,
  });

  @override
  State<_ColorSliderRow> createState() => _ColorSliderRowState();
}

class _ColorSliderRowState extends State<_ColorSliderRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(widget.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackShape: _GradientSliderTrackShape(gradient: widget.gradient),
            ),
            child: Slider(
              value: widget.value,
              min: widget.min,
              max: widget.max,
              onChanged: (v) {
                setState(() {});
                widget.onChanged(v);
              },
              activeColor: Colors.transparent,
              inactiveColor: Colors.transparent,
              thumbColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientSliderTrackShape extends SliderTrackShape {
  final LinearGradient gradient;
  const _GradientSliderTrackShape({required this.gradient});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 4;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final trackRect = getPreferredRect(parentBox: parentBox, offset: offset, sliderTheme: sliderTheme);
    final rRect = RRect.fromRectAndRadius(trackRect, const Radius.circular(6));
    final paint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;
    context.canvas.drawRRect(rRect, paint);
    // Outline
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    context.canvas.drawRRect(rRect, borderPaint);
  }
}
