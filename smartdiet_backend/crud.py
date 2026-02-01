from sqlalchemy.orm import Session
from sqlalchemy import func
import models
import schemas
from auth import get_password_hash, verify_password
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy.exc import IntegrityError


# USER CRUD
def get_user_by_email(db: Session, email: str):
    return db.query(models.User).filter(models.User.email == email).first()

def create_user(db: Session, user: schemas.UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        name=user.name,
        email=user.email,
        hashed_password=hashed_password,
        age=user.age,
        weight=user.weight,
        height=user.height,
        gender=user.gender,
        goal=user.goal,
        activity_level=user.activity_level
    )
    db.add(db_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str):
    user = get_user_by_email(db, email)
    if not user:
        return False
    if not verify_password(password, user.hashed_password):
        return False
    return user

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if db_user:
        update_data = user_update.dict(exclude_unset=True)
        for key, value in update_data.items():
            setattr(db_user, key, value)
        db_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_user)
    return db_user

# MEAL CRUD
def create_meal(db: Session, meal: schemas.MealCreate):
    db_meal = models.Meal(**meal.dict())
    db.add(db_meal)
    db.commit()
    db.refresh(db_meal)
    return db_meal

def get_meals_by_user(db: Session, user_id: int, limit: int = 100):
    return db.query(models.Meal).filter(models.Meal.user_id == user_id).order_by(models.Meal.created_at.desc()).limit(limit).all()

def get_meals_by_date(db: Session, user_id: int, date: str):
    return db.query(models.Meal).filter(
        models.Meal.user_id == user_id,
        models.Meal.date == date
    ).all()

def get_daily_stats(db: Session, user_id: int, date: str):
    meals = get_meals_by_date(db, user_id, date)
    total_calories = sum(meal.calories for meal in meals)
    total_protein = sum(meal.protein for meal in meals)
    total_carbs = sum(meal.carbs for meal in meals)
    total_fat = sum(meal.fat for meal in meals)
    
    return {
        "date": date,
        "total_calories": total_calories,
        "total_protein": total_protein,
        "total_carbs": total_carbs,
        "total_fat": total_fat,
        "meal_count": len(meals)
    }

# WEIGHT LOG CRUD
def create_weight_log(db: Session, weight_log: schemas.WeightLogCreate):
    db_log = models.WeightLog(**weight_log.dict())
    db.add(db_log)
    db.commit()
    db.refresh(db_log)
    return db_log

def get_weight_logs(db: Session, user_id: int, limit: int = 30):
    return db.query(models.WeightLog).filter(
        models.WeightLog.user_id == user_id
    ).order_by(models.WeightLog.date.desc()).limit(limit).all()

def get_foods(db: Session, query: str = None, limit: int = 20):
    """Rechercher des aliments"""
    sql_query = db.query(models.Food)
    if query:
        # Recherche insensible à la casse
        sql_query = sql_query.filter(models.Food.name.ilike(f"%{query}%"))
    
    return sql_query.limit(limit).all()