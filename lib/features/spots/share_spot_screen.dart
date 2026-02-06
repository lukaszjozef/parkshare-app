import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'spots_provider.dart';
import 'availability_provider.dart';

class ShareSpotScreen extends ConsumerStatefulWidget {
  final String spotId;

  const ShareSpotScreen({super.key, required this.spotId});

  @override
  ConsumerState<ShareSpotScreen> createState() => _ShareSpotScreenState();
}

class _ShareSpotScreenState extends ConsumerState<ShareSpotScreen> {
  int _selectedHours = 4;
  bool _isLoading = false;
  bool _useCustomTime = false;
  DateTime _customStart = DateTime.now();
  DateTime _customEnd = DateTime.now().add(const Duration(hours: 4));

  Future<void> _shareNow() async {
    setState(() => _isLoading = true);

    try {
      final service = ref.read(availabilityServiceProvider);

      if (_useCustomTime) {
        await service.shareCustom(
          spotId: widget.spotId,
          startsAt: _customStart,
          endsAt: _customEnd,
        );
      } else {
        await service.shareNow(
          spotId: widget.spotId,
          hours: _selectedHours,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Miejsce udostępnione!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/spots');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _customStart : _customEnd,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _customStart : _customEnd),
    );

    if (time == null || !mounted) return;

    setState(() {
      final newDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      if (isStart) {
        _customStart = newDateTime;
        if (_customEnd.isBefore(_customStart)) {
          _customEnd = _customStart.add(const Duration(hours: 2));
        }
      } else {
        _customEnd = newDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Udostępnij miejsce'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/spots'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick share section
            const Text(
              'Szybkie udostępnienie',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Hour options
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [2, 4, 6, 8, 12].map((hours) {
                final isSelected = !_useCustomTime && _selectedHours == hours;
                return ChoiceChip(
                  label: Text('$hours godz.'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _useCustomTime = false;
                      _selectedHours = hours;
                    });
                  },
                  selectedColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Custom time section
            Row(
              children: [
                const Text(
                  'Lub wybierz zakres',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _useCustomTime,
                  onChanged: (value) => setState(() => _useCustomTime = value),
                ),
              ],
            ),

            if (_useCustomTime) ...[
              const SizedBox(height: 16),

              // Start time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.play_arrow, color: Color(0xFF10B981)),
                title: const Text('Od'),
                subtitle: Text(
                  '${_customStart.day}.${_customStart.month}.${_customStart.year} '
                  '${_customStart.hour.toString().padLeft(2, '0')}:${_customStart.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _pickDateTime(true),
              ),

              // End time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Do'),
                subtitle: Text(
                  '${_customEnd.day}.${_customEnd.month}.${_customEnd.year} '
                  '${_customEnd.hour.toString().padLeft(2, '0')}:${_customEnd.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _pickDateTime(false),
              ),
            ],

            const SizedBox(height: 32),

            // Summary card
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _useCustomTime
                            ? 'Miejsce będzie dostępne od ${_customStart.hour}:${_customStart.minute.toString().padLeft(2, '0')} '
                              'do ${_customEnd.hour}:${_customEnd.minute.toString().padLeft(2, '0')}'
                            : 'Miejsce będzie dostępne przez $_selectedHours godzin od teraz',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Share button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _shareNow,
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.share),
              label: const Text(
                'Udostępnij teraz',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
