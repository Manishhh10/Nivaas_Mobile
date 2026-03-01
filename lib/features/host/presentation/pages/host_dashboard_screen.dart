import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:io';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/auth/data/models/auth_response.dart';
import 'package:nivaas/features/host/presentation/pages/host_edit_pages.dart';
import 'package:nivaas/features/host/presentation/pages/host_apply_screen.dart';
import 'package:nivaas/features/host/presentation/pages/location_picker_screen.dart';
import 'package:image_picker/image_picker.dart';

// Providers for host data
final hostListingsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.hostListings);
  final list =
      response.data['listings'] as List? ??
      response.data['data'] as List? ??
      [];
  return list.cast<Map<String, dynamic>>();
});

final hostExperiencesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.hostExperiences);
  final list =
      response.data['experiences'] as List? ??
      response.data['data'] as List? ??
      [];
  return list.cast<Map<String, dynamic>>();
});

final hostReservationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get(ApiEndpoints.hostReservations);
  final list =
      response.data['reservations'] as List? ??
      response.data['data'] as List? ??
      [];
  return list.cast<Map<String, dynamic>>();
});

// Old host dashboard page retired.

// ─── Create Listing Screen ───

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final _picker = ImagePicker();
  int _step = 0;

  final _locationCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _weekdayPriceCtrl = TextEditingController(text: '1000');
  final _weekendPremiumCtrl = TextEditingController(text: '5');
  final _countryCtrl = TextEditingController(text: 'Nepal');
  final _streetCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  int _maxGuests = 4;
  int _bedrooms = 1;
  int _beds = 1;
  int _bathrooms = 1;
  String _placeType = 'entire_place';
  double _latitude = 27.7172;
  double _longitude = 85.3240;
  final List<XFile> _images = [];

  final List<String> _highlights = [];
  final List<String> _amenities = [];
  final List<String> _standoutAmenities = [];
  final List<String> _safetyItems = [];
  bool _isLoading = false;

  static const List<Map<String, String>> placeTypes = [
    {'id': 'entire_place', 'label': 'Entire place'},
    {'id': 'room', 'label': 'Private room'},
    {'id': 'shared_room', 'label': 'Shared room'},
  ];

  static const List<String> guestFavorites = [
    'wifi',
    'tv',
    'kitchen',
    'washer',
    'free_parking',
    'paid_parking',
    'ac',
    'workspace',
  ];

  static const List<String> standout = [
    'pool',
    'hot_tub',
    'patio',
    'bbq',
    'outdoor_dining',
    'fire_pit',
    'pool_table',
    'fireplace',
    'piano',
    'exercise',
    'lake',
    'beach',
    'ski',
    'outdoor_shower',
  ];

  static const List<String> safety = [
    'smoke_alarm',
    'first_aid',
    'fire_extinguisher',
    'co_alarm',
  ];

  static const List<String> highlightOptions = [
    'peaceful',
    'unique',
    'family_friendly',
    'stylish',
    'central',
    'spacious',
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _weekdayPriceCtrl.dispose();
    _weekendPremiumCtrl.dispose();
    _countryCtrl.dispose();
    _streetCtrl.dispose();
    _aptCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _placeType.isNotEmpty && _locationCtrl.text.trim().isNotEmpty;
      case 1:
        return _maxGuests >= 1 &&
            _bedrooms >= 1 &&
            _beds >= 1 &&
            _bathrooms >= 1;
      case 3:
        return _images.isNotEmpty;
      case 4:
        return _titleCtrl.text.trim().isNotEmpty;
      case 5:
        return _descriptionCtrl.text.trim().isNotEmpty;
      case 6:
        return (double.tryParse(_weekdayPriceCtrl.text.trim()) ?? 0) > 0;
      default:
        return true;
    }
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _images.addAll(files));
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _locationCtrl.text.trim(),
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _locationCtrl.text = result.location;
      _latitude = result.lat;
      _longitude = result.lng;
    });
  }

  void _toggleItem(List<String> list, String value, {int max = 999}) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else if (list.length < max) {
        list.add(value);
      }
    });
  }

  Future<void> _submit() async {
    if (!_canContinue()) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final weekdayPrice = double.tryParse(_weekdayPriceCtrl.text.trim()) ?? 0;
      final weekendPremium = int.tryParse(_weekendPremiumCtrl.text.trim()) ?? 5;
      final weekendPrice = (weekdayPrice * (1 + (weekendPremium / 100)))
          .round();

      final imageFiles = <MultipartFile>[];
      for (final file in _images) {
        imageFiles.add(
          await MultipartFile.fromFile(file.path, filename: file.name),
        );
      }

      final payload = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'price': weekdayPrice,
        'weekendPrice': weekendPrice,
        'weekendPremium': weekendPremium,
        'description': _descriptionCtrl.text.trim(),
        'highlights': jsonEncode(_highlights),
        'amenities': jsonEncode(_amenities),
        'standoutAmenities': jsonEncode(_standoutAmenities),
        'safetyItems': jsonEncode(_safetyItems),
        'images': imageFiles,
        'maxGuests': _maxGuests,
        'bedrooms': _bedrooms,
        'beds': _beds,
        'bathrooms': _bathrooms,
        'residentialAddress': jsonEncode({
          'country': _countryCtrl.text.trim(),
          'street': _streetCtrl.text.trim(),
          'apt': _aptCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'province': _provinceCtrl.text.trim(),
          'postalCode': _postalCodeCtrl.text.trim(),
        }),
        'isPublished': false,
      });
      await api.post(ApiEndpoints.hostListings, data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stay draft created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = 8;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Stay (Step ${_step + 1}/$totalSteps)',
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / totalSteps,
            color: primaryOrange,
            backgroundColor: Colors.orange.shade100,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [_buildStepContent()],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _step == 0
                          ? null
                          : () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_step == totalSteps - 1
                                ? _submit
                                : (_canContinue()
                                      ? () => setState(() => _step++)
                                      : null)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == totalSteps - 1 ? 'Create Stay' : 'Next',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What type of place and where is it?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _placeType,
              decoration: _dec('Place Type'),
              items: placeTypes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['id'],
                      child: Text(item['label']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _placeType = v ?? 'entire_place'),
            ),
            const SizedBox(height: 14),
            _field(_locationCtrl, 'Location', 'City / area / address'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Search on map / Use current location'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share basics about your stay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _counter(
              'Guests',
              _maxGuests,
              (v) => setState(() => _maxGuests = v),
            ),
            _counter(
              'Bedrooms',
              _bedrooms,
              (v) => setState(() => _bedrooms = v),
            ),
            _counter('Beds', _beds, (v) => setState(() => _beds = v)),
            _counter(
              'Bathrooms',
              _bathrooms,
              (v) => setState(() => _bathrooms = v),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select amenities',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _chipSection('Guest favorites', guestFavorites, _amenities),
            _chipSection('Standout amenities', standout, _standoutAmenities),
            _chipSection('Safety items', safety, _safetyItems),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add photos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_images.length} selected',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map(
                  (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () => setState(() => _images.remove(file)),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title and highlights',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(_titleCtrl, 'Title', 'Short and clear title', maxLines: 2),
            const Text('Pick up to 2 highlights'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: highlightOptions.map((h) {
                final selected = _highlights.contains(h);
                final disabled = !selected && _highlights.length >= 2;
                return ChoiceChip(
                  label: Text(h.replaceAll('_', ' ')),
                  selected: selected,
                  onSelected: disabled
                      ? null
                      : (_) => _toggleItem(_highlights, h, max: 2),
                );
              }).toList(),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your stay',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(
              _descriptionCtrl,
              'Description',
              'Tell guests what makes it special',
              maxLines: 6,
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set pricing',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(
              _weekdayPriceCtrl,
              'Weekday Price (NPR)',
              'Base weekday price',
              isNumber: true,
            ),
            _field(
              _weekendPremiumCtrl,
              'Weekend Premium (%)',
              'e.g. 5',
              isNumber: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Weekend price: NPR ${((double.tryParse(_weekdayPriceCtrl.text) ?? 0) * (1 + ((int.tryParse(_weekendPremiumCtrl.text) ?? 0) / 100))).round()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Residential address',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(_countryCtrl, 'Country', 'Country'),
            _field(_streetCtrl, 'Street', 'Street address'),
            _field(_aptCtrl, 'Apt / Floor / Bldg', 'Optional'),
            _field(_cityCtrl, 'City', 'City / town / village'),
            _field(_provinceCtrl, 'Province', 'Province / state / territory'),
            _field(_postalCodeCtrl, 'Postal code', 'Postal code'),
          ],
        );
    }
  }

  Widget _chipSection(
    String title,
    List<String> options,
    List<String> selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (item) => FilterChip(
                    label: Text(item.replaceAll('_', ' ')),
                    selected: selected.contains(item),
                    onSelected: (_) => _toggleItem(selected, item),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: _dec(label, hint: hint),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryOrange),
    ),
  );

  Widget _counter(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: primaryOrange,
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: primaryOrange,
          ),
        ],
      ),
    );
  }
}

