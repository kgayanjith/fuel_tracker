import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuel_tracker/screens/generators.dart';
import 'package:fuel_tracker/screens/map_location_picker.dart';
import 'package:fuel_tracker/screens/report_preview_screen.dart';
import '../widgets/appbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../widgets/dialogs.dart';

class GeneratorView extends StatefulWidget {
  final Map<String, dynamic> data;

  const GeneratorView({super.key, required this.data});

  @override
  State<GeneratorView> createState() => _GeneratorViewState();
}

class _GeneratorViewState extends State<GeneratorView> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late String _selectedLocation;
  double? _selectedLat;
  double? _selectedLng;
  bool _imageDeleted = false;
  bool _isSaving = false;

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _usageController;

  bool get _hasImage =>
      _selectedImage != null ||
      (!_imageDeleted &&
          widget.data['imagePath'] != null &&
          widget.data['imagePath'].toString().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.data['name']?.toString() ?? '',
    );
    _codeController = TextEditingController(
      text: widget.data['code']?.toString() ?? '',
    );
    _capacityController = TextEditingController(
      text: widget.data['fuelCapacity']?.toString() ?? '',
    );
    _usageController = TextEditingController(
      text: widget.data['fuelUsage']?.toString() ?? '',
    );
    _selectedLocation =
        widget.data['location']?.toString() ?? 'Select Location';
    _selectedLat = (widget.data['latitude'] as num?)?.toDouble();
    _selectedLng = (widget.data['longitude'] as num?)?.toDouble();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _capacityController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() {
        _selectedImage = File(image.path);
        _imageDeleted = false;
      });
    }
  }

  void _deleteImage() {
    setState(() {
      _selectedImage = null;
      _imageDeleted = true;
    });
  }

  /// If a new image was picked, copies it into permanent local storage and
  /// returns the new path. If the image was deleted, returns null. If
  /// nothing changed, returns the existing stored path.
  Future<String?> _resolveImagePath() async {
    if (_imageDeleted && _selectedImage == null) {
      return null;
    }

    if (_selectedImage != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${const Uuid().v4()}${path.extension(_selectedImage!.path)}';
      final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');
      return savedImage.path;
    }

    return widget.data['imagePath'] as String?;
  }

  bool _isGeneratingReport = false;

  Future<void> _generateReport() async {
    setState(() => _isGeneratingReport = true);
    try {
      final reportData = {
        'generatorId': widget.data['id'],
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'location': _selectedLocation,
        'fuelCapacity': double.tryParse(_capacityController.text.trim()),
        'fuelUsage': double.tryParse(_usageController.text.trim()),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('reports')
          .add(reportData);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportPreviewScreen(
            data: {
              ...reportData,
              'id': docRef.id,
              'createdAt': DateTime.now(), // local stand-in until synced
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showMessageDialog(
        context,
        title: 'Error',
        message: 'Failed to generate report: $e',
      );
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Future<void> _saveChanges() async {
    final docId = widget.data['id'] as String?;
    if (docId == null) {
      showMessageDialog(
        context,
        title: 'Error',
        message: 'Missing record id, cannot save',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final imagePath = await _resolveImagePath();

      await FirebaseFirestore.instance
          .collection('generators')
          .doc(docId)
          .update({
            'name': _nameController.text.trim(),
            'code': _codeController.text.trim(),
            'fuelCapacity': double.tryParse(_capacityController.text.trim()),
            'fuelUsage': double.tryParse(_usageController.text.trim()),
            'location': _selectedLocation,
            'latitude': _selectedLat,
            'longitude': _selectedLng,
            'imagePath': imagePath,
          });

      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const GeneratorsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(-1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: Curves.easeInOut));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showMessageDialog(
        context,
        title: 'Error',
        message: 'Failed to save changes: $e',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImagePath = widget.data['imagePath'] as String?;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Generator View",
        leadingIconType: LeadingIconType.back,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
        onLeadingIconTap: () => Navigator.pop(context),
      ),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Name*",
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
                  controller: _nameController,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),

              SizedBox(height: 32),

              const Text(
                "Location*",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              GestureDetector(
                onTap: () async {
                  final result =
                      await Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => const MapLocationPicker(),
                        ),
                      );

                  if (result != null && mounted) {
                    setState(() {
                      _selectedLocation = result['address'];
                      _selectedLat = result['latitude'];
                      _selectedLng = result['longitude'];
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Colors.black38,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedLocation,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.black38,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),

              const Text(
                "Code*",
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
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),

              SizedBox(height: 32),
              const Text(
                "Fuel Capacity (L)*",
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
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 32),
              const Text(
                "Fuel Usage (L per hour)*",
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
                  controller: _usageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              SizedBox(height: 32),
              const Text(
                "Image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDDDDDD),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _imageDeleted
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.black26,
                              ),
                            )
                          : _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : (existingImagePath != null &&
                                existingImagePath.isNotEmpty &&
                                File(existingImagePath).existsSync())
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(existingImagePath),
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.black26,
                              ),
                            ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OutlinedButton(
                            onPressed: _hasImage ? _deleteImage : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _hasImage
                                  ? Colors.black
                                  : Colors.black26,
                              side: BorderSide(
                                color: _hasImage
                                    ? const Color(0xFFDDDDDD)
                                    : const Color(0xFFEEEEEE),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Delete Image",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton(
                            onPressed: _pickImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Upload Image",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _isGeneratingReport ? null : _generateReport,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: _isGeneratingReport
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Generate Report',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const GeneratorsScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0);
                                const end = Offset.zero;
                                final tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                        ),
                      ),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancle',
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
                          : () => showConfirmationGeneratorSave(
                              context,
                              onConfirm: _saveChanges,
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
              SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }
}

void showConfirmationGeneratorSave(
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
                child: const Icon(Icons.close, size: 22, color: Colors.black54),
              ),
            ),
            const Text(
              "Are you sure you want to save changes ?",
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
