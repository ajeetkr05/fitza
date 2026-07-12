import 'package:flutter/material.dart';

import '../../../main.dart';
import '../../../models/progress/weight_entry.dart';
import '../../../services/progress/weight_firestore_service.dart';

class AddWeightScreen extends StatefulWidget {
  const AddWeightScreen({super.key});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();

  static const int _minWeight = 30;
  static const int _maxWeight = 200;
  static const int _decimalLoopMiddle = 10000;

  int _selectedWeightTenths = 750;
  int _lastDecimalIndex = _decimalLoopMiddle;

  late final FixedExtentScrollController _wholeWeightController;
  late final FixedExtentScrollController _decimalWeightController;
  late final ValueNotifier<int> _weightTenthsNotifier;

  bool _hasInitialisedWeight = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _weightTenthsNotifier = ValueNotifier<int>(_selectedWeightTenths);

    _wholeWeightController = FixedExtentScrollController(
      initialItem: _selectedWholeWeight - _minWeight,
    );

    _decimalWeightController = FixedExtentScrollController(
      initialItem: _decimalLoopMiddle + _selectedDecimalWeight,
    );

    _lastDecimalIndex = _decimalLoopMiddle + _selectedDecimalWeight;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _wholeWeightController.dispose();
    _decimalWeightController.dispose();
    _weightTenthsNotifier.dispose();
    super.dispose();
  }

  int get _selectedWholeWeight {
    return _selectedWeightTenths ~/ 10;
  }

  int get _selectedDecimalWeight {
    return _selectedWeightTenths % 10;
  }

  double get _selectedWeight {
    return _selectedWeightTenths / 10;
  }

  void _initialiseWeightFromEntries(List<WeightEntry> entries) {
    if (_hasInitialisedWeight) {
      return;
    }

    if (entries.isNotEmpty) {
      final latestWeight = entries.last.weightKg;

      if (latestWeight >= _minWeight && latestWeight <= _maxWeight) {
        _selectedWeightTenths = (latestWeight * 10).round();
        _weightTenthsNotifier.value = _selectedWeightTenths;
      }
    }

    _hasInitialisedWeight = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_wholeWeightController.hasClients ||
          !_decimalWeightController.hasClients) {
        return;
      }

      _wholeWeightController.jumpToItem(
        _selectedWholeWeight - _minWeight,
      );

      final decimalIndex = _decimalLoopMiddle + _selectedDecimalWeight;
      _lastDecimalIndex = decimalIndex;
      _decimalWeightController.jumpToItem(decimalIndex);
    });
  }

  void _updateWeightTenths(
    int newTenths, {
    bool syncWholeWheel = true,
  }) {
    final previousWhole = _selectedWholeWeight;

    final minTenths = _minWeight * 10;
    final maxTenths = _maxWeight * 10;
    final clampedTenths = newTenths.clamp(minTenths, maxTenths).toInt();

    if (_selectedWeightTenths == clampedTenths) {
      return;
    }

    final newWhole = clampedTenths ~/ 10;
    final wholeChanged = previousWhole != newWhole;

    _selectedWeightTenths = clampedTenths;

    if (syncWholeWheel && wholeChanged) {
      if (_wholeWeightController.hasClients) {
        final expectedWholeIndex = newWhole - _minWeight;

        if (_wholeWeightController.selectedItem != expectedWholeIndex) {
          _wholeWeightController.jumpToItem(expectedWholeIndex);
        }
      }
    }

    _weightTenthsNotifier.value = clampedTenths;
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final now = DateTime.now();

    setState(() {
      _selectedDateTime = selectedDateTime.isAfter(now)
          ? now
          : selectedDateTime;
    });
  }

  Future<void> _continue() async {
    if (_isSaving) {
      return;
    }

    final weight = _selectedWeight;

    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid weight.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final savedHeight =
          await WeightFirestoreService.instance.getSavedHeight();

      if (!mounted) {
        return;
      }

      if (savedHeight == null) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your height is missing. Please update your profile first.',
            ),
          ),
        );

        return;
      }

      await WeightFirestoreService.instance.saveWeightEntry(
        weightKg: weight,
        heightCm: savedHeight,
        notes: _notesController.text.trim(),
        recordedAt: _selectedDateTime,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weight saved.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      debugPrint('Firestore weight save error: $error');

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your weight. Please check your connection and try again.',
          ),
        ),
      );
    }
  }

  String _formattedDateTime() {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();

    final isToday =
        _selectedDateTime.year == now.year &&
        _selectedDateTime.month == now.month &&
        _selectedDateTime.day == now.day;

    final hour = _selectedDateTime.hour;
    final minute = _selectedDateTime.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    final dateText = isToday
        ? 'Today'
        : '${months[_selectedDateTime.month - 1]} ${_selectedDateTime.day}, ${_selectedDateTime.year}';

    return '$dateText · $displayHour:$minute $period';
  }

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final fitzaColors = _colors(context);

    return BoxDecoration(
      color: fitzaColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: _isDark(context)
              ? const Color(0x33000000)
              : const Color(0x0F000000),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _notesInputDecoration(BuildContext context) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      hintText: 'Add any notes...',
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      counterStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 11,
      ),
      alignLabelWithHint: true,
      filled: true,
      fillColor: fitzaColors.inputSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);

    return Scaffold(
      backgroundColor: fitzaColors.background,
      body: SafeArea(
        child: StreamBuilder<List<WeightEntry>>(
          stream: WeightFirestoreService.instance.getWeightEntriesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _initialiseWeightFromEntries(snapshot.data!);
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: fitzaColors.primaryText,
                                size: 29,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Add Weight',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: fitzaColors.primaryText,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),

                        const SizedBox(height: 22),

                        Container(
                          padding: const EdgeInsets.all(17),
                          decoration: _cardDecoration(context),
                          child: Column(
                            children: [
                              _formRow(
                                context,
                                icon: Icons.schedule_rounded,
                                title: 'Date & time',
                                child: InkWell(
                                  onTap: _isSaving ? null : _pickDateTime,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _formattedDateTime(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: fitzaColors.primaryText,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.edit_calendar_outlined,
                                          color: fitzaColors.primaryBlue,
                                          size: 23,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Divider(
                                height: 26,
                                color: fitzaColors.border,
                              ),

                              _formRow(
                                context,
                                icon: Icons.monitor_weight_outlined,
                                title: 'Weight',
                                child: _inlineWeightPicker(),
                              ),

                              Divider(
                                height: 26,
                                color: fitzaColors.border,
                              ),

                              _formRow(
                                context,
                                icon: Icons.edit_note_outlined,
                                title: 'Notes (optional)',
                                child: TextField(
                                  controller: _notesController,
                                  minLines: 2,
                                  maxLines: 7,
                                  maxLength: 200,
                                  keyboardType: TextInputType.multiline,
                                  style: TextStyle(
                                    color: fitzaColors.primaryText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _notesInputDecoration(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: fitzaColors.primaryBlue,
                        foregroundColor: fitzaColors.textOnBlue,
                        disabledBackgroundColor:
                            _isDark(context)
                                ? const Color(0xFF375C9F)
                                : const Color(0xFF9BB7EA),
                        disabledForegroundColor: fitzaColors.textOnBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _isDark(context) ? 0 : 2,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: fitzaColors.textOnBlue,
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(
                              'Save Weight',
                              style: TextStyle(
                                color: fitzaColors.textOnBlue,
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _inlineWeightPicker() {
    return Builder(
      builder: (context) {
        final fitzaColors = _colors(context);

        return ValueListenableBuilder<int>(
          valueListenable: _weightTenthsNotifier,
          builder: (context, selectedTenths, _) {
            final selectedWhole = selectedTenths ~/ 10;
            final selectedDecimal = selectedTenths % 10;

            return Container(
              height: 166,
              width: double.infinity,
              decoration: BoxDecoration(
                color: fitzaColors.inputSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: fitzaColors.border,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 46,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: fitzaColors.primaryBlue.withValues(
                        alpha: _isDark(context) ? 0.20 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        child: ListWheelScrollView.useDelegate(
                          controller: _wholeWeightController,
                          itemExtent: 46,
                          perspective: 0.003,
                          diameterRatio: 1.6,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            final newWhole = _minWeight + index;
                            final newTenths =
                                (newWhole * 10) + _selectedDecimalWeight;

                            _updateWeightTenths(
                              newTenths,
                              syncWholeWheel: false,
                            );
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: _maxWeight - _minWeight + 1,
                            builder: (context, index) {
                              final value = _minWeight + index;
                              final isSelected = value == selectedWhole;

                              return Center(
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? fitzaColors.primaryText
                                        : fitzaColors.secondaryText.withValues(
                                            alpha: 0.42,
                                          ),
                                    fontSize: isSelected ? 25 : 18,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          '.',
                          style: TextStyle(
                            color: fitzaColors.primaryText,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 52,
                        child: ListWheelScrollView.useDelegate(
                          controller: _decimalWeightController,
                          itemExtent: 46,
                          perspective: 0.003,
                          diameterRatio: 1.6,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            final change = index - _lastDecimalIndex;
                            _lastDecimalIndex = index;

                            if (change == 0) {
                              return;
                            }

                            _updateWeightTenths(_selectedWeightTenths + change);
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              final value = index % 10;
                              final isSelected = value == selectedDecimal;

                              return Center(
                                child: Text(
                                  value.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? fitzaColors.primaryText
                                        : fitzaColors.secondaryText.withValues(
                                            alpha: 0.42,
                                          ),
                                    fontSize: isSelected ? 25 : 18,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Text(
                        'kg',
                        style: TextStyle(
                          color: fitzaColors.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _formRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final fitzaColors = _colors(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: fitzaColors.primaryBlue.withValues(
              alpha: _isDark(context) ? 0.20 : 0.10,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: fitzaColors.primaryBlue,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: fitzaColors.secondaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ],
    );
  }
}