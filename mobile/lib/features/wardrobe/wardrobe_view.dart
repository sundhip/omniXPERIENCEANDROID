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

class WardrobeView extends StatelessWidget {
  const WardrobeView({super.key});

  final List<String> categories = const ['All', 'Tops', 'Bottoms', 'Footwear', 'Outerwear'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<WardrobeBloc, WardrobeState>(
          builder: (context, state) {
            if (state is WardrobeLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is WardrobeLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Wardrobe', style: AppTypography.h2.copyWith(color: colors.textPrimary)),
                            Text('${state.allItems.length} items', style: AppTypography.caption.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: colors.primary, size: 32),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemView()));
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                    child: SearchField(
                      onChanged: (q) => context.read<WardrobeBloc>().add(SearchQueryChanged(q)),
                    ),
                  ),
                  const SizedBox(height: AppGeometry.gapSmall),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppGeometry.screenPadding),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = state.selectedCategory == cat;
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
                  Expanded(
                    child: state.filteredItems.isEmpty
                        ? EmptyState(
                            title: "No items found",
                            message: "Try clearing search filters or add a new piece to your closet.",
                            buttonLabel: "Add Item",
                            onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemView())),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(AppGeometry.screenPadding),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: AppGeometry.gapNormal,
                              mainAxisSpacing: AppGeometry.gapNormal,
                            ),
                            itemCount: state.filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = state.filteredItems[index];
                              return WardrobeItemCard(
                                item: item,
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
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