// ─── Create Experience Screen ───

class CreateExperienceScreen extends StatefulWidget {
  const CreateExperienceScreen({super.key});

  @override
  State<CreateExperienceScreen> createState() => _CreateExperienceScreenState();
}

class _CreateExperienceScreenState extends State<CreateExperienceScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final _picker = ImagePicker();
  int _step = 0;

  final _titleCtrl = TextEditingController();
  String _category = 'art_design';
  final _yearsOfExperienceCtrl = TextEditingController(text: '1');
  final _locationCtrl = TextEditingController();
  double _latitude = 27.7172;
  double _longitude = 85.3240;
  final _priceCtrl = TextEditingController(text: '1500');
  final _durationCtrl = TextEditingController(text: '2 hours');
  final _descCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Nepal');
  final _streetCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  final List<XFile> _images = [];
  final List<DateTime> _availableDates = [];
  final List<Map<String, TextEditingController>> _itineraryCtrls = [
    {
      'title': TextEditingController(),
      'duration': TextEditingController(text: '1 hr'),
      'description': TextEditingController(),
    },
  ];

  int _maxGuests = 1;
  bool _isLoading = false;

  static const List<String> experienceCategories = [
    'art_design',
    'fitness_wellness',
    'food_drink',
    'history_culture',
    'nature_outdoors',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearsOfExperienceCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descCtrl.dispose();
    _countryCtrl.dispose();
    _streetCtrl.dispose();
    _aptCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    for (final item in _itineraryCtrls) {
      item['title']?.dispose();
      item['duration']?.dispose();
      item['description']?.dispose();
    }
    super.dispose();
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _category.isNotEmpty;
      case 1:
        return _locationCtrl.text.trim().isNotEmpty;
      case 2:
        return _images.length >= 5;
      case 3:
        return _itineraryCtrls.any(
          (item) => item['title']!.text.trim().isNotEmpty,
        );
      case 4:
        return _availableDates.isNotEmpty;
      case 6:
        return _titleCtrl.text.trim().isNotEmpty &&
            _descCtrl.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _pickExperienceImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _images.addAll(files));
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLocation: _locationCtrl.text.trim(),
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _locationCtrl.text = result.location;
      _latitude = result.lat;
      _longitude = result.lng;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: DateTime(now.year, now.month, now.day),
    );
    if (picked == null) return;
    final date = DateTime(picked.year, picked.month, picked.day);
    if (_availableDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    )) {
      return;
    }
    setState(() {
      _availableDates.add(date);
      _availableDates.sort((a, b) => a.compareTo(b));
    });
  }

  Future<void> _submit() async {
    if (!_canContinue()) return;

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final imageFiles = <MultipartFile>[];
      for (final file in _images) {
        imageFiles.add(
          await MultipartFile.fromFile(file.path, filename: file.name),
        );
      }

      final itinerary = _itineraryCtrls
          .map(
            (item) => {
              'title': item['title']!.text.trim(),
              'duration': item['duration']!.text.trim(),
              'description': item['description']!.text.trim(),
            },
          )
          .where((item) => (item['title'] ?? '').isNotEmpty)
          .toList();

      final payload = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'category': _category,
        'location': _locationCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'duration': _durationCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'yearsOfExperience':
            int.tryParse(_yearsOfExperienceCtrl.text.trim()) ?? 0,
        'maxGuests': _maxGuests,
        'images': imageFiles,
        'itinerary': jsonEncode(itinerary),
        'availableDates': jsonEncode(
          _availableDates
              .map(
                (d) =>
                    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
              )
              .toList(),
        ),
        'residentialAddress': jsonEncode({
          'country': _countryCtrl.text.trim(),
          'street': _streetCtrl.text.trim(),
          'apt': _aptCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'province': _provinceCtrl.text.trim(),
          'postalCode': _postalCodeCtrl.text.trim(),
        }),
        'isPublished': false,
      });
      await api.post(ApiEndpoints.hostExperiences, data: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experience draft created!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const totalSteps = 7;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Experience (Step ${_step + 1}/$totalSteps)',
          style: const TextStyle(fontSize: 16),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_step + 1) / totalSteps,
            color: primaryOrange,
            backgroundColor: Colors.orange.shade100,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [_buildExpStepContent()],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _step == 0
                          ? null
                          : () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_step == totalSteps - 1
                                ? _submit
                                : (_canContinue()
                                      ? () => setState(() => _step++)
                                      : null)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == totalSteps - 1
                                  ? 'Create Experience'
                                  : 'Next',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpStepContent() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category and experience',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _dec('Category'),
              items: experienceCategories
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),
            _field(
              _yearsOfExperienceCtrl,
              'Years of Experience',
              'e.g. 2',
              isNumber: true,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(_locationCtrl, 'Location', 'Where will this happen?'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openLocationPicker,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Search on map / Use current location'),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add photos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${_images.length} selected (minimum 5)',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._images.map(
                  (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: InkWell(
                          onTap: () => setState(() => _images.remove(file)),
                          child: CircleAvatar(
                            radius: 10,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickExperienceImages,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itinerary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _itineraryCtrls.add({
                        'title': TextEditingController(),
                        'duration': TextEditingController(text: '1 hr'),
                        'description': TextEditingController(),
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add activity'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_itineraryCtrls.length, (index) {
              final item = _itineraryCtrls[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.45)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _field(
                      item['title']!,
                      'Activity title',
                      'e.g. Welcome + briefing',
                    ),
                    _field(item['duration']!, 'Duration', 'e.g. 1 hr'),
                    _field(
                      item['description']!,
                      'Description',
                      'What guests do here',
                      maxLines: 2,
                    ),
                    if (_itineraryCtrls.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setState(() {
                            item['title']?.dispose();
                            item['duration']?.dispose();
                            item['description']?.dispose();
                            _itineraryCtrls.removeAt(index);
                          }),
                          child: const Text('Remove'),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available dates',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.add),
                  label: const Text('Add date'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableDates
                  .map(
                    (d) => Chip(
                      label: Text('${d.day}/${d.month}/${d.year}'),
                      onDeleted: () =>
                          setState(() => _availableDates.remove(d)),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Capacity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _counter(
              'Max Guests',
              _maxGuests,
              (v) => setState(() => _maxGuests = v),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Final details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _field(_titleCtrl, 'Title', 'Experience title'),
            _field(
              _descCtrl,
              'Description',
              'Describe what guests will do',
              maxLines: 5,
            ),
            _field(
              _priceCtrl,
              'Price (NPR)',
              'Price per person',
              isNumber: true,
            ),
            _field(_durationCtrl, 'Duration', 'e.g. 3 hours'),
            const SizedBox(height: 8),
            const Text(
              'Residential address',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _field(_countryCtrl, 'Country', 'Country'),
            _field(_streetCtrl, 'Street', 'Street address'),
            _field(_aptCtrl, 'Apt / Floor / Bldg', 'Optional'),
            _field(_cityCtrl, 'City', 'City / town / village'),
            _field(_provinceCtrl, 'Province', 'Province / state / territory'),
            _field(_postalCodeCtrl, 'Postal code', 'Postal code'),
          ],
        );
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: _dec(label, hint: hint),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _counter(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: primaryOrange,
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
            color: primaryOrange,
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: primaryOrange),
    ),
  );
}
