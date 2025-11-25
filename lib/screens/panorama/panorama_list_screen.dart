import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image/image.dart' as img;
import 'panorama_view_screen.dart';
import 'package:dlsud_go/models/campus_location.dart';
// desktop_drop import is no longer needed

class PanoramaListScreen extends StatefulWidget {
  const PanoramaListScreen({super.key});

  @override
  State<PanoramaListScreen> createState() => _PanoramaListScreenState();
}

class _PanoramaListScreenState extends State<PanoramaListScreen> {
  final supabase = Supabase.instance.client;
  bool _isUploading = false;
  String _uploadStatus = '';
  Map<String, String> _locationPanoramaUrls = {}; // Cache for location panoramas
  // bool _dragging = false; // State for desktop_drop removed

  @override
  void initState() {
    super.initState();
    _loadPanoramaUrls();
  }

  // The _handleDroppedFiles function is no longer needed

  // Load all panorama URLs from Firebase
  Future<void> _loadPanoramaUrls() async {
    try {
      final urls = await CampusLocation.loadAllPanoramaUrls();
      setState(() {
        _locationPanoramaUrls = urls;
      });
    } catch (e) {
      print('Error loading panorama URLs: $e');
    }
  }

  Future<File> _stitchImagesHorizontally(List<File> imageFiles) async {
    // For 360° panoramas, we need 2:1 aspect ratio (width:height)
    // Limit height to avoid memory issues
    const maxHeight = 1536; // Conservative height for memory
    const overlapPercentage = 0.05; // 5% overlap between images

    final images = <img.Image>[];

    for (var file in imageFiles) {
      final bytes = await file.readAsBytes();
      // Use img.decodeImage which handles various formats including WebP, JPEG, and PNG
      var image = img.decodeImage(bytes);

      if (image != null) {
        // Resize if too large
        if (image.height > maxHeight) {
          final scale = maxHeight / image.height;
          final newWidth = (image.width * scale).round();
          image = img.copyResize(image, width: newWidth, height: maxHeight);
        }

        images.add(image);
      }

      // Force garbage collection between images
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (images.isEmpty) throw Exception('No valid images to stitch');

    // Calculate dimensions with overlap
    final targetHeight = images.first.height;

    // Calculate total width with overlap
    int totalWidth = images.first.width;
    for (int i = 1; i < images.length; i++) {
      final overlapPixels = (images[i].width * overlapPercentage).round();
      totalWidth += images[i].width - overlapPixels;
    }

    final stitchHeight = targetHeight;
    final stitchWidth = totalWidth;

    // Create blank canvas
    final stitched = img.Image(width: stitchWidth, height: stitchHeight);
    img.fill(stitched, color: img.ColorRgb8(0, 0, 0));

    // Paste images side by side with overlap
    int xOffset = 0;
    for (int i = 0; i < images.length; i++) {
      final image = images[i];

      // Resize to match stitch height if needed
      final resized = image.height != stitchHeight
          ? img.copyResize(image, height: stitchHeight)
          : image;

      // Apply blend for overlapping region
      if (i > 0) {
        // Calculate overlap region
        final overlapPixels = (resized.width * overlapPercentage).round();

        // Composite with alpha blending in overlap region
        for (int y = 0; y < resized.height; y++) {
          for (int x = 0; x < resized.width; x++) {
            final dstX = xOffset + x;
            if (dstX >= 0 && dstX < stitched.width && y < stitched.height) {
              final pixel = resized.getPixel(x, y);

              // Apply gradient alpha in overlap region
              if (x < overlapPixels) {
                final alpha = x / overlapPixels;
                final existingPixel = stitched.getPixel(dstX, y);

                final blendedR = ((1 - alpha) * existingPixel.r + alpha * pixel.r).round();
                final blendedG = ((1 - alpha) * existingPixel.g + alpha * pixel.g).round();
                final blendedB = ((1 - alpha) * existingPixel.b + alpha * pixel.b).round();

                stitched.setPixel(dstX, y, img.ColorRgb8(blendedR, blendedG, blendedB));
              } else {
                stitched.setPixel(dstX, y, pixel);
              }
            }
          }
        }
      } else {
        // First image, no blending needed
        img.compositeImage(stitched, resized, dstX: xOffset, dstY: 0);
      }

      // Calculate next offset with overlap
      if (i < images.length - 1) {
        final overlapPixels = (resized.width * overlapPercentage).round();
        xOffset += resized.width - overlapPixels;
      }

      // Clear from memory
      images[i] = img.Image(width: 1, height: 1);
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Save to temporary file with JPEG compression
    final tempDir = Directory.systemTemp;
    final stitchedFile = File('${tempDir.path}/stitched_${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Encode as JPEG with quality setting (70 for better compression)
    await stitchedFile.writeAsBytes(
        img.encodeJpg(stitched, quality: 70)
    );

    return stitchedFile;
  }

  Future<void> _pickAndUploadImage() async {
    // --- CHANGE: Added 'webp' to the allowed extensions ---
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
    );

    if (result == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Preparing images...';
    });

    final collectionId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Convert picked files to File objects
      final imageFiles = result.files.map((f) => File(f.path!)).toList();

      setState(() => _uploadStatus = 'Stitching ${imageFiles.length} images...');

      // Stitch images together
      final stitchedFile = await _stitchImagesHorizontally(imageFiles);

      setState(() => _uploadStatus = 'Uploading panorama...');

      // Upload stitched panorama as JPEG
      final fileName = "panorama_stitched_$collectionId.jpg";
      await supabase.storage.from("panoramas").upload(
        fileName,
        stitchedFile,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );

      final publicUrl = supabase.storage.from("panoramas").getPublicUrl(fileName);

      print('✓ Uploaded: $fileName');
      print('✓ Public URL: $publicUrl');

      // Save to database (only using existing columns)
      try {
        final response = await supabase.from("panoramas").insert({
          "image_url": publicUrl,
          "file_name": fileName,
          "collection_id": collectionId,
        }).select();

        print('✓ Database insert response: $response');
        print('✓ Saved to database with collection_id: $collectionId');
      } catch (dbError) {
        print('❌ Database insert failed: $dbError');
        throw Exception('Database insert failed: $dbError');
      }

      // Clean up temp file
      await stitchedFile.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ Created 360° panorama from ${imageFiles.length} images!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
    }
  }

