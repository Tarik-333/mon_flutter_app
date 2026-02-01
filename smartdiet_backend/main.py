from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import List
from datetime import timedelta
import uvicorn
import joblib
import pandas as pd
from pydantic import BaseModel
from pathlib import Path

from database import get_db, init_db
import models
import schemas
import crud
from auth import (
    create_access_token,
    get_current_user,
    ACCESS_TOKEN_EXPIRE_MINUTES
)
# from ai_recommendations import AIRecommendations  # Not used - AI page is coming soon

# =========================
# Initialiser la base de données
# =========================
init_db()

app = FastAPI(
    title="SmartDiet API",
    description="API Backend pour l'application SmartDiet",
    version="2.0.0"
)

# =========================
# =========================
# IA - Modèle calories (Disabled - AI page coming soon)
# =========================
# MODEL_PATH = Path("calorie_model.joblib")
# calorie_model = None

# def train_and_save_model():
#     ...

# def get_calorie_model():
#     ...

# class PredictCaloriesRequest(BaseModel):
#     name: str
#     grams: float
#     category: str

# @app.post("/api/ai/predict-calories")
# def predict_calories(req: PredictCaloriesRequest):
#     ...


# =========================
# Reconnaissance Banane (PoC)
# =========================
from fastapi import UploadFile, File
from ml_service import food_service

@app.post("/api/ai/recognize-banana")
async def recognize_banana(file: UploadFile = File(...)):
    """
    Reçoit une image et détecte si c'est une banane ou non.
    Utilise le modèle fine-tuné 'banana_model_v1.pth'.
    (Deprecated: use /api/ai/recognize-food instead)
    """
    contents = await file.read()
    result = food_service.predict(contents)
    # Convert to old format for backward compatibility
    return {
        "is_banana": result.get("is_recognized", False),
        "confidence": result.get("confidence", 0),
        "class_name": result.get("class_name", "unknown")
    }


@app.post("/api/ai/recognize-food")
async def recognize_food(file: UploadFile = File(...)):
    """
    Reçoit une image et détecte l'aliment.
    Retourne les informations nutritionnelles si l'aliment est reconnu.
    """
    contents = await file.read()
    result = food_service.predict(contents)
    return result


@app.get("/api/foods/search")
def search_foods(query: str, db: Session = Depends(get_db)):
    """Recherche dans la base de données"""
    if not query:
        return []
        
    results = crud.get_foods(db, query)
    
    # Convertir en dict pour la réponse (si nécessaire, ou laisser FastAPI le faire via ORM)
    # On retourne directement les objets ORM, FastAPI gérera la sérialisation si on avait des schemas
    # Mais ici on retourne une liste brute, donc on va convertir manuellement pour être sûr
    
    res_list = []
    for food in results:
        res_list.append({
            "name": food.name,
            "grams": food.grams,
            "category": food.category,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fat": food.fat
        })
        
    print(f"🔍 Search '{query}' -> {len(res_list)} results.")
    return res_list


# =========================
# CORS
# =========================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # OK pour dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# ROUTES DE BASE
# =========================
@app.get("/")
def root():
    return {
        "message": "SmartDiet API v2.0",
        "status": "running",
        "endpoints": {
            "docs": "/docs",
            "health": "/health"
        }
    }


@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "connected"}


# =========================
# AUTHENTIFICATION
# =========================
@app.post("/api/register", response_model=schemas.Token)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Inscription d'un nouvel utilisateur"""
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Email déjà utilisé"
        )

    new_user = crud.create_user(db=db, user=user)

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": new_user.email},
        expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": new_user
    }


@app.post("/api/login", response_model=schemas.Token)
def login(user_credentials: schemas.UserLogin, db: Session = Depends(get_db)):
    """Connexion utilisateur"""
    user = crud.authenticate_user(db, user_credentials.email, user_credentials.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email},
        expires_delta=access_token_expires
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }


# =========================
# UTILISATEUR
# =========================
@app.get("/api/user/me", response_model=schemas.UserResponse)
def get_current_user_info(current_user: models.User = Depends(get_current_user)):
    """Obtenir les infos de l'utilisateur connecté"""
    return current_user


