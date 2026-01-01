import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/drm_service.dart';
import '../models/location_data.dart';
import '../../../core/theme/app_theme.dart';

/// DRM Form Screen with cascading location dropdowns and image upload
class DrmScreen extends StatefulWidget {
  const DrmScreen({super.key});

  @override
  State<DrmScreen> createState() => _DrmScreenState();
}

class _DrmScreenState extends State<DrmScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  // Selected location values
  District? _selectedDistrict;
  County? _selectedCounty;
  SubCounty? _selectedSubCounty;
  Parish? _selectedParish;
  PollingStation? _selectedPollingStation;

  // Selected image
  File? _selectedImage;

  // Loading and submission state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DrmService>().initialize();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _submitForm() async {
    if (_selectedDistrict == null ||
        _selectedCounty == null ||
        _selectedSubCounty == null ||
        _selectedParish == null ||
        _selectedPollingStation == null ||
        _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select an image'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final drmService = context.read<DrmService>();

      await drmService.createSubmission(
        district: _selectedDistrict!,
        county: _selectedCounty!,
        subCounty: _selectedSubCounty!,
        parish: _selectedParish!,
        pollingStation: _selectedPollingStation!,
        imageFile: _selectedImage!,
      );

      // Reset form
      setState(() {
        _selectedImage = null;
        // Keep location selections to allow quick consecutive submissions
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              drmService.isOnline
                  ? 'Submission saved and uploading...'
                  : 'Submission cached. Will upload when online.',
            ),
            backgroundColor: drmService.isOnline
                ? AppColors.success
                : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearSelection(int level) {
    setState(() {
      switch (level) {
        case 0: // District changed
          _selectedCounty = null;
          _selectedSubCounty = null;
          _selectedParish = null;
          _selectedPollingStation = null;
          break;
        case 1: // County changed
          _selectedSubCounty = null;
          _selectedParish = null;
          _selectedPollingStation = null;
          break;
        case 2: // SubCounty changed
          _selectedParish = null;
          _selectedPollingStation = null;
          break;
        case 3: // Parish changed
          _selectedPollingStation = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DrmService>(
      builder: (context, drmService, child) {
        if (drmService.isLoadingData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading location data...'),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection status banner
              if (!drmService.isOnline)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: AppColors.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Offline mode: Forms will be cached and synced when connected',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Pending submissions indicator
              if (drmService.pendingCount > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (drmService.isSyncing)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.navyBlue,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        drmService.isSyncing
                            ? 'Syncing ${drmService.pendingCount} submission(s)...'
                            : '${drmService.pendingCount} submission(s) pending',
                        style: TextStyle(color: AppColors.navyBlue),
                      ),
                    ],
                  ),
                ),

              Text(
                'DR Forms Submission',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select location and upload the DRM form image',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // District dropdown
              _buildDropdown<District>(
                label: 'District',
                value: _selectedDistrict,
                items: drmService.getDistricts(),
                onChanged: (val) {
                  setState(() => _selectedDistrict = val);
                  _clearSelection(0);
                },
                itemLabel: (d) => d.name,
              ),
              const SizedBox(height: 16),

              // County dropdown
              _buildDropdown<County>(
                label: 'County',
                value: _selectedCounty,
                items: _selectedDistrict != null
                    ? drmService.getCounties(_selectedDistrict!.code)
                    : [],
                onChanged: (val) {
                  setState(() => _selectedCounty = val);
                  _clearSelection(1);
                },
                itemLabel: (c) => c.name,
                enabled: _selectedDistrict != null,
              ),
              const SizedBox(height: 16),

              // Sub-County dropdown
              _buildDropdown<SubCounty>(
                label: 'Sub-County',
                value: _selectedSubCounty,
                items: (_selectedDistrict != null && _selectedCounty != null)
                    ? drmService.getSubCounties(
                        _selectedDistrict!.code,
                        _selectedCounty!.code,
                      )
                    : [],
                onChanged: (val) {
                  setState(() => _selectedSubCounty = val);
                  _clearSelection(2);
                },
                itemLabel: (sc) => sc.name,
                enabled: _selectedCounty != null,
              ),
              const SizedBox(height: 16),

              // Parish dropdown
              _buildDropdown<Parish>(
                label: 'Parish',
                value: _selectedParish,
                items:
                    (_selectedDistrict != null &&
                        _selectedCounty != null &&
                        _selectedSubCounty != null)
                    ? drmService.getParishes(
                        _selectedDistrict!.code,
                        _selectedCounty!.code,
                        _selectedSubCounty!.code,
                      )
                    : [],
                onChanged: (val) {
                  setState(() => _selectedParish = val);
                  _clearSelection(3);
                },
                itemLabel: (p) => p.name,
                enabled: _selectedSubCounty != null,
              ),
              const SizedBox(height: 16),

              // Polling Station dropdown
              _buildDropdown<PollingStation>(
                label: 'Polling Station',
                value: _selectedPollingStation,
                items:
                    (_selectedDistrict != null &&
                        _selectedCounty != null &&
                        _selectedSubCounty != null &&
                        _selectedParish != null)
                    ? drmService.getPollingStations(
                        _selectedDistrict!.code,
                        _selectedCounty!.code,
                        _selectedSubCounty!.code,
                        _selectedParish!.code,
                      )
                    : [],
                onChanged: (val) =>
                    setState(() => _selectedPollingStation = val),
                itemLabel: (ps) =>
                    ps.name.isNotEmpty ? ps.name : 'Station ${ps.code}',
                enabled: _selectedParish != null,
              ),
              const SizedBox(height: 24),

              // Image section
              Text(
                'DR Form Image',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _selectedImage = null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Theme.of(context).disabledColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Image picker buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit DR Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled
              ? () => _showSearchableDropdown<T>(
                  label: label,
                  items: items,
                  itemLabel: itemLabel,
                  onSelected: onChanged,
                  currentValue: value,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? itemLabel(value)
                        : (enabled
                              ? 'Select $label'
                              : 'Select ${label.toLowerCase()} above first'),
                    style: TextStyle(
                      color: value != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: enabled
                      ? Theme.of(context).iconTheme.color
                      : Theme.of(context).disabledColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableDropdown<T>({
    required String label,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onSelected,
    T? currentValue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchableDropdownSheet<T>(
        label: label,
        items: items,
        itemLabel: itemLabel,
        onSelected: (value) {
          Navigator.pop(context);
          onSelected(value);
        },
        currentValue: currentValue,
      ),
    );
  }
}

/// Searchable dropdown bottom sheet
class _SearchableDropdownSheet<T> extends StatefulWidget {
  final String label;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T) onSelected;
  final T? currentValue;

  const _SearchableDropdownSheet({
    required this.label,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
    this.currentValue,
  });

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where(
              (item) => widget.itemLabel(item).toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Select ${widget.label}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ${widget.label.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              autofocus: true,
            ),
          ),
          const SizedBox(height: 8),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredItems.length} ${widget.label.toLowerCase()}(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),

          // Items list
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No results found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = widget.currentValue == item;

                      return ListTile(
                        title: Text(
                          widget.itemLabel(item),
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () => widget.onSelected(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
