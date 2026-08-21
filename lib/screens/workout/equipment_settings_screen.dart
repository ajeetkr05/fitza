import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/workout/equipment_settings_service.dart';

/// Lets the user select which equipment they have access to. Feeds
/// directly into RecommendationService via the availableEquipment
/// parameter - Exercise.isUsableWithEquipment() already implements the
/// filtering logic, this screen just finally populates the data it needs.
class EquipmentSettingsScreen extends StatefulWidget {
  const EquipmentSettingsScreen({super.key});

  @override
  State<EquipmentSettingsScreen> createState() => _EquipmentSettingsScreenState();
}

class _EquipmentSettingsScreenState extends State<EquipmentSettingsScreen> {
  // Tag -> display label. Tags must exactly match Exercise.equipmentTags
  // in exercise_database.dart - see EquipmentSettingsService for why.
  static const Map<String, String> _equipmentOptions = {
    'dumbbells': 'Dumbbells',
    'barbell': 'Barbell',
    'bench': 'Bench',
    'pull_up_bar': 'Pull-up Bar',
    'squat_rack': 'Squat Rack',
  };

  Set<String> _selected = {};
  bool _loaded = false;
  bool _saving = false;

  FitzaThemeColors _colors(BuildContext context) => Theme.of(context).extension<FitzaThemeColors>()!;

  @override
  void initState() {
    super.initState();
    EquipmentSettingsService.instance.getAvailableEquipmentStream().first.then((tags) {
      if (!mounted) return;
      setState(() {
        _selected = (tags ?? const <String>[]).toSet();
        _loaded = true;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await EquipmentSettingsService.instance.saveAvailableEquipment(_selected.toList());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context),
                    const SizedBox(height: 8),
                    Text(
                      'Select the equipment you have access to. We\'ll only '
                      'recommend exercises you can actually do - leave '
                      'everything unchecked for bodyweight-only workouts.',
                      style: TextStyle(color: colors.secondaryText, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: _equipmentOptions.entries
                            .map((entry) => _equipmentTile(context, entry.key, entry.value))
                            .toList(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryBlue,
                          foregroundColor: colors.textOnBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: colors.textOnBlue, strokeWidth: 2.4),
                              )
                            : const Text('Save', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final colors = _colors(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: colors.primaryBlue, size: 28),
        ),
        Expanded(
          child: Text(
            'Your Equipment',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _equipmentTile(BuildContext context, String tag, String label) {
    final colors = _colors(context);
    final isSelected = _selected.contains(tag);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selected.remove(tag);
            } else {
              _selected.add(tag);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? colors.primaryBlue.withValues(alpha: 0.1) : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? colors.primaryBlue : colors.border),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? colors.primaryBlue : colors.secondaryText,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
