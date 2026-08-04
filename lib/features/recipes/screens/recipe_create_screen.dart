import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/image/image_provider_helper.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_picker_field.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/recipes_models.dart';
import '../widgets/recipe_detail_widgets.dart' show formatAmount;

/// Formular zum Erstellen und Bearbeiten von Rezepten.
///
/// Ohne [recipeId] wird ein neues Rezept angelegt; mit [recipeId] wird das
/// bestehende Rezept geladen, vorbelegt und per PATCH aktualisiert.
class RecipeCreateScreen extends StatefulWidget {
  final String? recipeId;

  const RecipeCreateScreen({super.key, this.recipeId});

  bool get isEdit => recipeId != null;

  @override
  State<RecipeCreateScreen> createState() => _RecipeCreateScreenState();
}

class _RecipeCreateScreenState extends State<RecipeCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _dietaryTagsController = TextEditingController();
  final List<_IngredientEntry> _ingredients = [];
  final List<_StepEntry> _steps = [];
  String? _category;
  Uint8List? _imageBytes;

  /// Bestehendes Rezeptbild (Edit-Modus); unverändert, bis der Nutzer ein
  /// neues Bild wählt oder das Bild entfernt.
  String? _serverImage;
  bool _removeImage = false;
  bool _loading = false;
  String? _loadError;
  bool _hasLoaded = false;
  bool _submitting = false;
  String? _error;
  bool _isDraft = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _dietaryTagsController.dispose();
    for (final entry in _ingredients) {
      entry.dispose();
    }
    for (final entry in _steps) {
      entry.dispose();
    }
    super.dispose();
  }

  List<DesignPickerItem> get _categoryItems => [
    for (final entry in recipeCategories.entries)
      DesignPickerItem(
        value: entry.key,
        label: entry.value,
        icon: recipeCategoryIcons[entry.key],
      ),
  ];

  List<DesignPickerItem> get _unitItems => [
    for (final entry in recipeUnits.entries)
      DesignPickerItem(value: entry.key, label: entry.value),
  ];

  List<DesignPickerItem> get _stepCategoryItems => [
    for (final entry in stepCategories.entries)
      DesignPickerItem(value: entry.key, label: entry.value),
  ];

  void _addIngredient() => setState(() => _ingredients.add(_IngredientEntry()));

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  void _addStep() => setState(() => _steps.add(_StepEntry()));

  void _removeStep(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
    });
  }

  Future<void> _showImagePicker() async {
    final source = await showDesignSheet<ImageSource>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DesignText('Bild hinzufügen', style: DesignTextStyle.title),
          SizedBox(height: DesignTheme.of(context).spaceMd),
          _sheetOption(
            Icons.camera_alt_rounded,
            'Foto aufnehmen',
            () => Navigator.pop(context, ImageSource.camera),
          ),
          _sheetOption(
            Icons.photo_library_rounded,
            'Aus Gallery wählen',
            () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (_currentImage != null)
            _sheetOption(Icons.delete_rounded, 'Bild entfernen', () {
              Navigator.pop(context);
              setState(() {
                _imageBytes = null;
                _removeImage = true;
              });
            }, danger: true),
        ],
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final rawBytes = await picked.readAsBytes();
    if (!mounted) return;
    final compressed = compressImage(rawBytes);
    if (compressed == null) {
      _setError('Bild konnte nicht verarbeitet werden.');
      return;
    }
    setState(() => _imageBytes = compressed);
  }

  Widget _sheetOption(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final tokens = DesignTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: danger ? tokens.danger : null),
            SizedBox(width: tokens.spaceMd),
            DesignText(label, color: danger ? tokens.danger : tokens.textHigh),
          ],
        ),
      ),
    );
  }

  void _setError(String message) => setState(() => _error = message);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded && widget.isEdit) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final recipe = await AppScope.of(context).recipes.get(widget.recipeId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = recipe.title;
        _descriptionController.text = recipe.description ?? '';
        _category = recipe.category;
        _servingsController.text = recipe.servings.toString();
        _dietaryTagsController.text = recipe.dietaryTags ?? '';
        _serverImage = recipe.image;
        _isDraft = recipe.isDraft;
        for (final ingredient in recipe.ingredients) {
          final entry = _IngredientEntry();
          entry.amountController.text = formatAmount(ingredient.amount);
          entry.nameController.text = ingredient.name;
          entry.unit = ingredient.unit;
          _ingredients.add(entry);
        }
        for (final step in recipe.steps) {
          final entry = _StepEntry();
          entry.titleController.text = step.title ?? '';
          entry.descriptionController.text = step.description;
          entry.category = step.category;
          _steps.add(entry);
        }
        _loading = false;
      });
    } catch (e, st) {
      developer.log(
        'Failed to load recipe for editing',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Rezept konnte nicht geladen werden.';
      });
    }
  }

  ImageProvider? get _currentImage {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    if (_serverImage != null && !_removeImage) {
      return resolveImageProvider(_serverImage);
    }
    return null;
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return 'Bitte gib einen Titel ein.';
    }
    if (_category == null) {
      return 'Bitte wähle eine Kategorie.';
    }
    final servings = int.tryParse(_servingsController.text.trim());
    // API-Limit laut Doku: ganzzahlig 1–127, sonst invalid_servings (400).
    if (servings == null || servings < 1 || servings > 127) {
      return 'Bitte gib eine Portionsanzahl zwischen 1 und 127 ein.';
    }
    for (final entry in _ingredients) {
      final name = entry.nameController.text.trim();
      final amount = parseAmount(entry.amountController.text);
      final filled = name.isNotEmpty || amount != null || entry.unit != null;
      if (!filled) continue;
      if (name.isEmpty || amount == null || entry.unit == null) {
        return 'Bitte fülle jede Zutat vollständig aus.';
      }
    }
    return null;
  }

  Future<void> _submit({required bool publish}) async {
    final error = _validate();
    if (error != null) {
      _setError(error);
      return;
    }

    final ingredients = <RecipeIngredientCreateRequest>[];
    for (final entry in _ingredients) {
      final amount = parseAmount(entry.amountController.text);
      final name = entry.nameController.text.trim();
      if (amount == null || name.isEmpty || entry.unit == null) continue;
      ingredients.add(
        RecipeIngredientCreateRequest(
          amount: amount,
          unit: entry.unit!.toLowerCase(),
          name: name,
          order: ingredients.length,
        ),
      );
    }

    final steps = <RecipeStepCreateRequest>[];
    for (final entry in _steps) {
      final description = entry.descriptionController.text.trim();
      if (description.isEmpty) continue;
      final title = entry.titleController.text.trim();
      steps.add(
        RecipeStepCreateRequest(
          category: entry.category,
          title: title.isEmpty ? null : title,
          description: description,
          order: steps.length,
        ),
      );
    }

    setState(() {
      _error = null;
      _submitting = true;
    });
    try {
      final scope = AppScope.of(context);
      String? image;
      if (_imageBytes != null) image = base64Encode(_imageBytes!);

      if (widget.isEdit) {
        final request = RecipeUpdateRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _category!,
          dietaryTags: _dietaryTagsController.text.trim(),
          image: image,
          removeImage: _removeImage,
          servings: int.parse(_servingsController.text.trim()),
          ingredients: ingredients,
          steps: steps,
        );
        await scope.recipes.update(widget.recipeId!, request);
        if (publish) {
          await scope.recipes.publish(widget.recipeId!);
        }
        if (!mounted) return;
        context.go('/rezepte/${widget.recipeId}');
      } else {
        final request = RecipeCreateRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _category!,
          dietaryTags: _dietaryTagsController.text.trim().isEmpty
              ? null
              : _dietaryTagsController.text.trim(),
          image: image,
          servings: int.parse(_servingsController.text.trim()),
          isDraft: !publish,
          ingredients: ingredients,
          steps: steps,
        );
        final recipe = await scope.recipes.create(request);
        if (!mounted) return;
        context.go('/rezepte/${recipe.id}');
      }
    } catch (e, st) {
      developer.log('Failed to save recipe', error: e, stackTrace: st);
      if (!mounted) return;
      _setError('Rezept konnte nicht gespeichert werden.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Column(
        children: [
          DesignSubpageHeader(
            leading: DesignIconButton(
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            title: widget.isEdit ? 'Rezept bearbeiten' : 'Neues Rezept',
            actions: [
              if (!widget.isEdit) ...[
                Padding(
                  padding: EdgeInsets.only(right: tokens.spaceSm),
                  child: DesignButton(
                    variant: DesignButtonVariant.outlined,
                    label: 'Veröffentlichen',
                    loading: _submitting,
                    onPressed: _submitting || _loading
                        ? null
                        : () => _submit(publish: true),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: tokens.spaceSm),
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Erstellen',
                    loading: _submitting,
                    onPressed: _submitting || _loading
                        ? null
                        : () => _submit(publish: false),
                  ),
                ),
              ],
              if (widget.isEdit) ...[
                if (_isDraft)
                  Padding(
                    padding: EdgeInsets.only(right: tokens.spaceSm),
                    child: DesignButton(
                      variant: DesignButtonVariant.outlined,
                      label: 'Veröffentlichen',
                      loading: _submitting,
                      onPressed: _submitting || _loading
                          ? null
                          : () => _submit(publish: true),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(right: tokens.spaceSm),
                  child: DesignButton(
                    variant: DesignButtonVariant.filled,
                    label: 'Speichern',
                    loading: _submitting,
                    onPressed: _submitting || _loading
                        ? null
                        : () => _submit(publish: false),
                  ),
                ),
              ],
            ],
          ),
          if (_loading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: tokens.primary),
              ),
            )
          else if (_loadError != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: tokens.danger),
                    SizedBox(height: tokens.spaceSm),
                    DesignText(
                      _loadError!,
                      style: DesignTextStyle.body,
                      color: tokens.textHigh,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    DesignButton(
                      variant: DesignButtonVariant.filled,
                      label: 'Erneut versuchen',
                      onPressed: _load,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: EdgeInsets.all(tokens.spaceMd),
                        decoration: BoxDecoration(
                          color: tokens.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          border: Border.all(
                            color: tokens.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 20,
                              color: tokens.danger,
                            ),
                            SizedBox(width: tokens.spaceSm),
                            Expanded(
                              child: DesignText(
                                _error!,
                                style: DesignTextStyle.body,
                                color: tokens.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: tokens.spaceMd),
                    ],
                    DesignTextField(
                      controller: _titleController,
                      hint: 'Titel',
                      prefixIcon: Icons.edit_rounded,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    DesignTextField(
                      controller: _descriptionController,
                      hint: 'Beschreibung (optional)',
                      maxLines: 3,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    DesignPickerField(
                      items: _categoryItems,
                      value: _category,
                      onChanged: (v) => setState(() => _category = v),
                      hint: 'Kategorie wählen',
                      prefixIcon: Icons.category_rounded,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    Row(
                      children: [
                        Expanded(
                          child: DesignTextField(
                            controller: _servingsController,
                            hint: 'Portionen',
                            prefixIcon: Icons.restaurant_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: tokens.spaceMd),
                        Expanded(
                          flex: 2,
                          child: DesignTextField(
                            controller: _dietaryTagsController,
                            hint: 'Ernährung (optional)',
                            prefixIcon: Icons.spa_rounded,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceMd),
                    _ImageField(image: _currentImage, onPick: _showImagePicker),
                    SizedBox(height: tokens.spaceXl),
                    Row(
                      children: [
                        DesignText(
                          'Zutaten',
                          style: DesignTextStyle.subtitle,
                          color: tokens.textHigh,
                        ),
                        const Spacer(),
                        DesignIconButton(
                          icon: Icons.add_circle_outline_rounded,
                          onPressed: _addIngredient,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSm),
                    if (_ingredients.isEmpty)
                      DesignText(
                        'Noch keine Zutaten.',
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
                      )
                    else
                      ..._ingredients.asMap().entries.map(
                        (entry) => _IngredientRow(
                          key: ValueKey('ingredient-${entry.key}'),
                          entry: entry.value,
                          unitItems: _unitItems,
                          onRemove: () => _removeIngredient(entry.key),
                        ),
                      ),
                    SizedBox(height: tokens.spaceXl),
                    Row(
                      children: [
                        DesignText(
                          'Schritte',
                          style: DesignTextStyle.subtitle,
                          color: tokens.textHigh,
                        ),
                        const Spacer(),
                        DesignIconButton(
                          icon: Icons.add_circle_outline_rounded,
                          onPressed: _addStep,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSm),
                    if (_steps.isEmpty)
                      DesignText(
                        'Noch keine Schritte.',
                        style: DesignTextStyle.body,
                        color: tokens.textLow,
                      )
                    else
                      ..._steps.asMap().entries.map(
                        (entry) => _StepRow(
                          key: ValueKey('step-${entry.key}'),
                          entry: entry.value,
                          stepCategoryItems: _stepCategoryItems,
                          onRemove: () => _removeStep(entry.key),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IngredientEntry {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  String? unit;

  void dispose() {
    amountController.dispose();
    nameController.dispose();
  }
}

class _IngredientRow extends StatefulWidget {
  final _IngredientEntry entry;
  final List<DesignPickerItem> unitItems;
  final VoidCallback onRemove;

  const _IngredientRow({
    super.key,
    required this.entry,
    required this.unitItems,
    required this.onRemove,
  });

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DesignTextField(
                  controller: widget.entry.nameController,
                  hint: 'Zutat',
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignIconButton(
                icon: Icons.remove_circle_outline_rounded,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: DesignTextField(
                  controller: widget.entry.amountController,
                  hint: 'Menge',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: DesignPickerField(
                  items: widget.unitItems,
                  value: widget.entry.unit,
                  onChanged: (v) => setState(() => widget.entry.unit = v),
                  hint: 'Einheit',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepEntry {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String category = 'sonstiges';

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _StepRow extends StatefulWidget {
  final _StepEntry entry;
  final List<DesignPickerItem> stepCategoryItems;
  final VoidCallback onRemove;

  const _StepRow({
    super.key,
    required this.entry,
    required this.stepCategoryItems,
    required this.onRemove,
  });

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow> {
  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DesignPickerField(
                  items: widget.stepCategoryItems,
                  value: widget.entry.category,
                  onChanged: (v) => setState(() => widget.entry.category = v),
                  hint: 'Kategorie',
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              DesignIconButton(
                icon: Icons.remove_circle_outline_rounded,
                onPressed: widget.onRemove,
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          DesignTextField(
            controller: widget.entry.titleController,
            hint: 'Titel (optional)',
          ),
          SizedBox(height: tokens.spaceSm),
          DesignTextField(
            controller: widget.entry.descriptionController,
            hint: 'Beschreibung',
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ImageField extends StatelessWidget {
  final ImageProvider? image;
  final VoidCallback onPick;

  const _ImageField({required this.image, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    final img = image;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (img != null)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              child: Image(
                image: img,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 160,
                  color: tokens.surfaceVariant,
                  child: Icon(Icons.image_rounded, color: tokens.textLow),
                ),
              ),
            ),
          ),
        DesignButton(
          variant: img != null
              ? DesignButtonVariant.outlined
              : DesignButtonVariant.filled,
          icon: img != null
              ? Icons.image_rounded
              : Icons.add_photo_alternate_rounded,
          label: img != null ? 'Bild ändern' : 'Bild hinzufügen',
          onPressed: onPick,
        ),
      ],
    );
  }
}
