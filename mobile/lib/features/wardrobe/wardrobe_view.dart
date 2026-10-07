import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/filter_chip.dart';
import '../../shared/components/wardrobe_item_card.dart';
import '../../shared/components/state_banners.dart';
import 'wardrobe_bloc.dart';
import 'add_item_view.dart';
import 'item_detail_view.dart';

class WardrobeView extends StatefulWidget {
  const WardrobeView({super.key});

  @override
  State<WardrobeView> createState() => _WardrobeViewState();
}

class _WardrobeViewState extends State<WardrobeView> {
  final List<String> categories = const [
    'All', 'Tops', 'Bottoms', 'Outerwear', 'Footwear', 'Accessories', 'Traditional', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Load fresh items
    context.read<WardrobeBloc>().add(const LoadWardrobeRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<WardrobeBloc, WardrobeState>(
          builder: (context, state) {
            if (state is WardrobeLoading && (state is! WardrobeLoaded)) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WardrobeLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Digital Wardrobe', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                            Text(
                              '${state.allItems.length} pieces in closet',
                              style: AppTypography.caption.copyWith(color: colors.textSecondary),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: colors.primary, size: 34),
                          tooltip: 'Add Garment',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddItemView()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Search & Favorites Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchField(
                            hintText: 'Search by color, type, pattern or brand...',
                            onChanged: (q) => context.read<WardrobeBloc>().add(SearchQueryChanged(q)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            state.showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                            color: state.showFavoritesOnly ? Colors.redAccent : colors.textSecondary,
                          ),
                          tooltip: 'Favorites only',
                          onPressed: () => context.read<WardrobeBloc>().add(FavoriteFilterToggled()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapSmall),

                  // Category Filter Chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = state.selectedCategory.toLowerCase() == cat.toLowerCase();
                        return Center(
                          child: SemanticFilterChip(
                            label: cat,
                            isSelected: isSelected,
                            onSelected: (_) => context.read<WardrobeBloc>().add(CategoryFilterChanged(cat)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapSmall),

                  // Items Grid
                  Expanded(
                    child: state.filteredItems.isEmpty
                        ? EmptyState(
                            title: state.allItems.isEmpty ? "Your Wardrobe is Empty" : "No Matching Garments",
                            message: state.allItems.isEmpty
                                ? "Scan or add your clothing pieces using computer vision to build your digital closet."
                                : "Try adjusting your filters or search keywords.",
                            buttonLabel: "+ Scan First Item",
                            onAction: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddItemView()),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              context.read<WardrobeBloc>().add(const LoadWardrobeRequested(forceRefresh: true));
                            },
                            child: GridView.builder(
                              padding: const EdgeInsets.all(AppGeometry.screenPadding),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.68,
                                crossAxisSpacing: AppGeometry.gapNormal,
                                mainAxisSpacing: AppGeometry.gapNormal,
                              ),
                              itemCount: state.filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = state.filteredItems[index];
                                return WardrobeItemCard(
                                  item: item,
                                  onFavoriteToggle: () {
                                    context.read<WardrobeBloc>().add(ToggleItemFavoriteRequested(item.id));
                                  },
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ItemDetailView(item: item),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            }

            if (state is WardrobeError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colors.error),
                      const SizedBox(height: 12),
                      const Text("Failed to load wardrobe", style: AppTypography.h3),
                      const SizedBox(height: 6),
                      Text(state.message, textAlign: TextAlign.center, style: AppTypography.caption),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<WardrobeBloc>().add(const LoadWardrobeRequested(forceRefresh: true)),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
