import 'package:flutter/material.dart';
import '../../main.dart';

import '../../services/workout/injury_settings_service.dart';

/// Lets the user flag muscle groups as injured/limited. Saved separately
/// from UserProfile (see InjurySettingsService) so this doesn't touch the
/// profile feature's file. Feeds directly into RecommendationService via
/// the injuredMuscleGroups parameter - both at muscle-group-selection level
/// (an injured group is never picked as today's focus) and at individual
/// exercise level (Exercise.isSafeFor excludes contraindicated exercises).
class InjurySettingsScreen extends StatefulWidget {
  const InjurySettingsScreen({super.key});

  @override
  State<InjurySettingsScreen> createState() => _InjurySettingsScreenState();
}

class _InjurySettingsScreenState extends State<InjurySettingsScreen> {
   FitzaThemeColors _colors(BuildContext context) => Theme.of(context).extension<FitzaThemeColors>()!;
bool _isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  // Excludes 'Full Body' - flagging "all of me" as injured doesn't make
  // sense as a selectable option; the engine already has a Core fallback
  // for the rare case every real muscle group ends up excluded.
  static const List<String> _selectableGroups = [
    'Chest', 'Back', 'Legs', 'Shoulders', 'Core', 'Arms',
  ];

  Set<String> _selected = {};
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    InjurySettingsService.instance.getInjuredMuscleGroupsStream().first.then((groups) {
      if (!mounted) return;
      setState(() {
        _selected = groups.toSet();
        _loaded = true;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loaded = true); // proceed with empty selection on error
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await InjurySettingsService.instance.saveInjuredMuscleGroups(_selected.toList());
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
    return Scaffold(
      backgroundColor: _colors(context).background,
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
                      'Select any areas you\'re currently dealing with an injury '
                      'or limitation for. We\'ll avoid recommending exercises that '
                      'target these areas.',
                      style: TextStyle(color: _colors(context).secondaryText, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: _selectableGroups.map(_groupTile).toList(),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colors(context).primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
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
    final fitzaColors = _colors(context);
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: fitzaColors.primaryBlue, size: 28),
        ),
        Expanded(
          child: Text(
            'Injuries & Limitations',
            textAlign: TextAlign.center,
            style: TextStyle(color: fitzaColors.primaryText, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _groupTile(String group) {
    final fitzaColors = _colors(context);
    final isSelected = _selected.contains(group);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selected.remove(group);
            } else {
              _selected.add(group);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? fitzaColors.primaryBlue.withValues(alpha: _isDark(context) ? 0.20 : 0.10) : fitzaColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? fitzaColors.primaryBlue : fitzaColors.border),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? fitzaColors.primaryBlue : fitzaColors.secondaryText,
              ),
              const SizedBox(width: 12),
              Text(
                group,
                style: TextStyle(
                  color: fitzaColors.primaryText,
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
