import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'food_quantity_dialog.dart';

class SearchFoodScreen extends StatefulWidget {
  const SearchFoodScreen({super.key});

  @override
  State<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load default foods
    _performSearch('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    // Allow empty query to fetch default list
    // if (query.trim().isEmpty) { ... }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await ApiService.searchFoods(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  void _onFoodSelected(Map<String, dynamic> food) async {
    // Show quantity dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FoodQuantityDialog(food: food),
    );

    if (result != null && mounted) {
      // Return the result to the caller (MealDetailScreen)
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Rechercher un aliment',
          style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pomme, riz, poulet...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          
          if (_error != null)
             Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(child: Text('Erreur: $_error', style: const TextStyle(color: Colors.red))),
            ),
            
          Expanded(
            child: ListView.separated(
              itemCount: _searchResults.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                return ListTile(
                  title: Text(item['name'] ?? '', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text('${(item['calories'] as num?)?.toInt()} kcal / 100g • ${item['category'] ?? ''}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                  onTap: () => _onFoodSelected(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
