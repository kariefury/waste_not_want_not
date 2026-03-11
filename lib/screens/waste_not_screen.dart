import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pantry_item.dart';
import '../services/local_data_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class WasteNotScreen extends StatefulWidget {
  const WasteNotScreen({super.key});

  @override
  State<WasteNotScreen> createState() => _WasteNotScreenState();
}

class _WasteNotScreenState extends State<WasteNotScreen> {
  List<PantryItem> _myItems = [];
  bool _loading = true;
  String _neighbourhood = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalDataService.getMyContributions();
    try {
      final pos = await LocationService.getCurrentPosition();
      final name =
          await LocationService.getNeighbourhoodName(pos.latitude, pos.longitude);
      if (mounted) setState(() => _neighbourhood = name);
    } catch (_) {}
    if (mounted) setState(() { _myItems = items; _loading = false; });
  }

  Future<void> _addItem() async {
    final result = await Navigator.push<PantryItem>(
      context,
      MaterialPageRoute(builder: (_) => const _AddItemSheet()),
    );
    if (result != null) {
      await LocalDataService.addContribution(result);
      _load();
    }
  }

  Future<void> _removeItem(PantryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove "${item.name}" from the shared pantry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: AppTheme.terracotta))),
        ],
      ),
    );
    if (confirm == true) {
      await LocalDataService.removeContribution(item.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      appBar: AppBar(
        title: const Text('Waste Not'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: AppTheme.seedGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myItems.isEmpty
              ? _emptyState()
              : _itemList(),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.paleOlive,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 48, color: AppTheme.seedGreen),
            ),
            const SizedBox(height: 24),
            Text(
              'Your shared pantry is empty',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Add item" to share extra food\nwith your neighbours.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepBrown.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 500.ms),
      ),
    );
  }

  Widget _itemList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _myItems.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              _neighbourhood.isNotEmpty
                  ? 'Sharing in $_neighbourhood'
                  : 'Your contributions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.deepBrown.withOpacity(0.5),
                  ),
            ),
          );
        }
        final item = _myItems[index - 1];
        return _ContributionTile(
          item: item,
          onRemove: () => _removeItem(item),
        )
            .animate()
            .fadeIn(delay: (index * 60).ms, duration: 300.ms)
            .slideX(begin: 0.05, end: 0);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Contribution tile
