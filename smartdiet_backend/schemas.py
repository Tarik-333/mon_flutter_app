from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# USER SCHEMAS
class UserBase(BaseModel):
    name: str
    email: EmailStr

class UserCreate(UserBase):
    password: str
    age: int
    weight: float
    height: float
    gender: str
    goal: str
    activity_level: Optional[str] = "modéré"

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(UserBase):
    id: int
    age: int
    weight: float
    height: float
    gender: str
    goal: str
    activity_level: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    weight: Optional[float] = None
    height: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None

# MEAL SCHEMAS
class MealBase(BaseModel):
    name: str
    meal_type: str
    calories: float
    protein: float
    carbs: float
    fat: float
    fiber: Optional[float] = 0
    quantity: Optional[float] = 100
    unit: Optional[str] = 'g'
    date: str
    time: Optional[str] = None
    notes: Optional[str] = None

class MealCreate(MealBase):
    user_id: int

class MealResponse(MealBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# WEIGHT LOG SCHEMAS
class WeightLogCreate(BaseModel):
    user_id: int
    weight: float
    date: str

class WeightLogResponse(BaseModel):
    id: int
    user_id: int
    weight: float
    date: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# TOKEN SCHEMAS
class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse

class TokenData(BaseModel):
    email: Optional[str] = None