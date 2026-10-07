import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import 'app_card.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final primaryColorDisplay = item.primaryColor ?? (item.colors.isNotEmpty ? item.colors.first : 'Neutral');

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Container with Real Image or Fallback Icon
          Stack(
            children: [
              Container(
                height: 125,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppGeometry.radiusCard - 1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppGeometry.radiusCard - 1),
                  ),
                  child: _buildItemImage(colors),
                ),
              ),

              // AI Verification Badge
              if (item.aiAnalyzed)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          item.aiConfidence != null ? "${(item.aiConfidence! * 100).toInt()}%" : "AI",
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

              // Favorite Heart Icon Button
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.favorite ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: item.favorite ? Colors.redAccent : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
                  '${item.subcategory} • $primaryColorDisplay',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppGeometry.gapSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.pattern} • ${item.formality}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.status == 'in_laundry')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Laundry',
                          style: AppTypography.caption.copyWith(color: colors.warning, fontSize: 9),
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

  Widget _buildItemImage(AppSemanticColors colors) {
    // 1. Check local file path
    final localPath = item.thumbnailUrl ?? item.imageUrl;
    if (localPath != null && !localPath.startsWith('http') && !localPath.startsWith('/api')) {
      final file = File(localPath);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    }

    // 2. Check remote endpoint
    if (localPath != null && (localPath.startsWith('/api') || localPath.startsWith('http'))) {
      final fullUrl = localPath.startsWith('http') ? localPath : "${ApiClient.baseUrl}$localPath";
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(colors),
      );
    }

    // 3. Fallback placeholder
    return _buildFallbackIcon(colors);
  }

  Widget _buildFallbackIcon(AppSemanticColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(item.category),
            size: 36,
            color: colors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            item.primaryColor ?? (item.colors.isNotEmpty ? item.colors.first : 'Neutral'),
            style: AppTypography.caption.copyWith(color: colors.textMuted),
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
      case 'traditional':
        return Icons.style;
      default:
        return Icons.shopping_bag;
    }
  }
}
