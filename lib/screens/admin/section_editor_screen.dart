// lib/screens/admin/section_editor_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/dashboard_section.dart';
import '../../widgets/common/custom_button.dart';

// TODO: Update this import to your actual admin dashboard screen path
import 'admin_dashboard.dart';

class SectionEditorScreen extends StatefulWidget {
  final DashboardSection? section; // null for new section

  const SectionEditorScreen({super.key, this.section});

  @override
  State<SectionEditorScreen> createState() => _SectionEditorScreenState();
}

class _SubsectionEditor {
  TextEditingController titleController;
  List<TextEditingController> descriptionControllers;
  String selectedIcon;

  _SubsectionEditor({
    String title = '',
    List<dynamic> descriptions = const [],
    this.selectedIcon = 'info', // default subsection icon
  })  : titleController = TextEditingController(text: title),
        descriptionControllers = descriptions
            .map((d) => TextEditingController(text: d.toString()))
            .toList();

  void dispose() {
    titleController.dispose();
    for (var controller in descriptionControllers) {
      controller.dispose();
    }
  }
}

class _SectionEditorScreenState extends State<SectionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<_SubsectionEditor> _subsectionEditors;

  String _selectedIcon = 'school';
  String _selectedColor = '#00563F';
  String _selectedRoute = 'static_info';
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _availableIcons = [
    {'name': 'school', 'icon': Icons.school},
    {'name': 'map', 'icon': Icons.map},
    {'name': 'groups', 'icon': Icons.groups},
    {'name': 'info', 'icon': Icons.info},
    {'name': 'book', 'icon': Icons.book},
    {'name': 'event', 'icon': Icons.event},
    {'name': 'sports', 'icon': Icons.sports},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'local_library', 'icon': Icons.local_library},
    {'name': 'science', 'icon': Icons.science},
    {'name': 'computer', 'icon': Icons.computer},
    {'name': 'language', 'icon': Icons.language},
  ];

  final List<Map<String, String>> _availableColors = [
    {'name': 'Green', 'hex': '#00563F'},
    {'name': 'Blue', 'hex': '#0066CC'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Purple', 'hex': '#9C27B0'},
    {'name': 'Red', 'hex': '#F44336'},
    {'name': 'Teal', 'hex': '#009688'},
  ];

  final List<Map<String, String>> _availableRoutes = [
    {'name': 'Static Info Screen', 'value': 'static_info'},
    {'name': 'Map Navigation', 'value': 'map_navigation'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.section?.description ?? '');

    if (widget.section != null) {
      _selectedIcon = widget.section!.iconName;
      _selectedColor = widget.section!.colorHex;
      _selectedRoute = widget.section!.route;
      _isActive = widget.section!.isActive;
      _subsectionEditors = widget.section!.subsections.map((s) {
        return _SubsectionEditor(
          title: s['title'] ?? '',
          descriptions: s['descriptions'] ?? [],
          selectedIcon: s['iconName'] ?? 'info',
        );
      }).toList();
    } else {
      _subsectionEditors = [];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var editor in _subsectionEditors) {
      editor.dispose();
    }
    super.dispose();
  }

  void _addSubsection() {
    setState(() {
      _subsectionEditors.add(_SubsectionEditor());
    });
  }

  void _removeSubsection(int index) {
    setState(() {
      _subsectionEditors[index].dispose();
      _subsectionEditors.removeAt(index);
    });
  }

  void _addDescription(int subsectionIndex) {
    setState(() {
      _subsectionEditors[subsectionIndex]
          .descriptionControllers
          .add(TextEditingController());
    });
  }

  void _removeDescription(int subsectionIndex, int descriptionIndex) {
    setState(() {
      _subsectionEditors[subsectionIndex]
          .descriptionControllers[descriptionIndex]
          .dispose();
      _subsectionEditors[subsectionIndex]
          .descriptionControllers
          .removeAt(descriptionIndex);
    });
  }

  Future<void> _saveSection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final subsectionsData = _subsectionEditors.map((editor) {
      return {
        'title': editor.titleController.text,
        'iconName': editor.selectedIcon,
        'descriptions': editor.descriptionControllers
            .map((c) => c.text)
            .where((d) => d.isNotEmpty)
            .toList(),
      };
    }).where((s) {
      final title = s['title'] as String;
      final descriptions = s['descriptions'] as List<String>;
      return title.isNotEmpty || descriptions.isNotEmpty;
    }).toList();

    final sectionData = DashboardSection(
      id: widget.section?.id ?? '',
      title: _titleController.text,
      description: _descriptionController.text,
      iconName: _selectedIcon,
      colorHex: _selectedColor,
      route: _selectedRoute,
      subsections: _selectedRoute == 'static_info' ? subsectionsData : [],
      isActive: _isActive,
      order: widget.section?.order ??
          (await FirebaseFirestore.instance
              .collection('dashboard_sections')
              .get())
              .size,
    );

    try {
      final collection =
      FirebaseFirestore.instance.collection('dashboard_sections');
      if (widget.section == null) {
        await collection.add(sectionData.toMap());
      } else {
        await collection.doc(widget.section!.id).update(sectionData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Section saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving section: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.section == null ? 'Add Section' : 'Edit Section',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const AdminDashboard()),
            );
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // TITLE
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
              value == null || value.isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // DESCRIPTION
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter a description'
                  : null,
            ),

            const SizedBox(height: 16),

            // ICON SELECTOR
            const Text('Icon *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((iconData) {
                final isSelected = _selectedIcon == iconData['name'];
                return ChoiceChip(
                  label: Icon(iconData['icon'] as IconData, size: 24),
                  selected: isSelected,
                  onSelected: (selected) =>
                      setState(() => _selectedIcon = iconData['name'] as String),
                  selectedColor: AppColors.primaryGreen.withAlpha(77),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // COLOR SELECTOR
            const Text('Color *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((colorData) {
                final color =
                Color(int.parse(colorData['hex']!.replaceAll('#', '0xFF')));
                final isSelected = _selectedColor == colorData['hex'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(colorData['name']!),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) =>
                      setState(() => _selectedColor = colorData['hex']!),
                  selectedColor: color.withAlpha(77),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // ROUTE SELECTOR
            DropdownButtonFormField<String>(
              value: _selectedRoute,
              decoration: const InputDecoration(
                labelText: 'Navigation Route *',
                border: OutlineInputBorder(),
              ),
              items: _availableRoutes.map((route) {
                return DropdownMenuItem(
                  value: route['value'],
                  child: Text(route['name']!),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedRoute = value ?? 'static_info'),
            ),

            if (_selectedRoute == 'static_info') ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subsections',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: _addSubsection,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Add Subsection'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_subsectionEditors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No subsections yet. Add one above.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ..._buildSubsectionFields(),
            ],

            const SizedBox(height: 16),

            // ACTIVE TOGGLE
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Show this section in the app'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),

            const SizedBox(height: 24),

            // PREVIEW
            const Text('Preview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildPreview(),

            const SizedBox(height: 24),

            // SAVE BUTTON
            CustomButton(
              text: _isSaving ? 'Saving...' : 'Save Section',
              onPressed: _isSaving ? null : _saveSection,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSubsectionFields() {
    return _subsectionEditors.asMap().entries.map((entry) {
      final index = entry.key;
      final editor = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: editor.titleController,
                      decoration: InputDecoration(
                        labelText: 'Subsection ${index + 1} Title',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    onPressed: () => _removeSubsection(index),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Subsection Icon',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableIcons.map((iconData) {
                  final isSelected = editor.selectedIcon == iconData['name'];
                  return ChoiceChip(
                    label: Icon(iconData['icon'] as IconData, size: 22),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          editor.selectedIcon = iconData['name'] as String;
                        });
                      }
                    },
                    selectedColor: AppColors.primaryGreen.withAlpha(77),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              const Text('Details',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              ...editor.descriptionControllers.asMap().entries.map((descEntry) {
                final descIndex = descEntry.key;
                final descController = descEntry.value;

                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: descController,
                          decoration: InputDecoration(
                            labelText: 'Detail ${descIndex + 1}',
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () =>
                            _removeDescription(index, descIndex),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _addDescription(index),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Detail'),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPreview() {
    final color = Color(int.parse(_selectedColor.replaceAll('#', '0xFF')));
    final icon = _availableIcons.firstWhere(
          (i) => i['name'] == _selectedIcon,
      orElse: () => _availableIcons[0],
    )['icon'] as IconData;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withAlpha(204),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleController.text.isEmpty
                        ? 'Title'
                        : _titleController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text.isEmpty
                        ? 'Description'
                        : _descriptionController.text,
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
