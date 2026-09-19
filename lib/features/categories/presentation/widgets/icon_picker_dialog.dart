import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class IconPickerDialog extends StatelessWidget {
  const IconPickerDialog({super.key});

  static const List<IconData> iconsList = [
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.cake,
    Icons.directions_car,
    Icons.directions_bus,
    Icons.train,
    Icons.local_gas_station,
    Icons.flight,
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.storefront,
    Icons.receipt_long,
    Icons.bolt,
    Icons.water_drop,
    Icons.wifi,
    Icons.phone_android,
    Icons.home,
    Icons.apartment,
    Icons.movie,
    Icons.sports_esports,
    Icons.music_note,
    Icons.fitness_center,
    Icons.local_hospital,
    Icons.medication,
    Icons.pets,
    Icons.school,
    Icons.savings,
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.work,
    Icons.laptop,
    Icons.card_giftcard,
    Icons.child_care,
    Icons.brush,
    Icons.camera_alt,
    Icons.chair,
    Icons.clean_hands,
    Icons.handyman,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เลือกไอคอนหมวดหมู่'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
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
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(icon),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
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
