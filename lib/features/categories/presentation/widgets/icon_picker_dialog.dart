import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  static const List<IconData> iconsList = [
    Icons.ramen_dining_rounded,
    Icons.fastfood_rounded,
    Icons.local_cafe_rounded,
    Icons.cake_rounded,
    Icons.commute_rounded,
    Icons.directions_car_rounded,
    Icons.directions_subway_rounded,
    Icons.local_gas_station_rounded,
    Icons.flight_rounded,
    Icons.shopping_bag_rounded,
    Icons.local_mall_rounded,
    Icons.storefront_rounded,
    Icons.electric_bolt_rounded,
    Icons.water_drop_rounded,
    Icons.wifi_rounded,
    Icons.phone_iphone_rounded,
    Icons.cottage_rounded,
    Icons.home_rounded,
    Icons.apartment_rounded,
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.spa_rounded,
    Icons.fitness_center_rounded,
    Icons.favorite_rounded,
    Icons.medication_rounded,
    Icons.cruelty_free_rounded,
    Icons.pets_rounded,
    Icons.payments_rounded,
    Icons.auto_awesome_rounded,
    Icons.savings_rounded,
    Icons.swap_horizontal_circle_rounded,
    Icons.help_center_rounded,
    Icons.bubble_chart_rounded,
    Icons.work_rounded,
    Icons.laptop_mac_rounded,
    Icons.card_giftcard_rounded,
    Icons.brush_rounded,
    Icons.camera_alt_rounded,
    Icons.chair_rounded,
    Icons.celebration_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('เลือกไอคอนหมวดหมู่', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: iconsList.length,
          itemBuilder: (context, index) {
            final icon = iconsList[index];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.of(context).pop(icon),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(isDark ? 0.25 : 0.35),
                  ),
                ),
                child: Icon(icon, color: AppColors.primary, size: 26),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}