@app.put("/api/user/me", response_model=schemas.UserResponse)
def update_current_user(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Mettre à jour le profil utilisateur"""
    updated_user = crud.update_user(db, current_user.id, user_update)
    return updated_user


@app.get("/api/user/goals")
def get_user_goals(current_user: models.User = Depends(get_current_user)):
    """Obtenir les objectifs caloriques de l'utilisateur - Coming soon"""
    # TODO: Implement real AI-based calorie goals
    return {
        "daily_calories": 2000,
        "protein": 150,
        "carbs": 250,
        "fat": 65
    }


# =========================
# REPAS
# =========================
@app.post("/api/meals", response_model=schemas.MealResponse)
def add_meal(
    meal: schemas.MealCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Ajouter un repas"""
    if meal.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Accès non autorisé")

    return crud.create_meal(db=db, meal=meal)


@app.get("/api/meals", response_model=List[schemas.MealResponse])
def get_my_meals(
    limit: int = 100,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Obtenir tous les repas de l'utilisateur"""
    return crud.get_meals_by_user(db, current_user.id, limit)


@app.get("/api/meals/date/{date}")
def get_meals_by_date(
    date: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Obtenir les repas d'une date spécifique"""
    meals = crud.get_meals_by_date(db, current_user.id, date)
    stats = crud.get_daily_stats(db, current_user.id, date)

    return {
        "meals": meals,
        "stats": stats
    }


# =========================
# SUIVI DU POIDS
# =========================
@app.post("/api/weight", response_model=schemas.WeightLogResponse)
def log_weight(
    weight_log: schemas.WeightLogCreate,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Enregistrer un poids"""
    if weight_log.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Accès non autorisé")

    return crud.create_weight_log(db=db, weight_log=weight_log)


@app.get("/api/weight", response_model=List[schemas.WeightLogResponse])
def get_weight_logs(
    limit: int = 30,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Obtenir l'historique de poids"""
    return crud.get_weight_logs(db, current_user.id, limit)


# =========================
# IA & RECOMMANDATIONS (Coming Soon)
# =========================
# These endpoints are disabled as the AI page is under development

# @app.get("/api/recommendations")
# def get_recommendations(
#     current_user: models.User = Depends(get_current_user),
#     db: Session = Depends(get_db)
# ):
#     """Obtenir les recommandations de repas personnalisées"""
#     return AIRecommendations.get_meal_recommendations(current_user, db)


# @app.get("/api/health-tips")
# def get_health_tips(
#     current_user: models.User = Depends(get_current_user),
#     db: Session = Depends(get_db)
# ):
#     """Obtenir les conseils santé personnalisés"""
#     return AIRecommendations.get_health_tips(current_user, db)


# @app.get("/api/analysis/progress")
# def get_progress_analysis(
#     current_user: models.User = Depends(get_current_user),
#     db: Session = Depends(get_db)
# ):
#     """Analyse des progrès de l'utilisateur"""
#     return AIRecommendations.analyze_progress(current_user, db)


# =========================
# STATISTIQUES
# =========================
@app.get("/api/stats/summary")
def get_stats_summary(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Résumé des statistiques utilisateur"""
    meals = crud.get_meals_by_user(db, current_user.id, limit=30)
    weight_logs = crud.get_weight_logs(db, current_user.id, limit=30)
    
    # Simple default goals
    goals = {
        "daily_calories": 2000,
        "protein": 150,
        "carbs": 250,
        "fat": 65
    }

    return {
        "total_meals": len(meals),
        "total_weight_logs": len(weight_logs),
        "current_weight": current_user.weight,
        "goals": goals,
        "recent_meals_count": len(meals)
    }


# =========================
# LANCEMENT DU SERVEUR
# =========================
if __name__ == "__main__":
    print("=" * 50)
    print("🚀 SmartDiet Backend API v2.0")
    print("=" * 50)
    print("📡 Server: http://0.0.0.0:8000")
    print("📚 Docs: http://localhost:8000/docs")
    print("=" * 50)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
