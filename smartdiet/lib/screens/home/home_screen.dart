import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'recipe_detail_screen.dart';
import 'add_meal_form.dart';
import 'search_food_screen.dart';
import '../scan_food_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  double _caloriesConsumed = 0;
  double _caloriesGoal = 2000;
  double _protein = 0;
  double _carbs = 0;
  double _fat = 0;

  int? _userId;
  String _userName = 'Utilisateur'; // Default name
  List<dynamic> _historyMeals = [];
  List<dynamic> _todayMeals = [];
  bool _isHistoryLoading = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // 1. Get User Info
    try {
      final user = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _userId = user['id'] as int?;
        _userName = user['name'] as String? ?? 'Utilisateur';
      });
      
      // Check for new account notification (created_at is today)
      _checkNewAccountNotification(user['created_at']);
      
    } catch (_) {
      // Keep default if failed
    }

    // 2. Fetch Today's Meals for Dashboard
    await _fetchTodayMeals();

    // 3. Fetch History for "Repas" tab
    _fetchHistoryMeals();
  }

  void _checkNewAccountNotification(String? createdAtStr) {
    if (createdAtStr == null) return;
    try {
      final createdAt = DateTime.parse(createdAtStr);
      final now = DateTime.now();
      // If created within the last 24 hours
      if (now.difference(createdAt).inHours < 24) {
         // Could show a specific welcome dialog or just ensure the bell has the dot (which is static currently)
      }
    } catch (_) {}
  }

  Future<void> _fetchTodayMeals() async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    try {
      final data = await ApiService.getMealsByDate(dateStr);
      if (!mounted) return;
      
      final meals = data['meals'] as List<dynamic>;
      final stats = data['stats'] as Map<String, dynamic>;

      setState(() {
        _todayMeals = meals;
        // Update totals from backend stats directly if available, or calculate
        _caloriesConsumed = (stats['total_calories'] as num?)?.toDouble() ?? 0;
        _protein = (stats['total_protein'] as num?)?.toDouble() ?? 0;
        _carbs = (stats['total_carbs'] as num?)?.toDouble() ?? 0;
        _fat = (stats['total_fat'] as num?)?.toDouble() ?? 0;
      });
    } catch (e) {
      print('Error fetching today meals: $e');
    }
  }

  Future<void> _fetchHistoryMeals() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });

    try {
      final meals = await ApiService.getMeals();
      if (!mounted) return;
      setState(() {
        _historyMeals = meals;
        _isHistoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isHistoryLoading = false;
        _historyError = e.toString();
      });
    }
  }

  // No longer needed as we use backend stats for today
  void _recalculateTotals() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _getPage(_currentIndex),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.easeOut),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              _fabController.forward().then((_) => _fabController.reverse());
              _showAddMealModal();
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add_rounded, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildMealsPage();
      case 2:
        return _buildAIAssistantPage();
      case 3:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 30),
          _buildCaloriesCard(),
          const SizedBox(height: 30),
          _buildMacrosSection(),
          const SizedBox(height: 30),
          _buildMealsSection(),
          const SizedBox(height: 30),
          _buildHealthTipsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour 👋',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userName,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textPrimary,
                size: 26,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaloriesCard() {
    final percentage = _caloriesConsumed / _caloriesGoal;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calories du jour',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Objectif',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _caloriesConsumed.toInt().toString(),
                style: GoogleFonts.poppins(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 6),
                child: Text(
                  '/ ${_caloriesGoal.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('kcal', style: GoogleFonts.poppins(fontSize: 16, color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 24),
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Encore ${(_caloriesGoal - _caloriesConsumed).toInt()} kcal disponibles',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Macronutriments', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _buildMacroCard('Protéines', _protein, 80, 'g', AppTheme.accentColor, Icons.fitness_center_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildMacroCard('Glucides', _carbs, 250, 'g', AppTheme.primaryColor, Icons.bakery_dining_rounded)),
            const SizedBox(width: 14),
            Expanded(child: _buildMacroCard('Lipides', _fat, 60, 'g', AppTheme.warningColor, Icons.water_drop_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildMacroCard(String label, double current, double goal, String unit, Color color, IconData icon) {
    final percentage = (current / goal).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('${(percentage * 100).toInt()}%', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 14),
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              children: [
                TextSpan(text: '${current.toInt()}'),
                TextSpan(text: '/${goal.toInt()}$unit', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.normal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Repas du jour', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScanFoodScreen()),
                    );
                  },
                ),
                TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: Text('Voir tout', style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        const SizedBox(height: 18),
        _buildDynamicMealCard('Petit déjeuner', Icons.wb_sunny_rounded, const Color(0xFFFFA726)),
        const SizedBox(height: 14),
        _buildDynamicMealCard('Déjeuner', Icons.wb_twilight_rounded, AppTheme.accentColor),
        const SizedBox(height: 14),
        _buildDynamicMealCard('Dîner', Icons.nightlight_round, AppTheme.primaryColor),
        const SizedBox(height: 14),
        _buildDynamicMealCard('Snack', Icons.cookie_rounded, AppTheme.secondaryColor),
      ],
    );
  }

  Widget _buildDynamicMealCard(String mealType, IconData icon, Color color) {
    // Find meal in _todayMeals
    // Note: This logic assumes only ONE meal per type for simplicity in this card view, 
    // or we just show the first one found. The user requirement implies slots.
    final meal = _todayMeals.firstWhere(
      (m) => (m['meal_type'] as String? ?? '').toLowerCase() == mealType.toLowerCase(),
      orElse: () => <String, dynamic>{}, // Return empty map if not found
    );

    final bool hasFood = meal.isNotEmpty;
    // Capitalize first letter
    final String title = mealType.substring(0, 1).toUpperCase() + mealType.substring(1);
    final String calories = hasFood ? '${(meal['calories'] as num).toInt()} kcal' : 'Non ajouté';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasFood ? color.withOpacity(0.2) : AppTheme.textSecondary.withOpacity(0.1), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(calories, style: GoogleFonts.poppins(fontSize: 14, color: hasFood ? color : AppTheme.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          InkWell(
            onTap: () {
               // Open modal with pre-selected type
               // We need to update _showAddMealModal signature first or handle it here
               // For now, let's just assume we'll update it later
              _showAddMealModal(initialType: mealType.toLowerCase());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasFood ? AppTheme.successColor.withOpacity(0.1) : AppTheme.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasFood ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                color: hasFood ? AppTheme.successColor : AppTheme.textSecondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conseil du jour', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 6),
                Text('Buvez 500ml d\'eau maintenant !', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.95), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAssistantPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.aiGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Assistant IA',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'À venir...',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Nous travaillons sur des fonctionnalités intelligentes pour vous aider à atteindre vos objectifs',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsPage() {
    if (_isHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_historyError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text('Impossible de charger les repas', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_historyError!, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchHistoryMeals,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_historyMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text('Aucun historique', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // Group meals by date
    final Map<String, List<dynamic>> groupedMeals = {};
    for (var meal in _historyMeals) {
      final date = meal['date'] as String? ?? 'Inconnu';
      if (!groupedMeals.containsKey(date)) {
        groupedMeals[date] = [];
      }
      groupedMeals[date]!.add(meal);
    }

    final dates = groupedMeals.keys.toList();
    // Sort dates descending if needed, but backend already sorts by created_at desc. 
    // Assuming 'date' string matches sort order or relies on backend order.
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final mealsForDate = groupedMeals[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                   Container(
                     width: 4, 
                     height: 24, 
                     decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(4)),
                   ),
                   const SizedBox(width: 8),
                   Text(
                     _formatDate(date),
                     style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                   ),
                   const Expanded(child: Divider(indent: 12, height: 1)),
                ],
              ),
            ),
            
            // Meals List
            ...mealsForDate.map((meal) {
              final name = meal['name'] ?? 'Repas';
              final mealType = meal['meal_type'] ?? 'repas';
              final calories = (meal['calories'] as num?)?.toDouble() ?? 0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.textSecondary.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            '${mealType.toString().toUpperCase()} • $calories kcal',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr == 'Inconnu') return dateStr;
    try {
      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final yesterdayDate = now.subtract(const Duration(days: 1));
      final yesterday = '${yesterdayDate.year}-${yesterdayDate.month.toString().padLeft(2, '0')}-${yesterdayDate.day.toString().padLeft(2, '0')}';

      if (dateStr == today) return "Aujourd'hui";
      if (dateStr == yesterday) return "Hier";
      
      // Parse YYYY-MM-DD to DD/MM/YYYY
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildProfilePage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person, size: 80, color: AppTheme.primaryColor),
          const SizedBox(height: 20),
          Text('Page Profil', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('À venir...', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 8,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Accueil', 0),
            _buildNavItem(Icons.restaurant_outlined, Icons.restaurant_rounded, 'Repas', 1),
            const SizedBox(width: 48),
            _buildNavItem(Icons.psychology_outlined, Icons.psychology_rounded, 'IA', 2),
            _buildNavItem(Icons.person_outline, Icons.person_rounded, 'Profil', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMealModal({String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ajouter un repas',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            _buildAddMealOption(
              'Scanner un aliment',
              'Utilise la caméra pour identifier',
              Icons.camera_alt_rounded,
              AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            _buildAddMealOption(
              'Rechercher un aliment',
              'Cherche dans la base de données',
              Icons.search_rounded,
              AppTheme.secondaryColor,
            ),
            const SizedBox(height: 16),
            _buildAddMealOption(
              'Entrée manuelle',
              'Ajoute les valeurs manuellement',
              Icons.edit_rounded,
              AppTheme.accentColor,
              initialType: initialType,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAddMealOption(
      String title,
      String subtitle,
      IconData icon,
      Color color, {
      String? initialType,
      }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (title == 'Entrée manuelle') {
          _showManualMealForm(initialMealType: initialType);
          return;
        }
        if (title == 'Rechercher un aliment') {
          // Ouvrir l'écran de recherche
          // On attend un résultat pour ouvrir le formulaire
          // Note: On ne peut pas facilement ouvrir le formulaire depuis ici car le bottom sheet est fermé.
          // On va réouvrir le formulaire manuellement.
          
          await Future.delayed(const Duration(milliseconds: 100)); // Petit délai pour laisser le bottom sheet fermer
          
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchFoodScreen()),
          );
          
          if (result != null && result is Map<String, dynamic>) {
            _showManualMealForm(initialValues: result);
          }
          return;
        }
        
        // Scanner un aliment
        if (title == 'Scanner un aliment') {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const ScanFoodScreen()),
          );
          
          // If meal was added via scan, refresh the meals list
          if (result == true) {
            await _fetchMeals();
          }
          return;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fonctionnalité "$title" sélectionnée'),
            backgroundColor: color,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualMealForm({Map<String, dynamic>? initialValues, String? initialMealType}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return AddMealForm(
          userId: _userId,
          initialValues: initialValues,
          initialMealType: initialMealType,
          onMealAdded: () {
            // Optionnel : si on veut réagir immédiatement, mais on attend le résultat du pop
          },
        );
      },
    );

    if (result == true) {
      await _fetchMeals();
    }
  }
  Future<void> _fetchMeals() async {
    await _fetchTodayMeals();
    await _fetchHistoryMeals();
  }
}
