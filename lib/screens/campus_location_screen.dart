import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../models/campus_location.dart';

class CampusLocationEditorScreen extends StatefulWidget {
  final CampusLocation? location; // null for new location

  const CampusLocationEditorScreen({super.key, this.location});

  @override
  State<CampusLocationEditorScreen> createState() => _CampusLocationEditorScreenState();
}

class _CampusLocationEditorScreenState extends State<CampusLocationEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _panoramaController = TextEditingController();
  String _selectedIconName = 'info';
  final List<File> _newImages = [];
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      final loc = widget.location!;
      _nameController.text = loc.name;
      _descController.text = loc.description;
      _latitudeController.text = loc.latitude.toString();
      _longitudeController.text = loc.longitude.toString();
      _selectedIconName = loc.icon.toString();
      _existingImages = loc.imagePaths;
      _panoramaController.text = loc.panoramaUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _panoramaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _newImages.add(File(pickedFile.path)));
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final name = _nameController.text.trim();
      final desc = _descController.text.trim();
      final latitude = double.parse(_latitudeController.text.trim());
      final longitude = double.parse(_longitudeController.text.trim());
      final panoramaUrl = _panoramaController.text.trim().isEmpty
          ? null
          : _panoramaController.text.trim();

      final locData = {
        'name': name,
        'description': desc,
        'latitude': latitude,
        'longitude': longitude,
        'icon': _selectedIconName,
        'imagePaths': _existingImages, // For simplicity, keeping existing images only
        'panoramaUrl': panoramaUrl,
      };

      if (widget.location == null) {
        await FirebaseFirestore.instance.collection('campus_locations').add(locData);
      } else {
        await FirebaseFirestore.instance
            .collection('campus_locations')
            .doc(widget.location!.id)
            .update(locData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.location == null ? 'Add Location' : 'Edit Location'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val == null || val.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              // Latitude
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Enter latitude' : null,
              ),
              const SizedBox(height: 12),
              // Longitude
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: TextInputType.number,
                validator: (val) => val == null || val.isEmpty ? 'Enter longitude' : null,
              ),
              const SizedBox(height: 12),
              // Icon selector
              DropdownButtonFormField<String>(
                initialValue: _selectedIconName,
                items: const [
                  DropdownMenuItem(value: 'school', child: Text('School')),
                  DropdownMenuItem(value: 'map', child: Text('Map')),
                  DropdownMenuItem(value: 'groups', child: Text('Groups')),
                  DropdownMenuItem(value: 'info', child: Text('Info')),
                  DropdownMenuItem(value: 'book', child: Text('Book')),
                  DropdownMenuItem(value: 'event', child: Text('Event')),
                ],
                onChanged: (val) => setState(() => _selectedIconName = val ?? 'info'),
                decoration: const InputDecoration(labelText: 'Icon'),
              ),
              const SizedBox(height: 12),
              // Panorama URL
              TextFormField(
                controller: _panoramaController,
                decoration: const InputDecoration(labelText: 'Panorama URL (optional)'),
              ),
              const SizedBox(height: 12),
              // Images
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Images', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: _pickImage,
                  )
                ],
              ),
              Wrap(
                spacing: 8.0,
                children: [
                  for (var path in _existingImages)
                    Stack(
                      children: [
                        Image.network(path, width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _existingImages.remove(path));
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  for (var file in _newImages)
                    Stack(
                      children: [
                        Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _newImages.remove(file));
                            },
                            child: const Icon(Icons.close, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveLocation,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
