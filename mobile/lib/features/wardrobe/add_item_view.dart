import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_geometry.dart';
import '../../core/theme/app_typography.dart';
import '../../core/database/app_database.dart';
import '../../shared/components/app_button.dart';
import '../../shared/components/app_text_field.dart';
import '../../shared/components/app_card.dart';
import 'wardrobe_bloc.dart';

class AddItemView extends StatefulWidget {
  const AddItemView({super.key});

  @override
  State<AddItemView> createState() => _AddItemViewState();
}

class _AddItemViewState extends State<AddItemView> {
  final _nameController = TextEditingController(text: "White Linen Button-Down");
  final _brandController = TextEditingController(text: "Uniqlo");
  final _priceController = TextEditingController(text: "49.90");
  String _selectedCategory = "Tops";
  String _selectedSubcategory = "Shirts";
  String _selectedFormality = "Smart Casual";
  String _selectedColor = "White";
  bool _isAiDetecting = false;
  double _aiConfidence = 0.92;

  void _simulateAiScan() {
    setState(() => _isAiDetecting = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isAiDetecting = false;
          _selectedCategory = "Tops";
          _selectedSubcategory = "Shirts";
          _selectedColor = "White";
          _selectedFormality = "Smart Casual";
          _aiConfidence = 0.94;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Add Item', style: AppTypography.h3),
        backgroundColor: colors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppGeometry.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                backgroundColor: colors.surfaceSoft,
                onTap: _simulateAiScan,
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 36, color: colors.primary),
                      const SizedBox(height: 8),
                      Text(
                        _isAiDetecting ? "OP AI Analyzing garment..." : "+ Add Photo / Scan Garment",
                        style: AppTypography.label.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text("Tap to simulate camera detection", style: AppTypography.caption.copyWith(color: colors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppGeometry.gapNormal),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                  border: Border.all(color: colors.lavender.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AI Detected: Tops ? Shirt ? White (${(_aiConfidence * 100).toInt()}% confidence)",
                        style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppGeometry.gapLarge),
              AppTextField(label: 'Item Name', controller: _nameController),
              const SizedBox(height: AppGeometry.gapNormal),
              AppTextField(label: 'Brand', controller: _brandController),
              const SizedBox(height: AppGeometry.gapNormal),
              AppTextField(label: 'Purchase Price (\$)', controller: _priceController, keyboardType: TextInputType.number),
              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Save to Wardrobe',
                onPressed: () {
                  final newItem = WardrobeItemModel(
                    id: "item_${const Uuid().v4().substring(0, 8)}",
                    category: _selectedCategory,
                    subcategory: _selectedSubcategory,
                    name: _nameController.text,
                    colors: [_selectedColor],
                    formality: _selectedFormality,
                    brand: _brandController.text,
                    purchasePrice: double.tryParse(_priceController.text) ?? 0.0,
                    wearCount: 0,
                  );
                  context.read<WardrobeBloc>().add(AddWardrobeItemSubmitted(newItem));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