// ─────────────────────────────────────────────────────────────────────
class _ContributionTile extends StatelessWidget {
  const _ContributionTile({required this.item, required this.onRemove});
  final PantryItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo or category emoji
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.paleOlive,
                borderRadius: BorderRadius.circular(14),
                image: item.photoPath != null && File(item.photoPath!).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(item.photoPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: item.photoPath == null || !File(item.photoPath!).existsSync()
                  ? Text(item.category.emoji,
                      style: const TextStyle(fontSize: 24))
                  : null,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${item.quantity} ${item.unit}  ·  ${item.category.label}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.deepBrown.withOpacity(0.6),
                        ),
                  ),
                  if (item.expiresBy != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Expires ${DateFormat.MMMd().format(item.expiresBy!)}',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.terracotta,
                              ),
                    ),
                  ],
                ],
              ),
            ),

            // Remove
            IconButton(
              icon: Icon(Icons.close_rounded,
                  color: AppTheme.deepBrown.withOpacity(0.3)),
              onPressed: onRemove,
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Add item full-screen form
// ─────────────────────────────────────────────────────────────────────
class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet();

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();

  FoodCategory _category = FoodCategory.produce;
  DateTime? _expiresBy;
  double _radiusKm = 3.0;
  Position? _position;
  bool _locating = true;
  String? _locationError;
  bool _skipLocation = false;
  File? _photo;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadAlias();
  }

  Future<void> _initLocation() async {
    if (mounted) setState(() { _locating = true; _locationError = null; });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) setState(() { _position = pos; _locating = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _locationError = e.toString();
        });
      }
    }
  }

  Future<void> _loadAlias() async {
    final alias = await LocalDataService.getAlias();
    if (alias != null && mounted) _aliasCtrl.text = alias;
  }

  Future<void> _pickExpiry() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) setState(() => _expiresBy = date);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;

      // Copy to app's permanent storage so the photo survives
      final appDir = await getApplicationDocumentsDirectory();
      final photoDir = Directory('${appDir.path}/photos');
      if (!await photoDir.exists()) await photoDir.create(recursive: true);
      final savedPath = '${photoDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await File(picked.path).copy(savedPath);

      if (mounted) setState(() => _photo = savedFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get photo: $e')),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.seedGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppTheme.seedGreen),
                ),
                title: const Text('Take a photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.terracotta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppTheme.terracotta),
                ),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              if (_photo != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400),
                  ),
                  title: const Text('Remove photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _photo = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_position == null && !_skipLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available — tap "Skip location" below to continue without it.'),
        ),
      );
      return;
    }

    // Save alias for future use
    await LocalDataService.setAlias(_aliasCtrl.text.trim());

    // Use real position or fallback to 0,0 (neighbourhood-level only)
    final double lat = _position?.latitude ?? 0.0;
    final double lng = _position?.longitude ?? 0.0;
    final snapped = LocationService.snapToGrid(lat, lng);

    final item = PantryItem(
      name: _nameCtrl.text.trim(),
      category: _category,
      quantity: int.tryParse(_qtyCtrl.text.trim()) ?? 1,
      unit: _unitCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      photoPath: _photo?.path,
      expiresBy: _expiresBy,
      contributorAlias:
          _aliasCtrl.text.trim().isEmpty ? 'A neighbour' : _aliasCtrl.text.trim(),
      pickupAddress: _addressCtrl.text.trim(),
      pickupInstructions: _instructionsCtrl.text.trim(),
      latitude: snapped.lat,
      longitude: snapped.lng,
      radiusKm: _radiusKm,
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      appBar: AppBar(
        title: const Text('Add to pantry'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Share',
                style: TextStyle(
                    color: AppTheme.seedGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Section: Photo ──────────────────────────────────
            GestureDetector(
              onTap: _showPhotoOptions,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: _photo != null ? 220 : 140,
                decoration: BoxDecoration(
                  color: AppTheme.warmCream,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _photo != null
                        ? AppTheme.seedGreen.withOpacity(0.3)
                        : AppTheme.deepBrown.withOpacity(0.1),
                    width: 1.5,
                  ),
                  image: _photo != null
                      ? DecorationImage(
                          image: FileImage(_photo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photo != null
                    // Photo overlay with change button
                    ? Stack(
                        children: [
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Change',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    // Empty state
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.seedGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 28, color: AppTheme.seedGreen),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Add a photo of your item',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.seedGreen),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Helps neighbours know what to expect',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.deepBrown.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Section: What ───────────────────────────────────
            _sectionTitle('What are you sharing?'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'e.g. Organic bananas'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),

            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: FoodCategory.values.map((cat) {
                final selected = cat == _category;
                return ChoiceChip(
                  label: Text('${cat.emoji} ${cat.label}'),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: AppTheme.seedGreen,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.deepBrown,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quantity + unit
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Qty'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return '1+';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unitCtrl,
                    decoration:
                        const InputDecoration(hintText: 'Unit (cans, kg, …)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Expiry
            InkWell(
              onTap: _pickExpiry,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.warmCream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 18,
                        color: AppTheme.deepBrown.withOpacity(0.5)),
                    const SizedBox(width: 12),
                    Text(
                      _expiresBy != null
                          ? 'Expires ${DateFormat.yMMMd().format(_expiresBy!)}'
                          : 'Add expiry date (optional)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _expiresBy != null
                                ? AppTheme.deepBrown
                                : AppTheme.deepBrown.withOpacity(0.4),
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration:
                  const InputDecoration(hintText: 'Notes (optional)'),
            ),

            const SizedBox(height: 28),

            // ── Section: Who ────────────────────────────────────
            _sectionTitle('Your alias'),
            const SizedBox(height: 4),
            Text(
              'No real names needed — keep it fun & anonymous.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepBrown.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _aliasCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Baker on 5th'),
            ),

            const SizedBox(height: 28),

            // ── Section: Where ──────────────────────────────────
            _sectionTitle('Pickup details'),
            const SizedBox(height: 4),
            Text(
              'Only shown to people who claim your item.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepBrown.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressCtrl,
              decoration:
                  const InputDecoration(hintText: 'Pickup address'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter an address'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instructionsCtrl,
              decoration: const InputDecoration(
                  hintText: 'Instructions (e.g. "on the porch")'),
            ),
            const SizedBox(height: 20),

            // Radius slider
            Row(
              children: [
                Text('Visible within',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('${_radiusKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.seedGreen,
                        )),
              ],
            ),
            Slider(
              value: _radiusKm,
              min: 0.5,
              max: 10,
              divisions: 19,
              activeColor: AppTheme.seedGreen,
              onChanged: (v) => setState(() => _radiusKm = v),
            ),

            // ── Location status panel ────────────────────────────
            if (_locating)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.honeyGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Getting your location…'),
                  ],
                ),
              )
            else if (_position != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.seedGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 18, color: AppTheme.seedGreen),
                    const SizedBox(width: 10),
                    Text('Location ready',
                        style: TextStyle(color: AppTheme.seedGreen)),
                  ],
                ),
              )
            else if (_skipLocation)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.honeyGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: AppTheme.honeyGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sharing without location — item will be visible to everyone.',
                        style: TextStyle(
                            color: AppTheme.deepBrown.withOpacity(0.7),
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              )
            else if (_locationError != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.terracotta.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_off_rounded,
                            size: 18, color: AppTheme.terracotta),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Could not get location',
                            style: TextStyle(
                              color: AppTheme.terracotta,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$_locationError',
                      style: TextStyle(
                        color: AppTheme.deepBrown.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _initLocation,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.seedGreen,
                              side: BorderSide(color: AppTheme.seedGreen),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _skipLocation = true),
                            icon: const Icon(Icons.skip_next_rounded, size: 16),
                            label: const Text('Skip location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.deepBrown.withOpacity(0.6),
                              side: BorderSide(
                                  color: AppTheme.deepBrown.withOpacity(0.2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: Theme.of(context).textTheme.headlineMedium);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    _addressCtrl.dispose();
    _instructionsCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }
}
