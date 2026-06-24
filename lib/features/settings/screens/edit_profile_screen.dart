import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/network/api_client.dart';
import '../../user/models/user_models.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _displayNameController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _hasLoaded = false;
  String? _birthday;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await AppScope.of(context).user.getMeBase();
      if (!mounted) return;
      setState(() {
        _displayNameController.text = user.displayName;
        _birthday = user.birthday;
        _loading = false;
      });
    } catch (e, st) {
      developer.log('Failed to load profile', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Profil konnte nicht geladen werden.';
      });
    }
  }

  Future<void> _save() async {
    final displayName = _displayNameController.text.trim();
    if (displayName.isEmpty) {
      setState(() => _error = 'Der Anzeigename darf nicht leer sein.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await AppScope.of(context).user.updateProfile(ProfileUpdateRequest(
        displayName: displayName,
        birthday: _birthday,
      ));
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil gespeichert')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message ?? 'Fehler beim Speichern.');
    } catch (e, st) {
      developer.log('Failed to save profile', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = 'Netzwerkfehler. Bitte prüfe deine Verbindung.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthday != null ? DateTime.tryParse(_birthday!) : null;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Geburtstag auswählen',
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _birthday = formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil bearbeiten')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Anzeigename',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Geburtstag',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_rounded),
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                  child: Text(
                    _birthday != null
                        ? _birthday!
                        : 'Nicht angegeben',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _birthday != null ? null : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (_birthday != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _birthday = null),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Geburtstag entfernen'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Wird gespeichert…' : 'Speichern'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
