import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'availability_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    final availableAsync = ref.watch(filteredAvailableSpotsProvider);
    final filters = ref.watch(searchFiltersProvider);
    final buildingsAsync = ref.watch(availableBuildingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wolne miejsca'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filters.hasFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: 'Filtry',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters panel
          if (_showFilters)
            _buildFiltersPanel(context, ref, filters, buildingsAsync),

          // Active filters chips
          if (filters.hasFilters && !_showFilters)
            _buildActiveFiltersChips(ref, filters),

          // Spots list
          Expanded(
            child: availableAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Błąd: $err')),
              data: (spots) {
                if (spots.isEmpty) {
                  return _buildEmptyState(filters.hasFilters);
                }
                return _buildSpotsList(context, ref, spots);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel(
    BuildContext context,
    WidgetRef ref,
    SearchFilters filters,
    AsyncValue<List<String>> buildingsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building filter
          const Text(
            'Budynek',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          buildingsAsync.when(
            loading: () => const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const Text('Błąd ładowania'),
            data: (buildings) => DropdownButtonFormField<String>(
              value: filters.building,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Wszystkie budynki'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Wszystkie budynki'),
                ),
                ...buildings.map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b),
                    )),
              ],
              onChanged: (value) {
                ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
                  building: value,
                  clearBuilding: value == null,
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Date range
          const Text(
            'Zakres dat',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'Od',
                  value: filters.dateFrom,
                  onChanged: (date) {
                    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
                      dateFrom: date,
                      clearDateFrom: date == null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'Do',
                  value: filters.dateTo,
                  onChanged: (date) {
                    ref.read(searchFiltersProvider.notifier).state = filters.copyWith(
                      dateTo: date,
                      clearDateTo: date == null,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Clear filters button
          if (filters.hasFilters)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(searchFiltersProvider.notifier).state = SearchFilters();
                },
                icon: const Icon(Icons.clear),
                label: const Text('Wyczyść filtry'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersChips(WidgetRef ref, SearchFilters filters) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (filters.building != null)
            Chip(
              label: Text(filters.building!),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(clearBuilding: true);
              },
            ),
          if (filters.dateFrom != null)
            Chip(
              label: Text('Od: ${_formatDate(filters.dateFrom!)}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(clearDateFrom: true);
              },
            ),
          if (filters.dateTo != null)
            Chip(
              label: Text('Do: ${_formatDate(filters.dateTo!)}'),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                ref.read(searchFiltersProvider.notifier).state =
                    filters.copyWith(clearDateTo: true);
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_alt_off : Icons.search_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'Brak wyników' : 'Brak wolnych miejsc',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Spróbuj zmienić kryteria wyszukiwania'
                  : 'Aktualnie żaden sąsiad nie udostępnia\nswojego miejsca parkingowego',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotsList(
    BuildContext context,
    WidgetRef ref,
    List<AvailableSpot> spots,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(availableSpotsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          final item = spots[index];
          final isNow = item.availability.isActiveNow;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => context.go('/reserve/${item.availability.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_parking,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Miejsce ${item.spot.spotNumber}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${item.spot.building}${item.spot.level != null ? ' • Poziom ${item.spot.level}' : ''}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isNow)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'TERAZ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Time and owner info
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.availability.timeRangeText,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          item.ownerName,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Reserve button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/reserve/${item.availability.id}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Zarezerwuj'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('pl', 'PL'),
        );
        onChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null
                    ? '${value!.day}.${value!.month.toString().padLeft(2, '0')}.${value!.year}'
                    : label,
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.grey[600],
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 18, color: Colors.grey[600]),
              )
            else
              Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}
