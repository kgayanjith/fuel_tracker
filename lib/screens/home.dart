import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/appbar.dart';
import '../widgets/dialogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Fuel Tracker",
        leadingIconType: LeadingIconType.notification,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
      ),
      extendBodyBehindAppBar: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildTab(label: 'Runtime', index: 0),
                    _buildTab(label: 'Fuel', index: 1),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Expanded(
                child: _selectedTab == 0
                    ? const _RuntimeTab()
                    : const _FuelTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({required String label, required int index}) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color.fromARGB(0, 0, 0, 0),
            borderRadius: BorderRadius.circular(26),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
      ),
    );
  }
}

class _RuntimeTab extends StatefulWidget {
  const _RuntimeTab();

  @override
  State<_RuntimeTab> createState() => _RuntimeTabState();
}

class _RuntimeTabState extends State<_RuntimeTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String? _selectedGeneratorId;
  String? _selectedGeneratorName;
  String? _selectedHour;
  String? _selectedMinute;
  bool _isSaving = false;

  final List<String> _hours = List.generate(
    24,
    (i) => i.toString().padLeft(2, '0'),
  );
  final List<String> _minutes = List.generate(
    4,
    (i) => (i * 15).toString().padLeft(2, '0'),
  );

  Future<void> _saveRuntime() async {
    if (_selectedGeneratorId == null ||
        _selectedDay == null ||
        _selectedHour == null ||
        _selectedMinute == null) {
      showMessageDialog(
        context,
        title: 'Missing Fields',
        message: 'Please fill in all fields',
      );
      return;
    }

    final hours = int.parse(_selectedHour!);
    final minutes = int.parse(_selectedMinute!);

    if (hours == 0 && minutes == 0) {
      showMessageDialog(
        context,
        title: 'Invalid Runtime',
        message: 'Runtime must be greater than 0',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final generatorRef = FirebaseFirestore.instance
          .collection('generators')
          .doc(_selectedGeneratorId);
      final generatorSnap = await generatorRef.get();
      final generatorData = generatorSnap.data();

      if (generatorData == null) {
        if (!mounted) return;
        showMessageDialog(
          context,
          title: 'Error',
          message: 'Selected generator no longer exists',
        );
        return;
      }

      final currentFuel =
          (generatorData['currentFuel'] as num?)?.toDouble() ?? 0;
      final usageRatePerHour =
          (generatorData['fuelUsage'] as num?)?.toDouble() ?? 0;

      // No fuel in the tank at all.
      if (currentFuel <= 0) {
        if (!mounted) return;
        showMessageDialog(
          context,
          title: 'No Fuel Added',
          message:
              '${_selectedGeneratorName ?? 'This generator'} has no fuel '
              'added yet. Please add fuel before logging runtime.',
        );
        return;
      }

      final runtimeHours = hours + (minutes / 60);
      final fuelNeeded = runtimeHours * usageRatePerHour;

      // Not enough fuel in the tank to cover this runtime entry.
      if (fuelNeeded > currentFuel) {
        if (!mounted) return;
        showMessageDialog(
          context,
          title: 'Insufficient Fuel',
          message:
              'This runtime needs ~${fuelNeeded.toStringAsFixed(1)}L, but '
              '${_selectedGeneratorName ?? 'the generator'} only has '
              '${currentFuel.toStringAsFixed(1)}L left. Add more fuel or '
              'log a shorter runtime.',
        );
        return;
      }

      await FirebaseFirestore.instance.collection('runtime_logs').add({
        'generatorId': _selectedGeneratorId,
        'generatorName': _selectedGeneratorName,
        'date': Timestamp.fromDate(_selectedDay!),
        'hours': hours,
        'minutes': minutes,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await generatorRef.update({
        'currentFuel': FieldValue.increment(-fuelNeeded),
      });

      if (!mounted) return;
      showMessageDialog(context, title: 'Success', message: 'Runtime saved');
      setState(() {
        _selectedGeneratorId = null;
        _selectedGeneratorName = null;
        _selectedHour = null;
        _selectedMinute = null;
      });
    } catch (e) {
      if (!mounted) return;
      showMessageDialog(
        context,
        title: 'Error',
        message: 'Failed to save runtime: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Date",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                headerStyle: HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  titleTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.black,
                  ),
                  headerPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  titleTextFormatter: (date, locale) {
                    return '${_monthName(date.month)}       ${date.year}';
                  },
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  outsideTextStyle: const TextStyle(
                    color: Colors.black26,
                    fontSize: 14,
                  ),
                  defaultTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  todayDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  todayTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Select Generator",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('generators')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text(
                      '--Select--',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                    value: _selectedGeneratorId,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: docs
                        .map(
                          (doc) => DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              (doc.data() as Map<String, dynamic>)['name']
                                      ?.toString() ??
                                  '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      final doc = docs.firstWhere((d) => d.id == val);
                      final name = (doc.data() as Map<String, dynamic>)['name']
                          ?.toString();
                      setState(() {
                        _selectedGeneratorId = val;
                        _selectedGeneratorName = name;
                      });
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            "Select Running Time",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text(
                        '--Hours--',
                        style: TextStyle(color: Colors.black38, fontSize: 14),
                      ),
                      value: _selectedHour,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _hours
                          .map(
                            (h) => DropdownMenuItem(
                              value: h,
                              child: Text(
                                '$h hrs',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedHour = val),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text(
                        '--Minutes--',
                        style: TextStyle(color: Colors.black38, fontSize: 14),
                      ),
                      value: _selectedMinute,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _minutes
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                '$m min',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedMinute = val),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = DateTime.now();
                      _selectedGeneratorId = null;
                      _selectedGeneratorName = null;
                      _selectedHour = null;
                      _selectedMinute = null;
                      _focusedDay = DateTime.now();
                    });
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () => showConfirmationSheeRuntime(
                          context,
                          onConfirm: _saveRuntime,
                        ),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 110),
        ],
      ),
    );
  }

  void showConfirmationSheeRuntime(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Text(
                "Are you sure you want to save ?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

class _FuelTab extends StatefulWidget {
  const _FuelTab();

  @override
  State<_FuelTab> createState() => _FuelTabState();
}

class _FuelTabState extends State<_FuelTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  String? _selectedGeneratorId;
  String? _selectedGeneratorName;
  double? _selectedGeneratorCapacity;
  bool _isSaving = false;

  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();

  @override
  void dispose() {
    _litersController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveFuel() async {
    if (_selectedGeneratorId == null ||
        _selectedDay == null ||
        _litersController.text.trim().isEmpty ||
        _rateController.text.trim().isEmpty) {
      showMessageDialog(
        context,
        title: 'Missing Fields',
        message: 'Please fill in all fields',
      );
      return;
    }

    final litersToAdd = double.tryParse(_litersController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());

    if (litersToAdd == null || rate == null) {
      showMessageDialog(
        context,
        title: 'Invalid Input',
        message: 'Enter valid numbers for fuel and rate',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Re-fetch the generator doc fresh so validation uses the latest
      // current fuel level, not a possibly-stale value held in state.
      final generatorRef = FirebaseFirestore.instance
          .collection('generators')
          .doc(_selectedGeneratorId);
      final generatorSnap = await generatorRef.get();
      final generatorData = generatorSnap.data();

      if (generatorData == null) {
        if (!mounted) return;
        showMessageDialog(
          context,
          title: 'Error',
          message: 'Selected generator no longer exists',
        );
        return;
      }

      final capacity = (generatorData['fuelCapacity'] as num?)?.toDouble() ?? 0;
      final currentFuel =
          (generatorData['currentFuel'] as num?)?.toDouble() ?? 0;

      if (currentFuel + litersToAdd > capacity) {
        if (!mounted) return;
        final remainingCapacity = capacity - currentFuel;
        showMessageDialog(
          context,
          title: 'Fuel Limit Exceeded',
          message:
              'Only ${remainingCapacity.toStringAsFixed(1)}L of capacity left '
              '(tank holds ${capacity.toStringAsFixed(1)}L)',
        );
        return;
      }

      await FirebaseFirestore.instance.collection('fuel_logs').add({
        'generatorId': _selectedGeneratorId,
        'generatorName': _selectedGeneratorName,
        'date': Timestamp.fromDate(_selectedDay!),
        'liters': litersToAdd,
        'rate': rate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await generatorRef.update({
        'currentFuel': FieldValue.increment(litersToAdd),
      });

      if (!mounted) return;
      showMessageDialog(
        context,
        title: 'Success',
        message: 'Fuel record saved',
      );
      setState(() {
        _selectedGeneratorId = null;
        _selectedGeneratorName = null;
        _selectedGeneratorCapacity = null;
        _litersController.clear();
        _rateController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      showMessageDialog(
        context,
        title: 'Error',
        message: 'Failed to save fuel record: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Date",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() => _focusedDay = focusedDay);
                },
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                headerStyle: HeaderStyle(
                  titleCentered: false,
                  formatButtonVisible: false,
                  titleTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.black,
                  ),
                  headerPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  titleTextFormatter: (date, locale) {
                    return '${_monthName(date.month)}       ${date.year}';
                  },
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: true,
                  outsideTextStyle: const TextStyle(
                    color: Colors.black26,
                    fontSize: 14,
                  ),
                  defaultTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  weekendTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  todayDecoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  todayTextStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Select Generator",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('generators')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text(
                      '--Select--',
                      style: TextStyle(color: Colors.black38, fontSize: 14),
                    ),
                    value: _selectedGeneratorId,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: docs
                        .map(
                          (doc) => DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              (doc.data() as Map<String, dynamic>)['name']
                                      ?.toString() ??
                                  '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      final doc = docs.firstWhere((d) => d.id == val);
                      final data = doc.data() as Map<String, dynamic>;
                      setState(() {
                        _selectedGeneratorId = val;
                        _selectedGeneratorName = data['name']?.toString();
                        _selectedGeneratorCapacity =
                            (data['fuelCapacity'] as num?)?.toDouble();
                      });
                    },
                  ),
                ),
              );
            },
          ),

          if (_selectedGeneratorCapacity != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tank capacity: ${_selectedGeneratorCapacity!.toStringAsFixed(1)} L',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],

          const SizedBox(height: 24),

          const Text(
            "Liters Added",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: TextField(
              controller: _litersController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter fuel amount',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            "Rate Rs.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDDDDD)),
            ),
            child: TextField(
              controller: _rateController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter fuel rate',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = DateTime.now();
                      _selectedGeneratorId = null;
                      _selectedGeneratorName = null;
                      _selectedGeneratorCapacity = null;
                      _focusedDay = DateTime.now();
                      _litersController.clear();
                      _rateController.clear();
                    });
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: _isSaving
                      ? null
                      : () => showConfirmationSheeFuel(
                          context,
                          onConfirm: _saveFuel,
                        ),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 110),
        ],
      ),
    );
  }

  void showConfirmationSheeFuel(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 22,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Text(
                "Are you sure you want to save ?",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
