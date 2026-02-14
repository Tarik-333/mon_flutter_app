import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'search_food_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealType;
  final String date;
  final int userId;

  const MealDetailScreen({
    super.key,
    required this.mealType,
    required this.date,
    required this.userId,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  List<dynamic> _foods = [];
  bool _isLoading = true;
  double _totalCalories = 0;

  @override
  void initState() {
    super.initState();
    _fetchMealDetails();
  }

  Future<void> _fetchMealDetails() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getMealsByDate(widget.date);
      final allMeals = data['meals'] as List<dynamic>;
      
      // Filter for this meal type
      final mealFoods = allMeals.where((m) => 
        (m['meal_type'] as String? ?? '').toLowerCase() == widget.mealType.toLowerCase()
      ).toList();

      double total = 0;
      for (var food in mealFoods) {
        total += (food['calories'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _foods = mealFoods;
          _totalCalories = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _navigateToAddFood() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchFoodScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      _addFoodToMeal(result);
    }
  }

  Future<void> _addFoodToMeal(Map<String, dynamic> foodData) async {
    try {
      await ApiService.addMeal(
        userId: widget.userId,
        name: foodData['name'],
        mealType: widget.mealType,
        calories: (foodData['calories'] as num).toDouble(),
        protein: (foodData['protein'] as num).toDouble(),
        carbs: (foodData['carbs'] as num).toDouble(),
        fat: (foodData['fat'] as num).toDouble(),
        quantity: (foodData['quantity'] as num).toDouble(),
        unit: foodData['unit'] ?? 'g',
        date: widget.date,
        time: TimeOfDay.now().format(context),
      );
      
      _fetchMealDetails(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur ajout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.mealType.substring(0, 1).toUpperCase() + widget.mealType.substring(1);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context, true), // Return true to trigger refresh
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Calories', style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${_totalCalories.toInt()} kcal', 
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 30),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Aliments', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_foods.length} items', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              
              Expanded(
                child: _foods.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.no_food_outlined, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Aucun aliment ajouté', style: GoogleFonts.poppins(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _foods.length,
                      itemBuilder: (context, index) {
                        final food = _foods[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.fastfood, color: AppTheme.primaryColor, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(food['name'] ?? 'Aliment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(food['quantity'] as num?)?.toInt() ?? 100}${(food['unit'] ?? 'g')} • ${(food['calories'] as num).toInt()} kcal',
                                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              // IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade300), onPressed: () {}), // TODO: Implement delete
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddFood,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: Text('Ajouter un aliment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
