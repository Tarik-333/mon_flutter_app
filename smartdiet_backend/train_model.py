# train_model.py
# Entraîner un modèle simple "nom aliment + catégorie + grammes" -> calories
# Dans le dossier smartdiet_backend:
#   python train_model.py
# => crée calorie_model.joblib

from pathlib import Path
import pandas as pd
import joblib

from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import OneHotEncoder
from sklearn.linear_model import Ridge

BASE_DIR = Path(__file__).resolve().parent
CSV_PATH = BASE_DIR / "foods.csv"
MODEL_PATH = BASE_DIR / "calorie_model.joblib"

def main():
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"foods.csv introuvable: {CSV_PATH}")

    df = pd.read_csv(CSV_PATH)

    needed = {"name", "grams", "category", "calories"}
    missing = needed - set(df.columns)
    if missing:
        raise ValueError(f"Colonnes manquantes: {missing}. Colonnes trouvées: {list(df.columns)}")

    df["name"] = df["name"].astype(str).str.lower().str.strip()
    df["category"] = df["category"].astype(str).str.lower().str.strip()
    df["grams"] = pd.to_numeric(df["grams"], errors="coerce").fillna(100)
    df["calories"] = pd.to_numeric(df["calories"], errors="coerce")
    df = df.dropna(subset=["calories"])

    X = df[["name", "category", "grams"]]
    y = df["calories"]

    preprocessor = ColumnTransformer(
        transformers=[
            ("name_tfidf", TfidfVectorizer(ngram_range=(1, 2)), "name"),
            ("cat_ohe", OneHotEncoder(handle_unknown="ignore"), ["category"]),
            ("grams_num", "passthrough", ["grams"]),
        ]
    )

    model = Ridge(alpha=1.0)

    pipe = Pipeline([("prep", preprocessor), ("model", model)])

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    pipe.fit(X_train, y_train)

    score = pipe.score(X_test, y_test)

    joblib.dump(pipe, MODEL_PATH)
    print("✅ Modèle sauvegardé:", MODEL_PATH)
    print(f"📊 Score R² (indicatif): {score:.3f}")

if __name__ == "__main__":
    main()
