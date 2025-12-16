import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLocationsScreen extends StatefulWidget {
  const ManageLocationsScreen({super.key});

  @override
  State<ManageLocationsScreen> createState() => _ManageLocationsScreenState();
}

class _ManageLocationsScreenState extends State<ManageLocationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  String _selectedCategory = 'Clinic';
  String _selectedSection = 'east'; // Default section

  final List<String> _categories = ['Clinic', 'Building', 'Office', 'Food', 'Gate', 'Parking'];
  final List<String> _sections = ['east', 'west'];

  // --- CRUD FUNCTIONS ---

  Future<void> _addOrUpdateLocation({String? docId}) async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'section': _selectedSection, // Add section to data
        'latitude': double.parse(_latController.text.trim()),
        'longitude': double.parse(_longController.text.trim()),
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (docId == null) {
        // Add New
        data['created_at'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('locations').add(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Added!')));
      } else {
        // Update Existing
        await FirebaseFirestore.instance.collection('locations').doc(docId).update(data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Updated!')));
      }

      _clearForm();
      if (mounted) Navigator.pop(context); // Close dialog
    }
  }

  Future<void> _deleteLocation(String id) async {
    // Show confirmation dialog
    bool confirm = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Location?"),
          content: const Text("This cannot be undone."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
          ],
        )) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('locations').doc(id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Deleted!')));
    }
  }

  void _clearForm() {
    _nameController.clear();
    _latController.clear();
    _longController.clear();
    setState(() {
      _selectedCategory = 'Clinic';
      _selectedSection = 'east'; // Reset section
    });
  }

  void _showLocationDialog({String? docId, Map<String, dynamic>? existingData}) {
    // Pre-fill if editing
    if (existingData != null) {
      _nameController.text = existingData['name'];
      _latController.text = existingData['latitude'].toString();
      _longController.text = existingData['longitude'].toString();
      _selectedCategory = existingData['category'] ?? 'Clinic';
      _selectedSection = existingData['section'] ?? 'east'; // Pre-fill section
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(docId == null ? 'Add New Location' : 'Update Location'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Location Name (e.g., East Clinic)'),
                  validator: (val) => val!.isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _categories.contains(_selectedCategory) ? _selectedCategory : _categories.first,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 10),
                // Add Section Selection
                DropdownButtonFormField<String>(
                  value: _sections.contains(_selectedSection) ? _selectedSection : _sections.first,
                  decoration: const InputDecoration(labelText: 'Campus Section'),
                  items: _sections.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s == 'east' ? 'East Campus' : 'West Campus'),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedSection = val!),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(labelText: 'Latitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _longController,
                        decoration: const InputDecoration(labelText: 'Longitude'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  "Tip: Right-click a spot on Google Maps to get coordinates.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => _addOrUpdateLocation(docId: docId),
              child: Text(docId == null ? 'Save' : 'Update')
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Map Locations")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocationDialog(),
        child: const Icon(Icons.add_location_alt),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('locations').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No locations added yet."));
          }

          final docs = snapshot.data!.docs;

          // Group locations by section
          final eastLocations = docs.where((doc) => (doc.data() as Map<String, dynamic>)['section'] == 'east').toList();
          final westLocations = docs.where((doc) => (doc.data() as Map<String, dynamic>)['section'] == 'west').toList();
          final otherLocations = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['section'] != 'east' && data['section'] != 'west';
          }).toList();

          return ListView(
            children: [
              _buildSectionExpansionTile("East Campus", eastLocations),
              _buildSectionExpansionTile("West Campus", westLocations),
              if (otherLocations.isNotEmpty)
                _buildSectionExpansionTile("Other Locations", otherLocations),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionExpansionTile(String title, List<QueryDocumentSnapshot> locations) {
    if (locations.isEmpty) {
      return Card(
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("No locations in this section."),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: locations.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final id = doc.id;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(
                data['category'] == 'Clinic' ? Icons.medical_services : Icons.place,
                color: Colors.green,
              ),
            ),
            title: Text(data['name'] ?? 'Unknown'),
            subtitle: Text("${data['category']} • ${data['latitude']}, ${data['longitude']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // EDIT BUTTON
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showLocationDialog(docId: id, existingData: data),
                ),
                // DELETE BUTTON
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteLocation(id),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}