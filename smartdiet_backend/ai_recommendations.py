from typing import List, Dict
import models
from sqlalchemy.orm import Session
from datetime import datetime, timedelta

class AIRecommendations:
    
    @staticmethod
    def calculate_bmr(weight: float, height: float, age: int, gender: str) -> float:
        """Calcul du métabolisme de base (BMR) avec la formule de Mifflin-St Jeor"""
        if gender.lower() == "homme":
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        else:
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
        return bmr
    
    @staticmethod
    def calculate_tdee(bmr: float, activity_level: str) -> float:
        """Calcul des besoins caloriques journaliers (TDEE)"""
        activity_multipliers = {
            "sédentaire": 1.2,
            "modéré": 1.55,
            "actif": 1.725,
            "très actif": 1.9
        }
        multiplier = activity_multipliers.get(activity_level.lower(), 1.55)
        return bmr * multiplier
    
    @staticmethod
    def get_calorie_goal(user: models.User) -> Dict:
        """Calcule l'objectif calorique selon le goal de l'utilisateur"""
        bmr = AIRecommendations.calculate_bmr(
            user.weight, user.height, user.age, user.gender
        )
        tdee = AIRecommendations.calculate_tdee(bmr, user.activity_level)
        
        if user.goal == "perte":
            calorie_goal = tdee - 500  # Déficit de 500 kcal
            protein_goal = user.weight * 2.2  # 2.2g par kg
            carbs_goal = (calorie_goal * 0.30) / 4  # 30% des calories
            fat_goal = (calorie_goal * 0.30) / 9  # 30% des calories
        elif user.goal == "prise":
            calorie_goal = tdee + 500  # Surplus de 500 kcal
            protein_goal = user.weight * 2.0
            carbs_goal = (calorie_goal * 0.50) / 4  # 50% des calories
            fat_goal = (calorie_goal * 0.25) / 9  # 25% des calories
        else:  # maintien
            calorie_goal = tdee
            protein_goal = user.weight * 1.8
            carbs_goal = (calorie_goal * 0.40) / 4
            fat_goal = (calorie_goal * 0.30) / 9
        
        return {
            "calorie_goal": round(calorie_goal),
            "protein_goal": round(protein_goal),
            "carbs_goal": round(carbs_goal),
            "fat_goal": round(fat_goal),
            "bmr": round(bmr),
            "tdee": round(tdee)
        }
    
    @staticmethod
    def get_meal_recommendations(user: models.User, db: Session) -> List[Dict]:
        """Recommandations de repas basées sur le profil utilisateur"""
        
        # Base de données de repas
        all_meals = {
            "perte": [
                {
                    "name": "Salade de quinoa aux légumes grillés",
                    "calories": 450,
                    "protein": 20,
                    "carbs": 55,
                    "fat": 15,
                    "description": "Riche en protéines végétales et fibres",
                    "meal_type": "déjeuner",
                    "ingredients": ["quinoa", "courgettes", "poivrons", "tomates", "feta"]
                },
                {
                    "name": "Poulet grillé avec légumes vapeur",
                    "calories": 380,
                    "protein": 45,
                    "carbs": 25,
                    "fat": 12,
                    "description": "Faible en calories, riche en protéines",
                    "meal_type": "dîner",
                    "ingredients": ["poulet", "brocoli", "haricots verts", "carottes"]
                },
                {
                    "name": "Omelette aux légumes",
                    "calories": 320,
                    "protein": 28,
                    "carbs": 15,
                    "fat": 18,
                    "description": "Parfait pour le petit-déjeuner protéiné",
                    "meal_type": "petit-déjeuner",
                    "ingredients": ["œufs", "épinards", "champignons", "tomates"]
                },
                {
                    "name": "Soupe de lentilles",
                    "calories": 280,
                    "protein": 18,
                    "carbs": 42,
                    "fat": 5,
                    "description": "Rassasiante et nutritive",
                    "meal_type": "dîner",
                    "ingredients": ["lentilles", "carottes", "céleri", "oignon"]
                }
            ],
            "prise": [
                {
                    "name": "Riz brun avec saumon grillé",
                    "calories": 680,
                    "protein": 45,
                    "carbs": 72,
                    "fat": 22,
                    "description": "Riche en protéines et glucides complexes",
                    "meal_type": "déjeuner",
                    "ingredients": ["saumon", "riz brun", "avocat", "légumes"]
                },
                {
                    "name": "Smoothie protéiné banane-avoine",
                    "calories": 520,
                    "protein": 35,
                    "carbs": 68,
                    "fat": 12,
                    "description": "Parfait pour la prise de masse",
                    "meal_type": "snack",
                    "ingredients": ["whey", "banane", "avoine", "lait", "beurre de cacahuète"]
                },
                {
                    "name": "Pâtes complètes au poulet",
                    "calories": 720,
                    "protein": 48,
                    "carbs": 85,
                    "fat": 18,
                    "description": "Idéal post-entraînement",
                    "meal_type": "dîner",
                    "ingredients": ["pâtes complètes", "poulet", "sauce tomate", "parmesan"]
                },
                {
                    "name": "Œufs brouillés avec pain complet",
                    "calories": 480,
                    "protein": 32,
                    "carbs": 45,
                    "fat": 20,
                    "description": "Petit-déjeuner énergétique",
                    "meal_type": "petit-déjeuner",
                    "ingredients": ["œufs", "pain complet", "fromage", "avocat"]
                }
            ],
            "maintien": [
                {
                    "name": "Bowl méditerranéen",
                    "calories": 550,
                    "protein": 30,
                    "carbs": 58,
                    "fat": 22,
                    "description": "Équilibré en macronutriments",
                    "meal_type": "déjeuner",
                    "ingredients": ["poulet", "riz", "légumes", "houmous", "olives"]
                },
                {
                    "name": "Tacos au poisson",
                    "calories": 480,
                    "protein": 35,
                    "carbs": 52,
                    "fat": 16,
                    "description": "Savoureux et équilibré",
                    "meal_type": "dîner",
                    "ingredients": ["poisson blanc", "tortillas", "chou", "avocat", "salsa"]
                },
                {
                    "name": "Porridge aux fruits",
                    "calories": 380,
                    "protein": 15,
                    "carbs": 62,
                    "fat": 10,
                    "description": "Petit-déjeuner équilibré",
                    "meal_type": "petit-déjeuner",
                    "ingredients": ["avoine", "lait", "banane", "baies", "miel"]
                },
                {
                    "name": "Wok de légumes et tofu",
                    "calories": 420,
                    "protein": 22,
                    "carbs": 48,
                    "fat": 18,
                    "description": "Option végétarienne équilibrée",
                    "meal_type": "dîner",
                    "ingredients": ["tofu", "légumes variés", "sauce soja", "riz"]
                }
            ]
        }
        
        return all_meals.get(user.goal, all_meals["maintien"])
    
    @staticmethod
    def get_health_tips(user: models.User, db: Session) -> Dict:
        """Conseils santé personnalisés basés sur l'analyse des données"""
        
        goals = AIRecommendations.get_calorie_goal(user)
        
        # Analyse des repas récents
        from crud import get_meals_by_user
        recent_meals = get_meals_by_user(db, user.id, limit=7)
        
        tips = []
        
        # Analyse hydratation
        tips.append({
            "icon": "water_drop",
            "title": "Hydratation",
            "message": "Buvez 500ml d'eau maintenant",
            "priority": "high"
        })
        
        # Analyse protéines
        if recent_meals:
            avg_protein = sum(m.protein for m in recent_meals) / len(recent_meals)
            if avg_protein < goals["protein_goal"] * 0.8:
                tips.append({
                    "icon": "spa",
                    "title": "Protéines",
                    "message": f"Augmentez vos protéines à {goals['protein_goal']}g/jour",
                    "priority": "medium"
                })
        
        # Conseil micronutriments
        tips.append({
            "icon": "eco",
            "title": "Micronutriments",
            "message": "Ajoutez plus de légumes verts à vos repas",
            "priority": "medium"
        })
        
        # Conseil activité
        if user.activity_level == "sédentaire":
            tips.append({
                "icon": "directions_walk",
                "title": "Activité physique",
                "message": "Essayez 30 minutes de marche aujourd'hui",
                "priority": "low"
            })
        
        # Prochaine étape
        protein_deficit = goals["protein_goal"] - (avg_protein if recent_meals else 0)
        
        next_step = {
            "title": "Préparez un smoothie protéiné",
            "description": f"Vous avez besoin d'environ {round(protein_deficit)}g de protéines supplémentaires pour atteindre votre objectif aujourd'hui.",
            "action": "Voir la recette",
            "calories": 320,
            "protein": 25
        }
        
        return {
            "tips": tips[:3],  # Top 3 conseils
            "next_step": next_step,
            "goals": goals
        }
    
    @staticmethod
    def analyze_progress(user: models.User, db: Session) -> Dict:
        """Analyse des progrès de l'utilisateur"""
        from crud import get_weight_logs, get_meals_by_user
        
        weight_logs = get_weight_logs(db, user.id, limit=30)
        meals = get_meals_by_user(db, user.id, limit=30)
        
        analysis = {
            "weight_trend": "stable",
            "calorie_adherence": 0,
            "protein_adherence": 0,
            "consistency": 0,
            "recommendations": []
        }
        
        # Analyse du poids
        if len(weight_logs) >= 2:
            first_weight = weight_logs[-1].weight
            last_weight = weight_logs[0].weight
            weight_change = last_weight - first_weight
            
            if user.goal == "perte" and weight_change < -0.5:
                analysis["weight_trend"] = "excellent"
            elif user.goal == "prise" and weight_change > 0.5:
                analysis["weight_trend"] = "excellent"
            elif abs(weight_change) < 0.5:
                analysis["weight_trend"] = "stable"
        
        # Analyse des calories
        if meals:
            goals = AIRecommendations.get_calorie_goal(user)
            avg_calories = sum(m.calories for m in meals) / len(meals)
            adherence = (avg_calories / goals["calorie_goal"]) * 100
            analysis["calorie_adherence"] = min(100, adherence)
        
        return analysis