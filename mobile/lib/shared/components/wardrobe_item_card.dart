import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/database/app_database.dart';
import 'app_card.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItemModel item;
  final VoidCallback? onTap;

  const WardrobeItemCard({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Container / Image Placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceSoft,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppGeometry.radiusCard - 1),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(item.category),
                    size: 36,
                    color: colors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.colors.isNotEmpty ? item.colors.first : 'Neutral',
                    style: AppTypography.caption.copyWith(color: colors.textMuted),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppGeometry.gapNormal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subcategory} ? ${item.formality}',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppGeometry.gapSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Worn ${item.wearCount} times',
                      style: AppTypography.caption.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.status == 'in_laundry')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Laundry',
                          style: AppTypography.caption.copyWith(color: colors.warning, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'tops':
        return Icons.checkroom;
      case 'bottoms':
        return Icons.dry_cleaning;
      case 'footwear':
      case 'shoes':
        return Icons.roller_skating;
      case 'outerwear':
        return Icons.layers;
      case 'accessories':
        return Icons.watch;
      default:
        return Icons.shopping_bag;
    }
  }
}
