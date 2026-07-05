import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/image/image_compressor.dart';
import '../../../core/network/api_client.dart';
import '../models/recipes_models.dart';

class CreateRecipeScreen extends StatefulWidget {
  final String? recipeId;

  const CreateRecipeScreen({super.key, this.recipeId});

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  final _dietaryTagsController = TextEditingController();
  String _category = 'hauptgerichte';
  String? _imageBase64;
  bool _removeImage = false;
  List<_IngredientEntry> _ingredients = [];
  List<_StepEntry> _steps = [];
  bool _submitting = false;
  String? _error;
  bool _loadingExisting = false;
  bool _hasLoaded = false;

  bool get _isEditing => widget.recipeId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      if (_isEditing) _loadExisting();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _servingsController.dispose();
    _dietaryTagsController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final recipe = await AppScope.of(context).recipes.get(widget.recipeId!);
      if (!mounted) return;
      setState(() {
        _titleController.text = recipe.title;
        _descriptionController.text = recipe.description ?? '';
        _servingsController.text = recipe.servings.toString();
        _dietaryTagsController.text = recipe.dietaryTags ?? '';
        _category = recipe.category;
        _imageBase64 = recipe.image;
        _removeImage = false;
        _ingredients = recipe.ingredients
            .map(
              (i) => _IngredientEntry(
                amountController: TextEditingController(
                  text: i.amount % 1 == 0
                      ? i.amount.toInt().toString()
                      : i.amount.toString(),
                ),
                unitController: TextEditingController(text: i.unit),
                nameController: TextEditingController(text: i.name),
              ),
            )
            .toList();
        _steps = recipe.steps
            .map(
              (s) => _StepEntry(
                category: s.category,
                titleController: TextEditingController(text: s.title ?? ''),
                descriptionController: TextEditingController(
                  text: s.description,
                ),
              ),
            )
            .toList();
        _loadingExisting = false;
      });
    } catch (e, st) {
      developer.log('Failed to load recipe', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingExisting = false;
        _error = 'Rezept konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );
    if (picked == null) return;

    final rawBytes = await picked.readAsBytes();
    final compressed = compressImage(rawBytes);
    if (compressed == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bild konnte nicht verarbeitet werden.')),
      );
      return;
    }
    setState(() {
      _imageBase64 = base64Encode(compressed);
      _removeImage = false;
    });
  }

  void _addIngredient() {
    setState(
      () => _ingredients.add(
        _IngredientEntry(
          amountController: TextEditingController(),
          unitController: TextEditingController(),
          nameController: TextEditingController(),
        ),
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  void _addStep() {
    setState(
      () => _steps.add(
        _StepEntry(
          category: 'sonstiges',
          titleController: TextEditingController(),
          descriptionController: TextEditingController(),
        ),
      ),
    );
  }

  void _removeStep(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final ingredients = _ingredients
        .where((i) => i.nameController.text.trim().isNotEmpty)
        .map(
          (i) => RecipeIngredientCreateRequest(
            amount: double.tryParse(i.amountController.text) ?? 0,
            unit: i.unitController.text.trim(),
            name: i.nameController.text.trim(),
            order: _ingredients.indexOf(i),
          ),
        )
        .toList();

    final steps = _steps
        .where((s) => s.descriptionController.text.trim().isNotEmpty)
        .map(
          (s) => RecipeStepCreateRequest(
            category: s.category,
            title: s.titleController.text.trim().isEmpty
                ? null
                : s.titleController.text.trim(),
            description: s.descriptionController.text.trim(),
            order: _steps.indexOf(s),
          ),
        )
        .toList();

    try {
      final recipes = AppScope.of(context).recipes;
      if (_isEditing) {
        await recipes.update(
          widget.recipeId!,
          RecipeUpdateRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            category: _category,
            dietaryTags: _dietaryTagsController.text.trim().isEmpty
                ? null
                : _dietaryTagsController.text.trim(),
            image: _imageBase64,
            removeImage: _removeImage,
            servings: int.tryParse(_servingsController.text) ?? 4,
            ingredients: ingredients,
            steps: steps,
          ),
        );
      } else {
        await recipes.create(
          RecipeCreateRequest(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            category: _category,
            dietaryTags: _dietaryTagsController.text.trim().isEmpty
                ? null
                : _dietaryTagsController.text.trim(),
            image: _imageBase64,
            servings: int.tryParse(_servingsController.text) ?? 4,
            ingredients: ingredients,
            steps: steps,
          ),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Rezept aktualisiert.' : 'Rezept erstellt.',
          ),
        ),
      );
      context.go('/rezepte');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message ?? 'Fehler beim Speichern.';
      });
    } catch (e, st) {
      developer.log('Failed to save recipe', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Netzwerkfehler. Bitte versuche es erneut.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingExisting) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Rezeptname *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie *',
                border: OutlineInputBorder(),
              ),
              items: recipeCategories.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text('${recipeCategoryIcons[e.key]} ${e.value}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _servingsController,
              decoration: const InputDecoration(
                labelText: 'Portionen',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dietaryTagsController,
              decoration: const InputDecoration(
                labelText: 'Ernährungshinweise',
                hintText: 'z.B. vegetarisch, glutenfrei',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bild',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_imageBase64 != null)
              Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(_imageBase64!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _ImagePlaceholder(
                        onTap: _pickImage,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: () => setState(() {
                        _imageBase64 = null;
                        _removeImage = true;
                      }),
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ),
                ],
              )
            else
              _ImagePlaceholder(onTap: _pickImage),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Zutaten',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _addIngredient,
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Noch keine Zutaten hinzugefügt.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._ingredients.asMap().entries.map((entry) {
                final i = entry.key;
                final entry_ = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: entry_.amountController,
                          decoration: const InputDecoration(
                            labelText: 'Menge',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: entry_.unitController,
                          decoration: const InputDecoration(
                            labelText: 'Einheit',
                            hintText: 'g, ml, stk…',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: entry_.nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeIngredient(i),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Zubereitungsschritte',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_steps.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Noch keine Schritte hinzugefügt.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ..._steps.asMap().entries.map((entry) {
                final i = entry.key;
                final entry_ = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: entry_.category,
                                decoration: const InputDecoration(
                                  labelText: 'Kategorie',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: stepCategories.entries
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e.key,
                                        child: Text(e.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => entry_.category = v);
                                  }
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeStep(i),
                              icon: const Icon(
                                Icons.remove_circle_outline_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry_.titleController,
                          decoration: const InputDecoration(
                            labelText: 'Titel (optional)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: entry_.descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Beschreibung *',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Speichern' : 'Rezept erstellen'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _ImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Bild hinzufügen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientEntry {
  final TextEditingController amountController;
  final TextEditingController unitController;
  final TextEditingController nameController;

  _IngredientEntry({
    required this.amountController,
    required this.unitController,
    required this.nameController,
  });

  void dispose() {
    amountController.dispose();
    unitController.dispose();
    nameController.dispose();
  }
}

class _StepEntry {
  String category;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  _StepEntry({
    required this.category,
    required this.titleController,
    required this.descriptionController,
  });

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}
