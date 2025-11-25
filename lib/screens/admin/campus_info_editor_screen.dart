// Updated CampusInfoEditorScreen implementing Option B
// This version supports:
// • Section Title
// • Section Description
// • List of detail items per section

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class CampusInfoEditorScreen extends StatefulWidget {
  const CampusInfoEditorScreen({super.key});

  @override
  State<CampusInfoEditorScreen> createState() => _CampusInfoEditorScreenState();
}

class _CampusInfoEditorScreenState extends State<CampusInfoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _buttonTextController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isActive = true;

  List<_SectionData> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadCampusInfo();
  }

  Future<void> _loadCampusInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('campus_info')
          .doc('main')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _titleController.text = data['title'] ?? '';
        _subtitleController.text = data['subtitle'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _buttonTextController.text = data['button_text'] ?? '';
        _isActive = data['is_active'] ?? true;

        final loadedSections = List<Map<String, dynamic>>.from(data['button_sections'] ?? []);
        _sections = loadedSections.map((section) {
          return _SectionData(
            title: TextEditingController(text: section['title'] ?? ''),
            description: TextEditingController(text: section['description'] ?? ''),
            details: (section['details'] as List<dynamic>? ?? [])
                .map((d) => TextEditingController(text: d.toString()))
                .toList(),
          );
        }).toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _buttonTextController.dispose();

    for (var s in _sections) {
      s.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Edit Campus Information Card',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          _buildTextField(_titleController, 'Title *'),
          const SizedBox(height: 16),
          _buildTextField(_descriptionController, 'Description', maxLines: 4),
          const SizedBox(height: 16),
          _buildTextField(_buttonTextController, 'Button Text'),

          const SizedBox(height: 24),
          _buildSectionsEditor(),

          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),

          const SizedBox(height: 24),

          CustomButton(
            text: _isSaving ? 'Saving...' : 'Save Changes',
            onPressed: _isSaving ? null : _saveCampusInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
      validator: (value) => (label.contains('*') && (value == null || value.isEmpty))
          ? 'This field is required'
          : null,
    );
  }

  Widget _buildSectionsEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Button Sections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add),
              label: const Text('Add Section'),
            )
          ],
        ),

        if (_sections.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No sections yet.'),
          ),

        ..._sections.asMap().entries.map((entry) => _buildSectionCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildSectionCard(int index, _SectionData data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Section ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeSection(index),
                ),
              ],
            ),

            _buildTextField(data.title, 'Section Title'),
            const SizedBox(height: 12),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Items', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _addDetailItem(data),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Detail'),
                ),
              ],
            ),

            ...data.details.asMap().entries.map((entry) => _buildDetailField(data, entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailField(_SectionData section, int i, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: _buildTextField(c, 'Detail ${i + 1}')),
          IconButton(
            onPressed: () => setState(() => section.details.removeAt(i)),
            icon: const Icon(Icons.delete, color: Colors.red),
          )
        ],
      ),
    );
  }

  void _addSection() {
    setState(() {
      _sections.add(_SectionData.empty());
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections[index].dispose();
      _sections.removeAt(index);
    });
  }

  void _addDetailItem(_SectionData section) {
    setState(() {
      section.details.add(TextEditingController());
    });
  }

  Future<void> _saveCampusInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final sectionsPayload = _sections.map((s) {
        return {
          'title': s.title.text,
          'description': s.description.text,
          'details': s.details.map((d) => d.text).where((t) => t.isNotEmpty).toList(),
        };
      }).toList();

      await FirebaseFirestore.instance.collection('campus_info').doc('main').set({
        'title': _titleController.text,
        'subtitle': _subtitleController.text,
        'description': _descriptionController.text,
        'button_text': _buttonTextController.text,
        'button_sections': sectionsPayload,
        'is_active': _isActive,
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Campus info updated.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }
}

class _SectionData {
  TextEditingController title;
  TextEditingController description;
  List<TextEditingController> details;

  _SectionData({
    required this.title,
    required this.description,
    required this.details,
  });

  factory _SectionData.empty() {
    return _SectionData(
      title: TextEditingController(),
      description: TextEditingController(),
      details: [],
    );
  }

  void dispose() {
    title.dispose();
    description.dispose();
    for (var d in details) {
      d.dispose();
    }
  }
}