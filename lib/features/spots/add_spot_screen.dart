import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'spots_provider.dart';

class AddSpotScreen extends ConsumerStatefulWidget {
  const AddSpotScreen({super.key});

  @override
  ConsumerState<AddSpotScreen> createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends ConsumerState<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();
  final _spotNumberController = TextEditingController();
  final _levelController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _buildingController.dispose();
    _spotNumberController.dispose();
    _levelController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSpot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(spotsServiceProvider);
      await service.addSpot(
        building: _buildingController.text.trim(),
        spotNumber: _spotNumberController.text.trim(),
        level: _levelController.text.trim().isEmpty
            ? null
            : _levelController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      ref.invalidate(userSpotsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Miejsce dodane!'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj miejsce'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/spots'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Podaj dane swojego miejsca parkingowego, '
                          'aby sąsiedzi mogli je łatwo znaleźć.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Building
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(
                  labelText: 'Budynek *',
                  hintText: 'np. A, B, C lub adres',
                  prefixIcon: Icon(Icons.apartment),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj budynek';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Spot number
              TextFormField(
                controller: _spotNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numer miejsca *',
                  hintText: 'np. 42, A15',
                  prefixIcon: Icon(Icons.tag),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj numer miejsca';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Level (optional)
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Poziom (opcjonalnie)',
                  hintText: 'np. -1, 0, 1',
                  prefixIcon: Icon(Icons.layers),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Description (optional)
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis (opcjonalnie)',
                  hintText: 'np. Przy windzie, łatwy dojazd',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSpot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Dodaj miejsce',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
