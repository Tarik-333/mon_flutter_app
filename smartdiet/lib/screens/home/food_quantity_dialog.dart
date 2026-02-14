
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class FoodQuantityDialog extends StatefulWidget {
  final Map<String, dynamic> food;

  const FoodQuantityDialog({super.key, required this.food});

  @override
  State<FoodQuantityDialog> createState() => _FoodQuantityDialogState();
}

class _FoodQuantityDialogState extends State<FoodQuantityDialog> {
  late TextEditingController _quantityController;
  late double _baseCalories;
  late double _baseProtein;
  late double _baseCarbs;
  late double _baseFat;
  
  double _calculatedCalories = 0;
  double _calculatedProtein = 0;
  double _calculatedCarbs = 0;
  double _calculatedFat = 0;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: '100');
    
    // Safety check for nulls
    _baseCalories = (widget.food['calories'] as num?)?.toDouble() ?? 0;
    _baseProtein = (widget.food['protein'] as num?)?.toDouble() ?? 0;
    _baseCarbs = (widget.food['carbs'] as num?)?.toDouble() ?? 0;
    _baseFat = (widget.food['fat'] as num?)?.toDouble() ?? 0;
    
    _calculateMacros();
  }

  void _calculateMacros() {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    // Assuming base stats are per 100g. 
    // Ideally we should check widget.food['serving_unit'] or similar if available.
    // For now, assuming 100g base.
    final ratio = quantity / 100.0;
    
    setState(() {
      _calculatedCalories = _baseCalories * ratio;
      _calculatedProtein = _baseProtein * ratio;
      _calculatedCarbs = _baseCarbs * ratio;
      _calculatedFat = _baseFat * ratio;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.food['name'] ?? 'Aliment',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Valeurs pour 100g : ${_baseCalories.toInt()} kcal',
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            
            // Quantity Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantité',
                      suffixText: 'g',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => _calculateMacros(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Calculated Macros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroItem('Kcal', _calculatedCalories, AppTheme.primaryColor),
                  _buildMacroItem('Prot', _calculatedProtein, AppTheme.accentColor),
                  _buildMacroItem('Glu', _calculatedCarbs, Colors.blue),
                  _buildMacroItem('Lip', _calculatedFat, Colors.orange),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Annuler', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final quantity = double.tryParse(_quantityController.text) ?? 100;
                      // Return a map with calculated values and quantity
                      final result = {
                        'name': widget.food['name'],
                        'quantity': quantity,
                        'unit': 'g',
                        'calories': _calculatedCalories,
                        'protein': _calculatedProtein,
                        'carbs': _calculatedCarbs,
                        'fat': _calculatedFat,
                      };
                      Navigator.pop(context, result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Ajouter', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          value.toInt().toString(),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
