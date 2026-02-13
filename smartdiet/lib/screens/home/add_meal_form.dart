import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class AddMealForm extends StatefulWidget {
  final int? userId;
  final Function() onMealAdded;
  final Map<String, dynamic>? initialValues; // ✅ Ajout

  const AddMealForm({
    super.key,
    required this.userId,
    required this.onMealAdded,
    this.initialValues,
    this.initialMealType, // New parameter
  });

  final String? initialMealType;

  @override
  State<AddMealForm> createState() => _AddMealFormState();
}

class _AddMealFormState extends State<AddMealForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  String _mealType = 'déjeuner';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValues != null) {
      _nameController.text = widget.initialValues!['name'] ?? '';
      _caloriesController.text = (widget.initialValues!['calories'] ?? '').toString();
      _proteinController.text = (widget.initialValues!['protein'] ?? '').toString();
      _carbsController.text = (widget.initialValues!['carbs'] ?? '').toString();
      _fatController.text = (widget.initialValues!['fat'] ?? '').toString();
    }
    if (widget.initialMealType != null) {
      _mealType = widget.initialMealType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil utilisateur indisponible.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final now = DateTime.now();
    final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    try {
      await ApiService.addMeal(
        userId: widget.userId!,
        name: _nameController.text,
        mealType: _mealType,
        calories: double.parse(_caloriesController.text),
        protein: double.parse(_proteinController.text),
        carbs: double.parse(_carbsController.text),
        fat: double.parse(_fatController.text),
        date: date,
        time: time,
      );

      if (!mounted) return;
      
      Navigator.pop(context, true); // Return true to indicate success
      widget.onMealAdded();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repas ajouté avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handling keyboard obstruction
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ajouter un repas', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du repas'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _mealType,
                items: const [
                  DropdownMenuItem(value: 'petit-déjeuner', child: Text('Petit-déjeuner')),
                  DropdownMenuItem(value: 'déjeuner', child: Text('Déjeuner')),
                  DropdownMenuItem(value: 'dîner', child: Text('Dîner')),
                  DropdownMenuItem(value: 'snack', child: Text('Snack')),
                ],
                onChanged: (value) => setState(() => _mealType = value ?? 'déjeuner'),
                decoration: const InputDecoration(labelText: 'Type de repas'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: 'Protéines (g)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _carbsController,
                decoration: const InputDecoration(labelText: 'Glucides (g)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fatController,
                decoration: const InputDecoration(labelText: 'Lipides (g)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
