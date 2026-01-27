import psycopg2
from psycopg2.extras import RealDictCursor
import os

# Configuration de la base de données
# Vous devez adapter ces valeurs à votre configuration locale PostgreSQL
DB_HOST = "localhost"
DB_NAME = "smartdiet_db"
DB_USER = "postgres"
DB_PASS = "admin" # Changez ceci avec votre mot de passe

def get_db_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASS
        )
        return conn
    except Exception as e:
        print(f"Erreur de connexion à la base de données: {e}")
        return None

def init_db():
    conn = get_db_connection()
    if conn:
        try:
            cur = conn.cursor()
            
            # Création de la table users
            cur.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100),
                    age INTEGER,
                    gender VARCHAR(20),
                    height FLOAT,
                    weight FLOAT,
                    goal VARCHAR(50),
                    activity_level VARCHAR(50)
                );
            """)
            
            # Création de la table products
            cur.execute("""
                CREATE TABLE IF NOT EXISTS products (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100),
                    calories INTEGER,
                    protein FLOAT,
                    carbs FLOAT,
                    fat FLOAT,
                    image_url TEXT
                );
            """)
            
            # Création de la table meals
            cur.execute("""
                CREATE TABLE IF NOT EXISTS meals (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(id),
                    product_id INTEGER REFERENCES products(id),
                    meal_type VARCHAR(50), -- breakfast, lunch, dinner, snack
                    date DATE DEFAULT CURRENT_DATE
                );
            """)

            # Insertion d'un utilisateur par défaut s'il n'existe pas
            cur.execute("SELECT * FROM users LIMIT 1;")
            if not cur.fetchone():
                cur.execute("""
                    INSERT INTO users (name, age, gender, height, weight, goal, activity_level)
                    VALUES ('Jean Dupont', 25, 'homme', 175, 70, 'maintien', 'modéré');
                """)
                
            conn.commit()
            cur.close()
            conn.close()
            print("Base de données initialisée avec succès.")
        except Exception as e:
            print(f"Erreur lors de l'initialisation de la DB: {e}")
    else:
         print("Impossible de se connecter pour initialiser la DB.")

if __name__ == "__main__":
    init_db()
