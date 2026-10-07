import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_card.dart';
import 'wardrobe_bloc.dart';

class ItemDetailView extends StatefulWidget {
  final WardrobeItemModel item;

  const ItemDetailView({super.key, required this.item});

  @override
  State<ItemDetailView> createState() => _ItemDetailViewState();
}

class _ItemDetailViewState extends State<ItemDetailView> {
  late WardrobeItemModel _item;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Are you sure you want to remove "${_item.name}" from your wardrobe?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<WardrobeBloc>().add(DeleteItemRequested(_item.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed "${_item.name}" from wardrobe')),
                );
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final costPerWear = _item.wearCount > 0
        ? (_item.purchasePrice / _item.wearCount).toStringAsFixed(2)
        : _item.purchasePrice.toStringAsFixed(2);

    final primaryColorDisplay = _item.primaryColor ?? (_item.colors.isNotEmpty ? _item.colors.first : 'Neutral');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(_item.name, style: AppTypography.h3),
        backgroundColor: colors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _item.favorite ? Icons.favorite : Icons.favorite_border,
              color: _item.favorite ? Colors.redAccent : colors.textSecondary,
            ),
            tooltip: 'Toggle Favorite',
            onPressed: () {
              context.read<WardrobeBloc>().add(ToggleItemFavoriteRequested(_item.id));
              setState(() {
                _item = _item.copyWith(favorite: !_item.favorite);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Item',
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppGeometry.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garment Image / Header Visual
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                  child: _buildImage(colors),
                ),
              ),

              // AI Verification Banner if analyzed
              if (_item.aiAnalyzed) ...[
                const SizedBox(height: AppGeometry.gapNormal),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                    border: Border.all(color: colors.lavender.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OmniVision AI Verified Garment",
                              style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Model: ${_item.aiModel ?? 'OmniVision-Fashion-CV'} • ${(_item.aiConfidence != null ? (_item.aiConfidence! * 100).toInt() : 90)}% match confidence",
                              style: AppTypography.caption.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppGeometry.gapLarge),

              // Wear count & Cost per wear
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Wear Count", style: AppTypography.caption.copyWith(color: colors.textMuted)),
                          const SizedBox(height: 4),
                          Text("${_item.wearCount} times", style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Cost / Wear", style: AppTypography.caption.copyWith(color: colors.textMuted)),
                          const SizedBox(height: 4),
                          Text("\$$costPerWear", style: AppTypography.h2.copyWith(color: colors.success)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppGeometry.gapLarge),
              Text("Garment Specification", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapNormal),

              // Specifications Card
              AppCard(
                child: Column(
                  children: [
                    _buildSpecRow("Category", _item.category, colors),
                    const Divider(height: 16),
                    _buildSpecRow("Subcategory", _item.subcategory, colors),
                    const Divider(height: 16),
                    _buildSpecRow("Primary Color", primaryColorDisplay, colors),
                    if (_item.secondaryColors.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Accent Colors", _item.secondaryColors.join(", "), colors),
                    ],
                    const Divider(height: 16),
                    _buildSpecRow("Pattern", _item.pattern, colors),
                    const Divider(height: 16),
                    _buildSpecRow("Formality", _item.formality, colors),
                    const Divider(height: 16),
                    _buildSpecRow("Fit", _item.fit, colors),
                    if (_item.size != null) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Size", _item.size!, colors),
                    ],
                    if (_item.material != null) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Material", _item.material!, colors),
                    ],
                    if (_item.brand != null) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Brand", _item.brand!, colors),
                    ],
                    if (_item.purchasePrice > 0) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Price", "\$${_item.purchasePrice.toStringAsFixed(2)} ${_item.currency}", colors),
                    ],
                    if (_item.seasonTags.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Seasons", _item.seasonTags.join(", "), colors),
                    ],
                    if (_item.occasionTags.isNotEmpty) ...[
                      const Divider(height: 16),
                      _buildSpecRow("Occasions", _item.occasionTags.join(", "), colors),
                    ],
                  ],
                ),
              ),

              if (_item.notes != null && _item.notes!.isNotEmpty) ...[
                const SizedBox(height: AppGeometry.gapLarge),
                Text("Notes", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
                const SizedBox(height: AppGeometry.gapNormal),
                AppCard(
                  child: Text(
                    _item.notes!,
                    style: AppTypography.body.copyWith(color: colors.textSecondary),
                  ),
                ),
              ],

              const SizedBox(height: AppGeometry.gapLarge),
              Text("Wear History", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppGeometry.gapNormal),
              AppCard(
                child: Column(
                  children: [
                    _buildHistoryRow("Last logged", _item.lastWornDate != null ? _item.lastWornDate!.toIso8601String().substring(0, 10) : "Never", colors),
                    const Divider(height: 16),
                    _buildHistoryRow("Status", _item.status.toUpperCase(), colors),
                  ],
                ),
              ),

              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: '+ Mark as Worn Today',
                icon: const Icon(Icons.check, size: 18),
                onPressed: () {
                  context.read<WardrobeBloc>().add(MarkItemAsWornRequested(_item.id, "Daily wear"));
                  setState(() {
                    _item = _item.copyWith(
                      wearCount: _item.wearCount + 1,
                      lastWornDate: DateTime.now(),
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marked "${_item.name}" as worn today')),
                  );
                },
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              SecondaryButton(
                label: 'Remove Item',
                onPressed: () => _showDeleteDialog(context),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(AppSemanticColors colors) {
    final path = _item.imageUrl ?? _item.thumbnailUrl;
    if (path != null && !path.startsWith('http') && !path.startsWith('/api')) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    }

    if (path != null && (path.startsWith('http') || path.startsWith('/api'))) {
      final fullUrl = path.startsWith('http') ? path : "${ApiClient.baseUrl}$path";
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFallbackVisual(colors),
      );
    }

    return _buildFallbackVisual(colors);
  }

  Widget _buildFallbackVisual(AppSemanticColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom, size: 64, color: colors.primary),
          const SizedBox(height: 8),
          Text(_item.name, style: AppTypography.h3.copyWith(color: colors.textPrimary)),
          Text(
            '${_item.subcategory} • ${_item.formality}',
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, AppSemanticColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: colors.textMuted)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.label.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(String date, String contextStr, AppSemanticColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(date, style: AppTypography.label.copyWith(color: colors.textPrimary)),
        Text(contextStr, style: AppTypography.body.copyWith(color: colors.textSecondary)),
      ],
    );
  }
}
