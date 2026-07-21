import 'package:flutter/material.dart';
import '../../../core/utils/date_utils.dart';
import '../../../design/theme/design_theme.dart';
import '../../../design/widgets/composite/design_subpage_header.dart';
import '../../../design/widgets/foundation/design_surface.dart';
import '../../../design/widgets/foundation/design_text.dart';
import '../../../design/widgets/primitives/design_button.dart';
import '../../../design/widgets/primitives/design_icon_button.dart';
import '../widgets/pt_station_field.dart';
import '../models/pt_models.dart';
import 'pt_search_results_screen.dart';

class PtSearchScreen extends StatefulWidget {
  const PtSearchScreen({super.key});

  @override
  State<PtSearchScreen> createState() => _PtSearchScreenState();
}

class _PtSearchScreenState extends State<PtSearchScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  PtStation? _fromStation;
  PtStation? _toStation;
  DateTime _departure = DateTime.now();
  bool _arriveBy = false;
  bool _showAdvanced = false;
  int _maxTransfers = 5;
  int _results = 5;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _swap() {
    final tempController = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = tempController;
    final tempStation = _fromStation;
    setState(() {
      _fromStation = _toStation;
      _toStation = tempStation;
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _departure,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_departure),
    );
    if (time == null || !mounted) return;
    setState(() {
      _departure = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _search() async {
    if (_fromStation == null || _toStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Von- und Nach-Station wählen')),
      );
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PtSearchResultsScreen(
          fromStation: _fromStation!,
          toStation: _toStation!,
          departure: _departure,
          arriveBy: _arriveBy,
          maxTransfers: _maxTransfers,
          results: _results,
        ),
      ),
    );
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTheme.of(context);

    return DesignSurface(
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            DesignSubpageHeader(
              title: 'ÖPNV-Suche',
              leading: DesignIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLg,
                  0,
                  tokens.spaceLg,
                  tokens.spaceXl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PtStationField(
                      label: 'Von',
                      controller: _fromController,
                      onSelected: (s) => _fromStation = s,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    Center(
                      child: DesignIconButton(
                        icon: Icons.swap_vert_rounded,
                        onPressed: _swap,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    PtStationField(
                      label: 'Nach',
                      controller: _toController,
                      onSelected: (s) => _toStation = s,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: _arriveBy ? 'Ankunft bis' : 'Abfahrt',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMd,
                            ),
                          ),
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: tokens.textLow,
                          ),
                        ),
                        child: DesignText(
                          formatDateTime(_departure),
                          style: DesignTextStyle.body,
                          color: tokens.textHigh,
                        ),
                      ),
                    ),
                    SizedBox(height: tokens.spaceLg),
                    InkWell(
                      onTap: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      child: Row(
                        children: [
                          DesignText(
                            'Erweiterte Optionen',
                            style: DesignTextStyle.body,
                            color: tokens.primary,
                          ),
                          Icon(
                            _showAdvanced
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: tokens.primary,
                          ),
                        ],
                      ),
                    ),
                    if (_showAdvanced) ...[
                      SizedBox(height: tokens.spaceMd),
                      SwitchListTile(
                        title: DesignText(
                          'Ankunftszeit suchen',
                          style: DesignTextStyle.body,
                          color: tokens.textHigh,
                        ),
                        value: _arriveBy,
                        onChanged: (v) => setState(() => _arriveBy = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      SizedBox(height: tokens.spaceSm),
                      Row(
                        children: [
                          DesignText(
                            'Max. Umstiege: $_maxTransfers',
                            style: DesignTextStyle.body,
                            color: tokens.textHigh,
                          ),
                          Expanded(
                            child: Slider(
                              value: _maxTransfers.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              label: '$_maxTransfers',
                              onChanged: (v) =>
                                  setState(() => _maxTransfers = v.toInt()),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          DesignText(
                            'Ergebnisse: $_results',
                            style: DesignTextStyle.body,
                            color: tokens.textHigh,
                          ),
                          Expanded(
                            child: Slider(
                              value: _results.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '$_results',
                              onChanged: (v) =>
                                  setState(() => _results = v.toInt()),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: tokens.spaceXl),
                    SizedBox(
                      width: double.infinity,
                      child: DesignButton(
                        label: 'Suchen',
                        icon: Icons.search_rounded,
                        onPressed: _search,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
