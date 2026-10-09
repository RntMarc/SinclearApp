import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/osm_config.dart';
import '../../../core/di/app_scope.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_bottom_sheet.dart';
import '../../../design/widgets/composite/design_list_tile.dart';
import '../../../design/widgets/composite/design_map_marker.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_avatar.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_chip.dart';
import '../../../design/widgets/primitives/design_text_field.dart';
import '../models/travel_models.dart';
import '../models/travel_planning_models.dart';
import 'accommodation_picker_sheet.dart';
import 'travel_timing_fields.dart';

/// Entwürfe der Planungs-Formulare (Rückgabewerte der Sheets).

class PlanningDateOptionDraft {
  final String? label;
  final bool allDay;
  final String timezone;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? startAt;
  final DateTime? endAt;

  const PlanningDateOptionDraft({
    required this.label,
    required this.allDay,
    required this.timezone,
    required this.startDate,
    required this.endDate,
    required this.startAt,
    required this.endAt,
  });
}

class PlanningTransportDraft {
  final String direction;
  final String? mode;
  final bool offersRide;
  final int? availableSeats;
  final String? notes;

  const PlanningTransportDraft({
    required this.direction,
    required this.mode,
    required this.offersRide,
    required this.availableSeats,
    required this.notes,
  });
}

class PlanningAccommodationDraft {
  /// ID einer vorhandenen Katalog-Unterkunft (Wiederverwendung); `null`, wenn
  /// eine neue Unterkunft angelegt wird.
  final String? accommodationId;
  final String? name;
  final String? description;
  final String? address;
  final double? pricePerPersonPerNight;
  final String? currency;

  const PlanningAccommodationDraft({
    this.accommodationId,
    required this.name,
    required this.description,
    required this.address,
    required this.pricePerPersonPerNight,
    required this.currency,
  });
}

class PlanningEventDraft {
  final String name;
  final String? description;
  final bool allDay;
  final String timezone;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? address;
  final double? latitude;
  final double? longitude;

