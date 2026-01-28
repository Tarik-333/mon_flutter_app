import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'recipe_detail_screen.dart';

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
  List<dynamic> _meals = [];
  bool _isMealsLoading = true;
  String? _mealsError;

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
    try {
      final user = await ApiService.getMe();
      _userId = user['id'] as int?;
    } catch (_) {
      // On garde null pour l'instant si le profil n'est pas disponible.
    }
    await _fetchMeals();
  }

  Future<void> _fetchMeals() async {
    setState(() {
      _isMealsLoading = true;
      _mealsError = null;
    });

    try {
      final meals = await ApiService.getMeals();
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _isMealsLoading = false;
      });
      _recalculateTotals();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMealsLoading = false;
        _mealsError = e.toString();
      });
    }
  }

  void _recalculateTotals() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final meal in _meals) {
      totalCalories += (meal['calories'] as num?)?.toDouble() ?? 0;
      totalProtein += (meal['protein'] as num?)?.toDouble() ?? 0;
      totalCarbs += (meal['carbs'] as num?)?.toDouble() ?? 0;
      totalFat += (meal['fat'] as num?)?.toDouble() ?? 0;
    }

    setState(() {
      _caloriesConsumed = totalCalories;
      _protein = totalProtein;
      _carbs = totalCarbs;
      _fat = totalFat;
    });
  }

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
              'Jean Dupont',
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
            TextButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: Text('Voir tout', style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _buildMealCard('Petit déjeuner', '420 kcal', Icons.wb_sunny_rounded, const Color(0xFFFFA726), true),
        const SizedBox(height: 14),
        _buildMealCard('Déjeuner', '650 kcal', Icons.wb_twilight_rounded, AppTheme.accentColor, true),
        const SizedBox(height: 14),
        _buildMealCard('Dîner', 'Non ajouté', Icons.nightlight_round, AppTheme.primaryColor, false),
      ],
    );
  }

  Widget _buildMealCard(String title, String calories, IconData icon, Color color, bool hasFood) {
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
              // Si déjà ajouté, peut-être éditer ? Pour l'instant on ouvre toujours le modal
              _showAddMealModal();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assistant IA', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Votre coach nutrition personnalisé', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 30),
          _buildAIAvatar(),
          const SizedBox(height: 30),
          _buildHealthGlobalCard(),
          const SizedBox(height: 20),
          _buildNextStepCard(),
          const SizedBox(height: 30),
          _buildAIRecommendations(),
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.aiGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.aiColor.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.psychology_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text('Bonjour Jean !', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'J\'ai analysé vos habitudes alimentaires',
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.white.withOpacity(0.95), height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGlobalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.successColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.favorite_rounded, color: AppTheme.successColor, size: 24),
              ),
              const SizedBox(width: 14),
              Text('Santé Globale', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          _buildHealthItem('Focus sur les micronutriments.', Icons.spa_rounded, AppTheme.primaryColor),
          const SizedBox(height: 14),
          _buildHealthItem('Boire 500ml d\'eau maintenant.', Icons.water_drop_rounded, AppTheme.secondaryColor),
          const SizedBox(height: 14),
          _buildHealthItem('Ajoutez plus de légumes verts.', Icons.eco_rounded, AppTheme.successColor),
        ],
      ),
    );
  }

  Widget _buildHealthItem(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.sunsetGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.accentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Text('Prochaine Étape', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 18),
          Text('Préparez un smoothie protéiné', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Vous avez besoin de 15g de protéines supplémentaires pour atteindre votre objectif aujourd\'hui.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.95), height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecipeDetailScreen(
                    recipe: {
                      'title': 'Smoothie Protéiné',
                      'calories': 320,
                      'protein': 30, // 15g base + 15g extra
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text('Voir la recette', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recommandations de repas', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 18),
        _buildRecommendationCard('Salade de quinoa aux légumes', '450 kcal • 20g protéines', Icons.restaurant_rounded, AppTheme.successColor),
        const SizedBox(height: 14),
        _buildRecommendationCard('Poulet grillé avec riz brun', '580 kcal • 45g protéines', Icons.dinner_dining_rounded, AppTheme.primaryColor),
        const SizedBox(height: 14),
        _buildRecommendationCard('Smoothie bowl aux fruits', '320 kcal • 12g protéines', Icons.set_meal_rounded, AppTheme.warningColor),
      ],
    );
  }

  Widget _buildRecommendationCard(String title, String details, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipe: {
                'title': title,
                'calories': int.tryParse(details.split(' ')[0]) ?? 0,
                'protein': int.tryParse(details.split('•')[1].trim().split('g')[0]) ?? 0,
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
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
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(details, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMealsPage() {
    if (_isMealsLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_mealsError != null) {
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
              Text(_mealsError!, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchMeals,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 20),
            Text('Aucun repas ajouté', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ajoute ton premier repas avec le bouton +', style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meal = _meals[index] as Map<String, dynamic>;
        final name = meal['name'] ?? 'Repas';
        final mealType = meal['meal_type'] ?? 'repas';
        final calories = (meal['calories'] as num?)?.toDouble() ?? 0;
        final date = meal['date'] ?? '';
        return Container(
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
                    if (date.toString().isNotEmpty)
                      Text(date.toString(), style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _showAddMealModal() {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ajouter un repas',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildAddMealOption(
                    rootContext,
                    'Scanner un aliment',
                    'Utilise la caméra pour identifier',
                    Icons.camera_alt_rounded,
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildAddMealOption(
                    rootContext,
                    'Rechercher un aliment',
                    'Cherche dans la base de données',
                    Icons.search_rounded,
                    AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                  _buildAddMealOption(
                    rootContext,
                    'Entrée manuelle',
                    'Ajoute les valeurs manuellement',
                    Icons.edit_rounded,
                    AppTheme.accentColor,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMealOption(
      BuildContext rootContext,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (title == 'Entrée manuelle') {
          _showManualMealForm();
          return;
        }
        _showSnackBar(
          rootContext,
          'Fonctionnalité "$title" sélectionnée',
          backgroundColor: color,
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

  Future<void> _showManualMealForm() async {
    final rootContext = context;
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String mealType = 'déjeuner';

    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Ajouter un repas', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom du repas'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mealType,
                  items: const [
                    DropdownMenuItem(value: 'petit-déjeuner', child: Text('Petit-déjeuner')),
                    DropdownMenuItem(value: 'déjeuner', child: Text('Déjeuner')),
                    DropdownMenuItem(value: 'dîner', child: Text('Dîner')),
                    DropdownMenuItem(value: 'snack', child: Text('Snack')),
                  ],
                  onChanged: (value) => mealType = value ?? 'déjeuner',
                  decoration: const InputDecoration(labelText: 'Type de repas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: caloriesController,
                  decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: proteinController,
                  decoration: const InputDecoration(labelText: 'Protéines (g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: carbsController,
                  decoration: const InputDecoration(labelText: 'Glucides (g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: fatController,
                  decoration: const InputDecoration(labelText: 'Lipides (g)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      if (_userId == null) {
                        _showSnackBar(
                          rootContext,
                          'Profil utilisateur indisponible.',
                        );
                        return;
                      }

                      final now = DateTime.now();
                      final date = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                      try {
                        await ApiService.addMeal(
                          userId: _userId!,
                          name: nameController.text,
                          mealType: mealType,
                          calories: double.parse(caloriesController.text),
                          protein: double.parse(proteinController.text),
                          carbs: double.parse(carbsController.text),
                          fat: double.parse(fatController.text),
                          date: date,
                          time: time,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);
                        await _fetchMeals();
                        _showSnackBar(
                          rootContext,
                          'Repas ajouté avec succès',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        _showSnackBar(
                          rootContext,
                          'Erreur: $e',
                        );
                      }
                    },
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }

  void _showSnackBar(
    BuildContext rootContext,
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}