  Future<void> _deleteCollection(String collectionId, List<String> fileNames) async {
    try {
      await supabase.storage.from("panoramas").remove(fileNames);
      await supabase.from("panoramas").delete().eq("collection_id", collectionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Panorama deleted")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }

  Future<void> _assignPanoramaToLocation(String locationId, String locationName, String panoramaUrl) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Saving to Firebase...';
      });

      // Save the panorama URL to Firebase for the specific location
      await CampusLocation.savePanoramaUrl(locationId, panoramaUrl);

      // Update local cache
      setState(() {
        _locationPanoramaUrls[locationId] = panoramaUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✓ Panorama assigned to $locationName"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      print('✓ Panorama URL saved to Firebase for location: $locationId');
      print('✓ Location name: $locationName');
      print('✓ URL: $panoramaUrl');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to assign panorama: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ Failed to save to Firebase: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadStatus = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        label: Text(_isUploading ? _uploadStatus : "Add Panorama"),
        icon: _isUploading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.add_photo_alternate),
      ),
      // --- CHANGE: DropTarget wrapper removed ---
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from("panoramas")
            .stream(primaryKey: ["id"])
            .order("collection_id", ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.panorama, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No panoramas yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap + to upload multiple images",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Group by collection_id
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (var item in items) {
            final collectionId = item["collection_id"];
            grouped.putIfAbsent(collectionId, () => []);
            grouped[collectionId]!.add(item);
          }

          final collections = grouped.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              final collectionId = collection.first["collection_id"];
              final coverImage = collection.first["image_url"];
              final imageCount = collection.length;
              final allFileNames = collection.map((e) => e["file_name"] as String).toList();

              // Check if this panorama is assigned to any location
              final assignedLocation = _locationPanoramaUrls.entries
                  .where((entry) => entry.value == coverImage)
                  .map((entry) => entry.key)
                  .firstOrNull;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Pass only the stitched image URL
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PanoramaViewScreen(
                          imageUrl: coverImage,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: coverImage,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                          // Show badge if assigned to a location
                          if (assignedLocation != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      CampusLocation.allLocations
                                          .firstWhere((loc) => loc.id == assignedLocation)
                                          .name
                                          .split(' ')
                                          .take(2)
                                          .join(' '),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "360° Panorama",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$imageCount image${imageCount > 1 ? 's' : ''} • Optimized JPEG",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (assignedLocation != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "Assigned to: ${CampusLocation.allLocations.firstWhere((loc) => loc.id == assignedLocation).name}",
                                      style: TextStyle(
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Delete Panorama?"),
                                    content: const Text("This action cannot be undone."),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _deleteCollection(collectionId, allFileNames);
                                }
                              },
                            ),
                            // IconButton(
                            //   icon: Icon(
                            //     assignedLocation != null ? Icons.edit_location : Icons.location_on,
                            //     color: assignedLocation != null ? Colors.green : Colors.blue,
                            //   ),
                            //   tooltip: assignedLocation != null
                            //       ? "Change Location"
                            //       : "Set to Campus Location",
                            //   onPressed: () async {
                            //     final selected = await showDialog<CampusLocation>(
                            //       context: context,
                            //       builder: (context) => AlertDialog(
                            //         title: const Text("Select Campus Location"),
                            //         content: SizedBox(
                            //           width: double.maxFinite,
                            //           height: 300,
                            //           child: ListView(
                            //             children: CampusLocation.allLocations.map((location) {
                            //               final isCurrentlyAssigned = assignedLocation == location.id;
                            //               final hasOtherPanorama = _locationPanoramaUrls[location.id] != null &&
                            //                   !isCurrentlyAssigned;
                            //
                            //               return ListTile(
                            //                 title: Text(location.name),
                            //                 subtitle: Text(location.description),
                            //                 trailing: isCurrentlyAssigned
                            //                     ? const Icon(Icons.check_circle, color: Colors.green)
                            //                     : hasOtherPanorama
                            //                     ? const Icon(Icons.warning, color: Colors.orange)
                            //                     : null,
                            //                 onTap: () => Navigator.pop(context, location),
                            //               );
                            //             }).toList(),
                            //           ),
                            //         ),
                            //       ),
                            //     );
                            //
                            //     if (selected != null) {
                            //       // Check if location already has a panorama
                            //       final existingUrl = _locationPanoramaUrls[selected.id];
                            //       if (existingUrl != null && existingUrl != coverImage) {
                            //         final replace = await showDialog<bool>(
                            //           context: context,
                            //           builder: (context) => AlertDialog(
                            //             title: const Text("Replace Existing Panorama?"),
                            //             content: Text(
                            //               "${selected.name} already has a panorama assigned. Do you want to replace it?",
                            //             ),
                            //             actions: [
                            //               TextButton(
                            //                 onPressed: () => Navigator.pop(context, false),
                            //                 child: const Text("Cancel"),
                            //               ),
                            //               TextButton(
                            //                 onPressed: () => Navigator.pop(context, true),
                            //                 child: const Text("Replace"),
                            //               ),
                            //             ],
                            //           ),
                            //         );
                            //         if (replace != true) return;
                            //       }
                            //
                            //       // Assign panorama to the selected location
                            //       await _assignPanoramaToLocation(
                            //         selected.id,
                            //         selected.name,
                            //         coverImage,
                            //       );
                            //     }
                            //   },
                            // ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}