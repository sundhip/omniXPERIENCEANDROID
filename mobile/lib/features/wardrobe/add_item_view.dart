import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
  final _picker = ImagePicker();
  File? _imageFile;
  bool _isAnalyzing = false;
  String? _analysisError;

  // AI Analysis Results
  bool _aiAnalyzed = false;
  double _aiConfidence = 0.0;
  String _aiModel = "OmniVision-Fashion-CV";
  String _aiSummary = "";
  String? _remoteImageUrl;
  String? _remoteThumbnailUrl;
  Map<String, dynamic>? _confidenceBreakdown;

  // Garment Form Controllers & Values
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();
  final _sizeController = TextEditingController(text: "M");

  String _selectedCategory = "Tops";
  String _selectedSubcategory = "T-Shirt";
  String _selectedFormality = "Casual";
  String _selectedPattern = "Solid";
  String _selectedPrimaryColor = "Blue";
  List<String> _secondaryColors = [];
  String _selectedFit = "Regular";
  List<String> _seasonTags = ["All-Season"];
  List<String> _occasionTags = ["Casual", "Everyday"];

  final List<String> _categories = [
    "Tops", "Bottoms", "Outerwear", "Footwear", "Accessories", "Traditional", "Other"
  ];

  final Map<String, List<String>> _subcategoriesMap = {
    "Tops": ["T-Shirt", "Shirt", "Polo", "Blouse", "Sweater", "Hoodie", "Sweatshirt", "Tank Top"],
    "Bottoms": ["Jeans", "Trousers", "Chinos", "Shorts", "Skirt", "Leggings"],
    "Outerwear": ["Blazer", "Jacket", "Coat", "Trench Coat", "Overcoat", "Bomber Jacket", "Cardigan"],
    "Footwear": ["Sneakers", "Loafers", "Boots", "Sandals", "Heels", "Formal Shoes"],
    "Accessories": ["Cap", "Sunglasses", "Belt", "Scarf", "Bag", "Watch"],
    "Traditional": ["Kurta", "Sherwani", "Sari", "Nehru Jacket"],
    "Other": ["Clothing Item"]
  };

  final List<String> _patterns = [
    "Solid", "Striped", "Checkered", "Floral", "Printed", "Textured"
  ];

  final List<String> _formalities = [
    "Casual", "Smart Casual", "Formal", "Sport", "Business Casual"
  ];

  final List<String> _colors = [
    "Black", "White", "Grey", "Charcoal", "Navy", "Blue", "Light Blue", "Cyan",
    "Green", "Olive", "Yellow", "Mustard", "Orange", "Red", "Maroon", "Pink",
    "Purple", "Lavender", "Brown", "Beige", "Cream"
  ];

  final List<String> _fits = ["Regular", "Slim", "Relaxed", "Oversized"];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _analysisError = null;
        });
        await _runRealAiAnalysis(picked.path);
      }
    } catch (e) {
      setState(() {
        _analysisError = "Error selecting image: $e";
      });
    }
  }

  Future<void> _runRealAiAnalysis(String path) async {
    setState(() {
      _isAnalyzing = true;
      _analysisError = null;
    });

    try {
      final repository = context.read<WardrobeBloc>().repository;
      final result = await repository.analyzeClothingImage(
        path,
        userSize: _sizeController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _aiAnalyzed = true;
          _aiConfidence = (result['confidence'] as num?)?.toDouble() ?? 0.85;
          _aiModel = result['ai_model']?.toString() ?? "OmniVision-Fashion-CV";
          _aiSummary = result['ai_summary']?.toString() ?? "";
          _remoteImageUrl = result['image_url']?.toString();
          _remoteThumbnailUrl = result['thumbnail_url']?.toString();
          _confidenceBreakdown = result['confidence_breakdown'] as Map<String, dynamic>?;

          // Populate detected fields
          _nameController.text = result['name']?.toString() ?? _nameController.text;
          
          final detectedCat = result['category']?.toString() ?? _selectedCategory;
          if (_categories.contains(detectedCat)) {
            _selectedCategory = detectedCat;
          }

          final subcats = _subcategoriesMap[_selectedCategory] ?? [];
          final detectedSubcat = result['subcategory']?.toString() ?? _selectedSubcategory;
          if (subcats.contains(detectedSubcat)) {
            _selectedSubcategory = detectedSubcat;
          } else if (subcats.isNotEmpty) {
            _selectedSubcategory = subcats.first;
          }

          final detectedColor = result['primary_color']?.toString() ?? _selectedPrimaryColor;
          if (_colors.contains(detectedColor)) {
            _selectedPrimaryColor = detectedColor;
          }

          if (result['secondary_colors'] is List) {
            _secondaryColors = List<String>.from(result['secondary_colors']);
          }

          final detectedPattern = result['pattern']?.toString() ?? _selectedPattern;
          if (_patterns.contains(detectedPattern)) {
            _selectedPattern = detectedPattern;
          }

          final detectedFormality = result['formality']?.toString() ?? _selectedFormality;
          if (_formalities.contains(detectedFormality)) {
            _selectedFormality = detectedFormality;
          }

          final detectedFit = result['fit']?.toString() ?? _selectedFit;
          if (_fits.contains(detectedFit)) {
            _selectedFit = detectedFit;
          }

          if (result['season_tags'] is List) {
            _seasonTags = List<String>.from(result['season_tags']);
          }
          if (result['occasion_tags'] is List) {
            _occasionTags = List<String>.from(result['occasion_tags']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisError = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  void _saveItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for this clothing item.')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final id = "clt_${const Uuid().v4().substring(0, 8)}";

    final allColors = [_selectedPrimaryColor];
    for (final sec in _secondaryColors) {
      if (!allColors.contains(sec)) allColors.add(sec);
    }

    final newItem = WardrobeItemModel(
      id: id,
      category: _selectedCategory,
      subcategory: _selectedSubcategory,
      name: name,
      primaryColor: _selectedPrimaryColor,
      secondaryColors: _secondaryColors,
      colors: allColors,
      pattern: _selectedPattern,
      formality: _selectedFormality,
      fit: _selectedFit,
      size: _sizeController.text.trim().isNotEmpty ? _sizeController.text.trim() : null,
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
      purchasePrice: price,
      currency: "USD",
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      imageUrl: _remoteImageUrl ?? _imageFile?.path,
      thumbnailUrl: _remoteThumbnailUrl ?? _remoteImageUrl ?? _imageFile?.path,
      seasonTags: _seasonTags,
      seasons: _seasonTags,
      occasionTags: _occasionTags,
      aiAnalyzed: _aiAnalyzed,
      aiConfidence: _aiAnalyzed ? _aiConfidence : null,
      aiModel: _aiAnalyzed ? _aiModel : null,
      userConfirmed: true,
      wearCount: 0,
      favorite: false,
    );

    context.read<WardrobeBloc>().add(AddWardrobeItemSubmitted(newItem));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${newItem.name}" to your Digital Wardrobe'),
        backgroundColor: Colors.green.shade700,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subcategories = _subcategoriesMap[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Add Garment', style: AppTypography.h3),
        backgroundColor: colors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppGeometry.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker Card
              if (_imageFile == null)
                AppCard(
                  backgroundColor: colors.surfaceSoft,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 44, color: colors.primary),
                        const SizedBox(height: 12),
                        Text(
                          "Capture or Upload Clothing Photo",
                          style: AppTypography.label.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Real computer vision scans color, fabric pattern & category",
                          textAlign: TextAlign.center,
                          style: AppTypography.caption.copyWith(color: colors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _pickImage(ImageSource.camera),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text('Gallery'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.primary,
                              ),
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                          child: SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          ),
                        ),
                        if (_isAnalyzing)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(AppGeometry.radiusCard),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white),
                                  const SizedBox(height: 12),
                                  Text(
                                    "OmniVision AI Analyzing...",
                                    style: AppTypography.label.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Extracting colors, edge patterns & silhouette",
                                    style: AppTypography.caption.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                              tooltip: "Retake Photo",
                              onPressed: () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

              // Error Banner if analysis failed
              if (_analysisError != null) ...[
                const SizedBox(height: AppGeometry.gapNormal),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                    border: Border.all(color: colors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.error, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _analysisError!,
                          style: AppTypography.caption.copyWith(color: colors.error, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // AI Analysis Success Card
              if (_aiAnalyzed) ...[
                const SizedBox(height: AppGeometry.gapNormal),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppGeometry.radiusSmall),
                    border: Border.all(color: colors.lavender.withOpacity(0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "OmniVision AI Classification",
                                style: AppTypography.label.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${(_aiConfidence * 100).toInt()}% Match",
                              style: AppTypography.caption.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (_aiSummary.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _aiSummary,
                          style: AppTypography.caption.copyWith(color: colors.textSecondary),
                        ),
                      ],
                      if (_secondaryColors.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Secondary accents: ${_secondaryColors.join(', ')}",
                          style: AppTypography.caption.copyWith(color: colors.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (_confidenceBreakdown != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            Text(
                              "Cat: ${((_confidenceBreakdown!['category'] as num?)?.toDouble() ?? 0.85 * 100).toInt()}%",
                              style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary),
                            ),
                            Text("•", style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textMuted)),
                            Text(
                              "Color: ${((_confidenceBreakdown!['color'] as num?)?.toDouble() ?? 0.85 * 100).toInt()}%",
                              style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary),
                            ),
                            Text("•", style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textMuted)),
                            Text(
                              "Pattern: ${((_confidenceBreakdown!['pattern'] as num?)?.toDouble() ?? 0.85 * 100).toInt()}%",
                              style: AppTypography.caption.copyWith(fontSize: 10, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppGeometry.gapLarge),
              Text("Garment Details", style: AppTypography.h3.copyWith(color: colors.textPrimary)),
              const SizedBox(height: 4),
              Text("Review and correct detected attributes before saving.", style: AppTypography.caption.copyWith(color: colors.textMuted)),

              const SizedBox(height: AppGeometry.gapNormal),
              AppTextField(
                label: 'Item Name *',
                controller: _nameController,
                hintText: 'e.g. Navy Oxford Shirt',
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            final subcats = _subcategoriesMap[val] ?? [];
                            if (subcats.isNotEmpty) {
                              _selectedSubcategory = subcats.first;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: subcategories.contains(_selectedSubcategory) ? _selectedSubcategory : (subcategories.isNotEmpty ? subcategories.first : null),
                      decoration: InputDecoration(
                        labelText: 'Subcategory',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: subcategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSubcategory = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _colors.contains(_selectedPrimaryColor) ? _selectedPrimaryColor : _colors.first,
                      decoration: InputDecoration(
                        labelText: 'Primary Color',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _colors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPrimaryColor = val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _patterns.contains(_selectedPattern) ? _selectedPattern : _patterns.first,
                      decoration: InputDecoration(
                        labelText: 'Pattern',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _patterns.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedPattern = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _formalities.contains(_selectedFormality) ? _selectedFormality : _formalities.first,
                      decoration: InputDecoration(
                        labelText: 'Formality',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _formalities.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFormality = val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _fits.contains(_selectedFit) ? _selectedFit : _fits.first,
                      decoration: InputDecoration(
                        labelText: 'Fit',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppGeometry.radiusSmall)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      items: _fits.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFit = val);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Size',
                      controller: _sizeController,
                      hintText: 'S, M, 32/30, 10.5',
                    ),
                  ),
                  const SizedBox(width: AppGeometry.gapNormal),
                  Expanded(
                    child: AppTextField(
                      label: 'Brand',
                      controller: _brandController,
                      hintText: 'Uniqlo, Zara, Nike',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              AppTextField(
                label: 'Purchase Price (\$ USD)',
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hintText: '49.99',
              ),

              const SizedBox(height: AppGeometry.gapNormal),
              AppTextField(
                label: 'Notes / Care Instructions',
                controller: _notesController,
                maxLines: 2,
                hintText: 'Dry clean only, favorite date night shirt',
              ),

              const SizedBox(height: AppGeometry.gapLarge),
              AppButton(
                label: 'Save to Digital Wardrobe',
                onPressed: _saveItem,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
