import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nivaas/core/api/api_client.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/widgets/nivaas_image.dart';
import 'package:nivaas/features/host/presentation/pages/location_picker_screen.dart';

class HostEditListingScreen extends StatefulWidget {
  final String listingId;
  const HostEditListingScreen({super.key, required this.listingId});

  @override
  State<HostEditListingScreen> createState() => _HostEditListingScreenState();
}

class _HostEditListingScreenState extends State<HostEditListingScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weekendPremiumCtrl = TextEditingController(text: '5');
  final _descriptionCtrl = TextEditingController();
  final _maxGuestsCtrl = TextEditingController(text: '1');
  final _bedroomsCtrl = TextEditingController(text: '1');
  final _bedsCtrl = TextEditingController(text: '1');
  final _bathroomsCtrl = TextEditingController(text: '1');

  final _countryCtrl = TextEditingController(text: 'Nepal');
  final _streetCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  List<String> _existingImages = [];
  final List<XFile> _newImages = [];

  List<String> _highlights = [];
  List<String> _amenities = [];
  List<String> _standoutAmenities = [];
  List<String> _safetyItems = [];

  double _latitude = 27.7172;
  double _longitude = 85.3240;
  bool _isPublished = false;

  bool _loading = true;
  bool _saving = false;

  static const List<String> highlightOptions = [
    'peaceful',
    'unique',
    'family_friendly',
    'stylish',
    'central',
    'spacious',
  ];

  static const List<String> amenityOptions = [
    'wifi',
    'tv',
    'kitchen',
    'washer',
    'free_parking',
    'paid_parking',
    'ac',
    'workspace',
  ];

  static const List<String> standoutOptions = [
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

  static const List<String> safetyOptions = [
    'smoke_alarm',
    'first_aid',
    'fire_extinguisher',
    'co_alarm',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _weekendPremiumCtrl.dispose();
    _descriptionCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _bedroomsCtrl.dispose();
    _bedsCtrl.dispose();
    _bathroomsCtrl.dispose();
    _countryCtrl.dispose();
    _streetCtrl.dispose();
    _aptCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = ApiClient();
      final res = await api.get(ApiEndpoints.hostListingById(widget.listingId));
      final listing = (res.data['listing'] ?? {}) as Map<String, dynamic>;

      _titleCtrl.text = (listing['title'] ?? '').toString();
      _locationCtrl.text = (listing['location'] ?? '').toString();
      _priceCtrl.text = (listing['price'] ?? 0).toString();
      _weekendPremiumCtrl.text = (listing['weekendPremium'] ?? 5).toString();
      _descriptionCtrl.text = (listing['description'] ?? '').toString();
      _maxGuestsCtrl.text = (listing['maxGuests'] ?? 1).toString();
      _bedroomsCtrl.text = (listing['bedrooms'] ?? 1).toString();
      _bedsCtrl.text = (listing['beds'] ?? 1).toString();
      _bathroomsCtrl.text = (listing['bathrooms'] ?? 1).toString();
      _latitude = (listing['latitude'] is num) ? (listing['latitude'] as num).toDouble() : 27.7172;
      _longitude = (listing['longitude'] is num) ? (listing['longitude'] as num).toDouble() : 85.3240;
      _isPublished = listing['isPublished'] == true;

      _highlights = List<String>.from(listing['highlights'] ?? []);
      _amenities = List<String>.from(listing['amenities'] ?? []);
      _standoutAmenities = List<String>.from(listing['standoutAmenities'] ?? []);
      _safetyItems = List<String>.from(listing['safetyItems'] ?? []);
      _existingImages = List<String>.from(listing['images'] ?? []);

      final addr = (listing['residentialAddress'] is Map<String, dynamic>)
          ? listing['residentialAddress'] as Map<String, dynamic>
          : <String, dynamic>{};
      _countryCtrl.text = (addr['country'] ?? 'Nepal').toString();
      _streetCtrl.text = (addr['street'] ?? '').toString();
      _aptCtrl.text = (addr['apt'] ?? '').toString();
      _cityCtrl.text = (addr['city'] ?? '').toString();
      _provinceCtrl.text = (addr['province'] ?? '').toString();
      _postalCodeCtrl.text = (addr['postalCode'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load stay: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _newImages.addAll(files));
  }

  Future<void> _pickLocation() async {
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

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and location are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ApiClient();
      final newImageFiles = <MultipartFile>[];
      for (final file in _newImages) {
        newImageFiles.add(await MultipartFile.fromFile(file.path, filename: file.name));
      }

      final weekdayPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0;
      final weekendPremium = int.tryParse(_weekendPremiumCtrl.text.trim()) ?? 5;
      final weekendPrice = (weekdayPrice * (1 + weekendPremium / 100)).round();

      final payload = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'price': weekdayPrice,
        'weekendPremium': weekendPremium,
        'weekendPrice': weekendPrice,
        'description': _descriptionCtrl.text.trim(),
        'maxGuests': int.tryParse(_maxGuestsCtrl.text.trim()) ?? 1,
        'bedrooms': int.tryParse(_bedroomsCtrl.text.trim()) ?? 1,
        'beds': int.tryParse(_bedsCtrl.text.trim()) ?? 1,
        'bathrooms': int.tryParse(_bathroomsCtrl.text.trim()) ?? 1,
        'highlights': jsonEncode(_highlights),
        'amenities': jsonEncode(_amenities),
        'standoutAmenities': jsonEncode(_standoutAmenities),
        'safetyItems': jsonEncode(_safetyItems),
        'existingImages': jsonEncode(_existingImages),
        if (newImageFiles.isNotEmpty) 'images': newImageFiles,
        'residentialAddress': jsonEncode({
          'country': _countryCtrl.text.trim(),
          'street': _streetCtrl.text.trim(),
          'apt': _aptCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'province': _provinceCtrl.text.trim(),
          'postalCode': _postalCodeCtrl.text.trim(),
        }),
        'isPublished': _isPublished.toString(),
      });

      await api.put(ApiEndpoints.hostListingById(widget.listingId), data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stay updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Edit Stay'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewCard(
            title: _titleCtrl.text.trim().isEmpty ? 'Untitled Stay' : _titleCtrl.text.trim(),
            subtitle: _locationCtrl.text.trim().isEmpty ? 'Add location' : _locationCtrl.text.trim(),
          ),
          _section('Photos', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingImages.map((img) => Stack(
                      children: [
                        NivaasImage(imagePath: img, width: 88, height: 88, borderRadius: BorderRadius.circular(8)),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => setState(() => _existingImages.remove(img)),
                            child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                          ),
                        ),
                      ],
                    )),
                ..._newImages.map((img) => Stack(
                      children: [
                        Image.network(img.path, width: 88, height: 88, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => setState(() => _newImages.remove(img)),
                            child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                          ),
                        ),
                      ],
                    )),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
          ], subtitle: 'Manage your stay gallery'),
          _section('Title & Description', [
            _field(_titleCtrl, 'Title'),
            _field(_descriptionCtrl, 'Description', maxLines: 4),
          ], subtitle: 'How guests will see this stay'),
          _section('Location', [
            _field(_locationCtrl, 'Location'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Search on map / Use current location'),
              ),
            ),
          ], subtitle: 'Pinpoint where guests should arrive'),
          _section('Pricing', [
            Row(
              children: [
                Expanded(child: _field(_priceCtrl, 'Price (NPR)', isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _field(_weekendPremiumCtrl, 'Weekend %', isNumber: true)),
              ],
            ),
          ], subtitle: 'Set weekday and weekend pricing'),
          _section('Capacity', [
            Row(
              children: [
                Expanded(child: _field(_maxGuestsCtrl, 'Guests', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_bedroomsCtrl, 'Bedrooms', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_bedsCtrl, 'Beds', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_bathroomsCtrl, 'Baths', isNumber: true)),
              ],
            ),
          ], subtitle: 'Rooms and guest limits'),
          _section('Property Features', [
            _chips('Highlights', highlightOptions, _highlights),
            _chips('Amenities', amenityOptions, _amenities),
            _chips('Standout Amenities', standoutOptions, _standoutAmenities),
            _chips('Safety Items', safetyOptions, _safetyItems),
          ], subtitle: 'Help guests understand what stands out'),
          _section('Residential Address', [
            _field(_countryCtrl, 'Country'),
            _field(_streetCtrl, 'Street'),
            _field(_aptCtrl, 'Apt/Floor/Bldg'),
            _field(_cityCtrl, 'City'),
            _field(_provinceCtrl, 'Province'),
            _field(_postalCodeCtrl, 'Postal Code'),
          ], subtitle: 'Street-level address information'),
          _section('Publishing', [
            Row(
              children: [
                const Text('Published'),
                const SizedBox(width: 8),
                Switch(
                  value: _isPublished,
                  activeThumbColor: primaryOrange,
                  onChanged: (v) => setState(() => _isPublished = v),
                )
              ],
            ),
          ], subtitle: 'Control listing visibility'),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard({required String title, required String subtitle}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFF1EA),
            child: Icon(Icons.home_work_outlined, color: primaryOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children, {String? subtitle}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool isNumber = false, int maxLines = 1}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: primaryOrange, width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _chips(String title, List<String> options, List<String> selected) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((item) => FilterChip(
                      label: Text(item.replaceAll('_', ' ')),
                      selected: selected.contains(item),
                      selectedColor: const Color(0xFFFFE7DC),
                      checkmarkColor: primaryOrange,
                      side: BorderSide(
                        color: selected.contains(item)
                            ? primaryOrange
                            : colorScheme.outline.withOpacity(0.45),
                      ),
                      onSelected: (_) => _toggle(selected, item),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class HostEditExperienceScreen extends StatefulWidget {
  final String experienceId;
  const HostEditExperienceScreen({super.key, required this.experienceId});

  @override
  State<HostEditExperienceScreen> createState() => _HostEditExperienceScreenState();
}

class _HostEditExperienceScreenState extends State<HostEditExperienceScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);
  final _picker = ImagePicker();

  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _yearsCtrl = TextEditingController(text: '0');
  final _maxGuestsCtrl = TextEditingController(text: '1');
  final _descriptionCtrl = TextEditingController();

  final _countryCtrl = TextEditingController(text: 'Nepal');
  final _streetCtrl = TextEditingController();
  final _aptCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  final List<Map<String, TextEditingController>> _itineraryCtrls = [];
  final List<DateTime> _availableDates = [];
  List<String> _existingImages = [];
  final List<XFile> _newImages = [];

  double _latitude = 27.7172;
  double _longitude = 85.3240;
  bool _isPublished = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _yearsCtrl.dispose();
    _maxGuestsCtrl.dispose();
    _descriptionCtrl.dispose();
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

  Future<void> _load() async {
    try {
      final api = ApiClient();
      final res = await api.get(ApiEndpoints.hostExperienceById(widget.experienceId));
      final exp = (res.data['experience'] ?? {}) as Map<String, dynamic>;

      _titleCtrl.text = (exp['title'] ?? '').toString();
      _categoryCtrl.text = (exp['category'] ?? '').toString();
      _locationCtrl.text = (exp['location'] ?? '').toString();
      _priceCtrl.text = (exp['price'] ?? 0).toString();
      _durationCtrl.text = (exp['duration'] ?? '').toString();
      _yearsCtrl.text = (exp['yearsOfExperience'] ?? 0).toString();
      _maxGuestsCtrl.text = (exp['maxGuests'] ?? 1).toString();
      _descriptionCtrl.text = (exp['description'] ?? '').toString();
      _latitude = (exp['latitude'] is num) ? (exp['latitude'] as num).toDouble() : 27.7172;
      _longitude = (exp['longitude'] is num) ? (exp['longitude'] as num).toDouble() : 85.3240;
      _isPublished = exp['isPublished'] == true;
      _existingImages = List<String>.from(exp['images'] ?? []);

      final itinerary = List<Map<String, dynamic>>.from(exp['itinerary'] ?? []);
      if (itinerary.isNotEmpty) {
        for (final item in itinerary) {
          _itineraryCtrls.add({
            'title': TextEditingController(text: (item['title'] ?? '').toString()),
            'duration': TextEditingController(text: (item['duration'] ?? '').toString()),
            'description': TextEditingController(text: (item['description'] ?? '').toString()),
          });
        }
      } else {
        _itineraryCtrls.add({
          'title': TextEditingController(),
          'duration': TextEditingController(text: '1 hr'),
          'description': TextEditingController(),
        });
      }

      final dates = List.from(exp['availableDates'] ?? []);
      _availableDates
        ..clear()
        ..addAll(
          dates
              .map((d) => DateTime.tryParse(d.toString()))
              .whereType<DateTime>()
              .map((d) => DateTime(d.year, d.month, d.day)),
        );

      final addr = (exp['residentialAddress'] is Map<String, dynamic>)
          ? exp['residentialAddress'] as Map<String, dynamic>
          : <String, dynamic>{};
      _countryCtrl.text = (addr['country'] ?? 'Nepal').toString();
      _streetCtrl.text = (addr['street'] ?? '').toString();
      _aptCtrl.text = (addr['apt'] ?? '').toString();
      _cityCtrl.text = (addr['city'] ?? '').toString();
      _provinceCtrl.text = (addr['province'] ?? '').toString();
      _postalCodeCtrl.text = (addr['postalCode'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load experience: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    setState(() => _newImages.addAll(files));
  }

  Future<void> _pickLocation() async {
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
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final date = DateTime(picked.year, picked.month, picked.day);
    if (_availableDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day)) {
      return;
    }
    setState(() {
      _availableDates.add(date);
      _availableDates.sort((a, b) => a.compareTo(b));
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and location are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ApiClient();
      final newImageFiles = <MultipartFile>[];
      for (final file in _newImages) {
        newImageFiles.add(await MultipartFile.fromFile(file.path, filename: file.name));
      }

      final itinerary = _itineraryCtrls
          .map((item) => {
                'title': item['title']!.text.trim(),
                'duration': item['duration']!.text.trim(),
                'description': item['description']!.text.trim(),
              })
          .where((item) => (item['title'] ?? '').isNotEmpty)
          .toList();

      final payload = FormData.fromMap({
        'title': _titleCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0,
        'duration': _durationCtrl.text.trim(),
        'yearsOfExperience': int.tryParse(_yearsCtrl.text.trim()) ?? 0,
        'maxGuests': int.tryParse(_maxGuestsCtrl.text.trim()) ?? 1,
        'description': _descriptionCtrl.text.trim(),
        'existingImages': jsonEncode(_existingImages),
        if (newImageFiles.isNotEmpty) 'images': newImageFiles,
        'itinerary': jsonEncode(itinerary),
        'availableDates': jsonEncode(
          _availableDates
              .map((d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}')
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
        'isPublished': _isPublished.toString(),
      });

      await api.put(ApiEndpoints.hostExperienceById(widget.experienceId), data: payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Experience updated'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryOrange)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Edit Experience'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewCard(
            title: _titleCtrl.text.trim().isEmpty ? 'Untitled Experience' : _titleCtrl.text.trim(),
            subtitle: _locationCtrl.text.trim().isEmpty ? 'Add location' : _locationCtrl.text.trim(),
          ),
          _section('Photos', [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingImages.map((img) => Stack(
                      children: [
                        NivaasImage(imagePath: img, width: 88, height: 88, borderRadius: BorderRadius.circular(8)),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => setState(() => _existingImages.remove(img)),
                            child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                          ),
                        ),
                      ],
                    )),
                ..._newImages.map((img) => Stack(
                      children: [
                        Image.network(img.path, width: 88, height: 88, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () => setState(() => _newImages.remove(img)),
                            child: const CircleAvatar(radius: 10, child: Icon(Icons.close, size: 12)),
                          ),
                        ),
                      ],
                    )),
                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add'),
                ),
              ],
            ),
          ], subtitle: 'Manage your experience gallery'),
          _section('Title & Description', [
            _field(_titleCtrl, 'Title'),
            _field(_descriptionCtrl, 'Description', maxLines: 4),
          ], subtitle: 'How guests will discover this experience'),
          _section('Category & Location', [
            _field(_categoryCtrl, 'Category'),
            _field(_locationCtrl, 'Location'),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Search on map / Use current location'),
              ),
            ),
          ], subtitle: 'Core details and meeting point'),
          _section('Pricing & Capacity', [
            Row(
              children: [
                Expanded(child: _field(_priceCtrl, 'Price (NPR)', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_durationCtrl, 'Duration')),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field(_yearsCtrl, 'Years Exp', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_maxGuestsCtrl, 'Max Guests', isNumber: true)),
              ],
            ),
          ], subtitle: 'Pricing, duration and guest limits'),
          _section('Itinerary', [
            ...List.generate(_itineraryCtrls.length, (index) {
              final item = _itineraryCtrls[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.45)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    _field(item['title']!, 'Activity Title'),
                    _field(item['duration']!, 'Duration'),
                    _field(item['description']!, 'Description', maxLines: 2),
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
                      )
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _itineraryCtrls.add({
                    'title': TextEditingController(),
                    'duration': TextEditingController(text: '1 hr'),
                    'description': TextEditingController(),
                  });
                }),
                icon: const Icon(Icons.add),
                label: const Text('Add activity'),
              ),
            ),
          ], subtitle: 'Plan the guest journey step by step'),
          _section('Available Dates', [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Choose dates guests can book'),
                TextButton.icon(onPressed: _pickDate, icon: const Icon(Icons.add), label: const Text('Add')),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableDates
                  .map((d) => Chip(
                        label: Text('${d.day}/${d.month}/${d.year}'),
                        onDeleted: () => setState(() => _availableDates.remove(d)),
                      ))
                  .toList(),
            ),
          ], subtitle: 'Set when this experience can be booked'),
          _section('Residential Address', [
            _field(_countryCtrl, 'Country'),
            _field(_streetCtrl, 'Street'),
            _field(_aptCtrl, 'Apt/Floor/Bldg'),
            _field(_cityCtrl, 'City'),
            _field(_provinceCtrl, 'Province'),
            _field(_postalCodeCtrl, 'Postal Code'),
          ], subtitle: 'Street-level address information'),
          _section('Publishing', [
            Row(
              children: [
                const Text('Published'),
                const SizedBox(width: 8),
                Switch(
                  value: _isPublished,
                  activeThumbColor: primaryOrange,
                  onChanged: (v) => setState(() => _isPublished = v),
                )
              ],
            ),
          ], subtitle: 'Control experience visibility'),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: primaryOrange),
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewCard({required String title, required String subtitle}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFF1EA),
            child: Icon(Icons.celebration_outlined, color: primaryOrange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children, {String? subtitle}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool isNumber = false, int maxLines = 1}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: primaryOrange, width: 1.2),
          ),
        ),
      ),
    );
  }
}