  const PlanningEventDraft({
    required this.name,
    required this.description,
    required this.allDay,
    required this.timezone,
    required this.startDate,
    required this.endDate,
    required this.startAt,
    required this.endAt,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

// ──────────────────────────── Terminoption ────────────────────────────

/// Erstellt/bearbeitet eine Terminoption. Liefert den Entwurf oder `null`.
Future<PlanningDateOptionDraft?> showPlanningDateOptionSheet({
  required BuildContext context,
  PlanDateOption? initial,
  String? initialTimezone,
}) {
  return showDesignSheet<PlanningDateOptionDraft>(
    context: context,
    child: _DateOptionSheet(initial: initial, initialTimezone: initialTimezone),
  );
}

class _DateOptionSheet extends StatefulWidget {
  const _DateOptionSheet({this.initial, this.initialTimezone});

  final PlanDateOption? initial;
  final String? initialTimezone;

  @override
  State<_DateOptionSheet> createState() => _DateOptionSheetState();
}

class _DateOptionSheetState extends State<_DateOptionSheet> {
  late final TextEditingController _label;
  late TravelTimingInput _timing;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _label = TextEditingController(text: initial?.label ?? '');
    _timing = TravelTimingInput(
      allDay: initial?.allDay ?? true,
      timezone: initial?.timezone ?? widget.initialTimezone ?? 'UTC',
      startDate: initial?.startDate,
      endDate: initial?.endDate,
      startAt: initial != null && initial.startAt != null
          ? instantToWallTime(initial.startAt!, initial.timezone)
          : null,
      endAt: initial != null && initial.endAt != null
          ? instantToWallTime(initial.endAt!, initial.timezone)
          : null,
    );
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          widget.initial == null ? 'Termin vorschlagen' : 'Termin bearbeiten',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(hint: 'Bezeichnung (optional)', controller: _label),
        SizedBox(height: tokens.spaceLg),
        TravelTimingFields(
          initial: _timing,
          onChanged: (value) => _timing = value,
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: () => Navigator.pop(
            context,
            PlanningDateOptionDraft(
              label: _label.text.trim().isEmpty ? null : _label.text.trim(),
              allDay: _timing.allDay,
              timezone: _timing.timezone,
              startDate: _timing.startDate,
              endDate: _timing.endDate,
              startAt: _timing.startAt,
              endAt: _timing.endAt,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Transport ────────────────────────────

Future<PlanningTransportDraft?> showPlanningTransportSheet({
  required BuildContext context,
  String initialDirection = 'outbound',
  PlanTransport? initial,
  String? initialTimezone,
}) {
  return showDesignSheet<PlanningTransportDraft>(
    context: context,
    child: _TransportSheet(
      initialDirection: initialDirection,
      initial: initial,
    ),
  );
}

class _TransportSheet extends StatefulWidget {
  const _TransportSheet({required this.initialDirection, this.initial});

  final String initialDirection;
  final PlanTransport? initial;

  @override
  State<_TransportSheet> createState() => _TransportSheetState();
}

class _TransportSheetState extends State<_TransportSheet> {
  late String _direction;
  late final TextEditingController _mode;
  late final TextEditingController _seats;
  late final TextEditingController _notes;
  late bool _offersRide;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _direction = initial?.direction ?? widget.initialDirection;
    _mode = TextEditingController(text: initial?.mode ?? '');
    _seats = TextEditingController(
      text: initial?.availableSeats?.toString() ?? '',
    );
    _notes = TextEditingController(text: initial?.notes ?? '');
    _offersRide = initial?.offersRide ?? false;
  }

  @override
  void dispose() {
    _mode.dispose();
    _seats.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          'Meine Anreise',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        _label(tokens, 'Richtung'),
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            DesignChip(
              label: 'Hinfahrt',
              selected: _direction == 'outbound',
              onTap: () => setState(() => _direction = 'outbound'),
            ),
            DesignChip(
              label: 'Rückfahrt',
              selected: _direction == 'return',
              onTap: () => setState(() => _direction = 'return'),
            ),
            DesignChip(
              label: 'Beide Richtungen',
              selected: _direction == 'both',
              onTap: () => setState(() => _direction = 'both'),
            ),
          ],
        ),
        if (_direction == 'both') ...[
          SizedBox(height: tokens.spaceSm),
          DesignText(
            'Gilt für Hin- und Rückfahrt.',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
        SizedBox(height: tokens.spaceMd),
        DesignTextField(hint: 'Verkehrsmittel', controller: _mode),
        SizedBox(height: tokens.spaceMd),
        Row(
          children: [
            Expanded(
              child: DesignText(
                'Ich biete eine Mitfahrgelegenheit an',
                style: DesignTextStyle.body,
                color: tokens.textHigh,
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: Switch(
                value: _offersRide,
                activeThumbColor: tokens.primary,
                onChanged: (v) => setState(() => _offersRide = v),
              ),
            ),
          ],
        ),
        if (_offersRide) ...[
          SizedBox(height: tokens.spaceMd),
          DesignTextField(
            hint: 'Freie Plätze',
            controller: _seats,
            keyboardType: TextInputType.number,
          ),
        ],
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Notizen (optional)',
          controller: _notes,
          maxLines: 2,
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: () => Navigator.pop(
            context,
            PlanningTransportDraft(
              direction: _direction,
              mode: _mode.text.trim().isEmpty ? null : _mode.text.trim(),
              offersRide: _offersRide,
              availableSeats: _offersRide
                  ? int.tryParse(_seats.text.trim())
                  : null,
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Unterkunft ────────────────────────────

Future<PlanningAccommodationDraft?> showPlanningAccommodationSheet({
  required BuildContext context,
  PlanAccommodationOption? initial,
}) {
  return showDesignSheet<PlanningAccommodationDraft>(
    context: context,
    child: _AccommodationSheet(initial: initial),
  );
}

class _AccommodationSheet extends StatefulWidget {
  const _AccommodationSheet({this.initial});

  final PlanAccommodationOption? initial;

  @override
  State<_AccommodationSheet> createState() => _AccommodationSheetState();
}

class _AccommodationSheetState extends State<_AccommodationSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _currency = TextEditingController(text: 'EUR');

  TravelAccommodation? _selected;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _name.text = initial.name ?? '';
      _description.text = initial.description ?? '';
      _address.text = initial.address ?? '';
      _price.text = initial.pricePerPersonPerNight ?? '';
      _currency.text = (initial.currency == null || initial.currency!.isEmpty)
          ? 'EUR'
          : initial.currency!;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _price.dispose();
    _currency.dispose();
    super.dispose();
  }

  /// Öffnet ein eigenes Auswahl-Sheet mit den bereits gespeicherten
  /// Katalog-Unterkünften (aus früheren Reisen).
  Future<void> _pickExisting() async {
    final catalog = await AppScope.of(
      context,
    ).travel.listAccommodationCatalog();
    if (!mounted) return;
    final chosenId = await showAccommodationPicker(
      context,
      options: catalog,
      selectedId: _selected?.id,
      title: 'Gespeicherte Unterkünfte',
      description:
          'Unterkünfte, die bereits in früheren Reisen gespeichert wurden.',
      searchable: true,
    );
    if (chosenId == null || !mounted) return;
    final matches = catalog.where((a) => a.id == chosenId);
    if (matches.isEmpty) return;
    setState(() => _selected = matches.first);
  }

  double? _parsePrice() {
    final text = _price.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get _canSave {
    if (_selected != null) return true;
    return _name.text.trim().isNotEmpty;
  }

  void _save() {
    final currency = _currency.text.trim().isEmpty
        ? null
        : _currency.text.trim();
    if (_selected != null) {
      Navigator.pop(
        context,
        PlanningAccommodationDraft(
          accommodationId: _selected!.id,
          name: null,
          description: null,
          address: null,
          pricePerPersonPerNight: _parsePrice(),
          currency: currency,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      PlanningAccommodationDraft(
        accommodationId: widget.initial?.accommodationId,
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        pricePerPersonPerNight: _parsePrice(),
        currency: currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          _isEdit ? 'Unterkunft bearbeiten' : 'Unterkunft vorschlagen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (!_isEdit) ...[
          DesignText(
            'Vorhandene Unterkunft',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
          SizedBox(height: tokens.spaceSm),
          DesignButton(
            label: 'Gespeicherte Unterkünfte wählen',
            variant: DesignButtonVariant.outlined,
            icon: Icons.list_rounded,
            onPressed: _pickExisting,
          ),
          if (_selected != null) ...[
            SizedBox(height: tokens.spaceSm),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: tokens.primary,
                  size: 20,
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: DesignText(
                    _selected!.name,
                    style: DesignTextStyle.body,
                    color: tokens.textHigh,
                  ),
                ),
                DesignButton(
                  label: 'Ändern',
                  variant: DesignButtonVariant.text,
                  onPressed: () => setState(() => _selected = null),
                ),
              ],
            ),
          ],
          if (_selected == null) ...[
            SizedBox(height: tokens.spaceMd),
            DesignText(
              'Oder neue Unterkunft anlegen',
              style: DesignTextStyle.label,
              color: tokens.textLow,
            ),
            SizedBox(height: tokens.spaceSm),
            DesignTextField(
              hint: 'Name',
              controller: _name,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: tokens.spaceMd),
            DesignTextField(hint: 'Adresse (optional)', controller: _address),
            SizedBox(height: tokens.spaceMd),
            DesignTextField(
              hint: 'Beschreibung (optional)',
              controller: _description,
              maxLines: 2,
            ),
          ],
        ] else ...[
          DesignTextField(
            hint: 'Name',
            controller: _name,
            onChanged: (_) => setState(() {}),
          ),
          SizedBox(height: tokens.spaceMd),
          DesignTextField(hint: 'Adresse (optional)', controller: _address),
          SizedBox(height: tokens.spaceMd),
          DesignTextField(
            hint: 'Beschreibung (optional)',
            controller: _description,
            maxLines: 2,
          ),
        ],
        SizedBox(height: tokens.spaceMd),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DesignTextField(
                hint: 'Preis pro Person/Nacht',
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: DesignTextField(hint: 'Währung', controller: _currency),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: _canSave ? _save : null,
        ),
      ],
    );
  }
}

// ──────────────────────────── Eventvorschlag ────────────────────────────

Future<PlanningEventDraft?> showPlanningEventSheet({
  required BuildContext context,
  PlanEventSuggestion? initial,
  String? initialTimezone,
}) {
  return showDesignSheet<PlanningEventDraft>(
    context: context,
    child: _EventSheet(initial: initial, initialTimezone: initialTimezone),
  );
}

class _EventSheet extends StatefulWidget {
  const _EventSheet({this.initial, this.initialTimezone});

  final PlanEventSuggestion? initial;
  final String? initialTimezone;

  @override
  State<_EventSheet> createState() => _EventSheetState();
}

class _EventSheetState extends State<_EventSheet> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _mapController = MapController();
  late TravelTimingInput _timing;
  LatLng? _location;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name.text = initial?.name ?? '';
    _description.text = initial?.description ?? '';
    _address.text = initial?.address ?? '';
    if (initial?.latitude != null && initial?.longitude != null) {
      _location = LatLng(initial!.latitude!, initial.longitude!);
    }
    _timing = TravelTimingInput(
      allDay: initial?.allDay ?? false,
      timezone: initial?.timezone ?? widget.initialTimezone ?? 'UTC',
      startDate: initial?.startDate,
      endDate: initial?.endDate,
      startAt: initial != null && initial.startAt != null
          ? instantToWallTime(initial.startAt!, initial.timezone)
          : null,
      endAt: initial != null && initial.endAt != null
          ? instantToWallTime(initial.endAt!, initial.timezone)
          : null,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      PlanningEventDraft(
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        allDay: _timing.allDay,
        timezone: _timing.timezone,
        startDate: _timing.startDate,
        endDate: _timing.endDate,
        startAt: _timing.startAt,
        endAt: _timing.endAt,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        latitude: _location?.latitude,
        longitude: _location?.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          widget.initial == null ? 'Event vorschlagen' : 'Event bearbeiten',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Name',
          controller: _name,
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(
          hint: 'Beschreibung (optional)',
          controller: _description,
          maxLines: 2,
        ),
        SizedBox(height: tokens.spaceMd),
        _buildMap(tokens),
        SizedBox(height: tokens.spaceMd),
        DesignTextField(hint: 'Ort (optional)', controller: _address),
        SizedBox(height: tokens.spaceLg),
        TravelTimingFields(
          initial: _timing,
          onChanged: (value) => _timing = value,
        ),
        SizedBox(height: tokens.spaceXl),
        DesignButton(
          label: 'Speichern',
          fullWidth: true,
          onPressed: _name.text.trim().isEmpty ? null : _save,
        ),
      ],
    );
  }

  Widget _buildMap(DesignTokens tokens) {
    final location = _location;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesignText(
          'Ort auf der Karte',
          style: DesignTextStyle.label,
          color: tokens.textLow,
        ),
        SizedBox(height: tokens.spaceSm),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: location ?? const LatLng(51.1657, 10.4515),
                initialZoom: location != null ? 15 : 6,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: (tapPosition, latLng) {
                  setState(() => _location = latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: OsmConfig.tileUrlTemplate,
                  userAgentPackageName: OsmConfig.tileUserAgent,
                  tileProvider: osmTileProvider(),
                ),
                if (location != null)
                  MarkerLayer(
                    markers: [
                      designMapMarker(
                        point: location,
                        icon: Icons.location_on_rounded,
                        color: tokens.danger,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (location != null) ...[
          SizedBox(height: tokens.spaceSm),
          DesignText(
            '${location.latitude.toStringAsFixed(5)}, '
            '${location.longitude.toStringAsFixed(5)}',
            style: DesignTextStyle.label,
            color: tokens.textLow,
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────── Mitglied einladen ────────────────────────────

/// Zeigt die Nutzerauswahl zum Einladen in die Planung und liefert die
/// gewählte `userId` oder `null`.
Future<String?> showPlanningInviteSheet({
  required BuildContext context,
  required Set<String> existingUserIds,
}) async {
  final users = await AppScope.of(context).user.listAll();
  if (!context.mounted) return null;
  final candidates = users
      .where((u) => !existingUserIds.contains(u.id))
      .map((u) => (id: u.id, displayName: u.displayName, image: u.image))
      .toList();
  return showDesignSheet<String>(
    context: context,
    child: Builder(
      builder: (sheetContext) => PlanningInvitePicker(
        candidates: candidates,
        onPick: (id) => Navigator.pop(sheetContext, id),
      ),
    ),
  );
}

/// Auswahlliste zum Einladen von Nutzern in eine Planung.
///
/// Modell-frei über die Anzeigedaten (`id`, `displayName`, `image`); der
/// Aufrufer entscheidet über [onPick], was mit der gewählten `userId` passiert.
class PlanningInvitePicker extends StatelessWidget {
  const PlanningInvitePicker({
    required this.candidates,
    required this.onPick,
    super.key,
  });

  final List<({String id, String displayName, String? image})> candidates;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesignText(
          'Zur Planung einladen',
          style: DesignTextStyle.subtitle,
          color: tokens.textHigh,
        ),
        SizedBox(height: tokens.spaceMd),
        if (candidates.isEmpty)
          DesignText(
            'Keine weiteren Nutzer verfügbar.',
            style: DesignTextStyle.body,
            color: tokens.textLow,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final user in candidates)
                DesignListTile(
                  leading: DesignAvatar(
                    imageUrl: user.image,
                    name: user.displayName,
                    size: 32,
                  ),
                  title: user.displayName,
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: tokens.textLow,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceSm,
                    vertical: tokens.spaceSm,
                  ),
                  onTap: () => onPick(user.id),
                ),
            ],
          ),
      ],
    );
  }
}

Widget _label(DesignTokens tokens, String text) {
  return DesignText(text, style: DesignTextStyle.label, color: tokens.textLow);
}
