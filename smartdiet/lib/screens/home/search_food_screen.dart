import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'add_meal_form.dart'; // Pour réutiliser le formulaire si besoin, ou on passera les data

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

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
    // food: {name: '...', calories: ..., category: ...}
    // On ouvre le formulaire AddMealForm pré-rempli
    
    // Note: Pour simplifier, on peut ouvrir le AddMealForm DEPUIS ici.
    // Il faut que AddMealForm accepte des valeurs initiales.
    
    // On va modifier AddMealForm juste après pour accepter des initialValues.
    // Pour l'instant, disons qu'on retourne le résultat à l'écran précédent qui gérera l'ouverture ?
    // Ou mieux, on ouvre le modal ici directement, c'est plus fluide.
    
    // Mais AddMealForm a besoin du userId. On ne l'a pas ici facilement sauf si on le passe
    // ou si on le récupère via getMe (déjà fait dans HomeScreen).
    
    // Pour faire simple : on retourne l'aliment sélectionné à HomeScreen
    Navigator.pop(context, food);
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
              onChanged: (val) {
                // Debounce simple possible ici, mais on va rester simple : search on submit
                // ou search si > 3 chars
              },
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
                  subtitle: Text('${item['calories']} kcal / 100g • ${item['category']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
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
