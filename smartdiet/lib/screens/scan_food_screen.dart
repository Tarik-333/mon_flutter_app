import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartdiet/services/api_service.dart';
import 'home/add_meal_form.dart';

class ScanFoodScreen extends StatefulWidget {
  const ScanFoodScreen({super.key});

  @override
  State<ScanFoodScreen> createState() => _ScanFoodScreenState();
}

class _ScanFoodScreenState extends State<ScanFoodScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final user = await ApiService.getMe();
      setState(() {
        _userId = user['id'] as int?;
      });
    } catch (_) {
      // User ID not available
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _result = null; // Reset previous result
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.recognizeFood(_image!);
      
      if (!mounted) return;
      
      setState(() {
        _result = result;
      });

      // If food is recognized and has nutritional info, navigate to form
      if (result['is_recognized'] == true && result['nutritional_info'] != null) {
        final nutritionalInfo = result['nutritional_info'] as Map<String, dynamic>;
        
        // Wait a moment to show the success message
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (!mounted) return;
        
        // Show the meal form with initial values (scan screen still visible in background)
        final mealAdded = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return AddMealForm(
              userId: _userId,
              initialValues: {
                'name': result['food_name'] ?? 'Aliment',
                'calories': nutritionalInfo['calories'] ?? 0,
                'protein': nutritionalInfo['protein'] ?? 0,
                'carbs': nutritionalInfo['carbs'] ?? 0,
                'fat': nutritionalInfo['fat'] ?? 0,
              },
              onMealAdded: () {},
            );
          },
        );
        
        // After meal form is closed, close scan screen and return result
        if (!mounted) return;
        Navigator.pop(context, mealAdded == true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un Aliment 📸'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera),
                  label: const Text('Caméra'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galerie'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Analyze Button
            if (_image != null)
              ElevatedButton(
                onPressed: _isLoading ? null : _analyzeImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'ANALYSER L\'ALIMENT',
                        style: TextStyle(fontSize: 18, color: Colors.black),
                      ),
              ),

            // Result Area
            if (_result != null) ...[
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                color: _result!['is_recognized'] == true
                    ? Colors.green[50]
                    : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _result!['is_recognized'] == true
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 50,
                        color: _result!['is_recognized'] == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _result!['is_recognized'] == true
                            ? "Aliment reconnu ! ✅"
                            : "Aliment non reconnu",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      if (_result!['is_recognized'] == true) ...[
                        Text(
                          "${_result!['food_name']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Confiance: ${_result!['confidence']}%",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Redirection vers le formulaire...",
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Veuillez réessayer avec une autre photo ou saisir manuellement.",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
