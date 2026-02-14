import db
import psycopg2

def migrate():
    conn = db.get_db_connection()
    if not conn:
        print("Impossible de se connecter à la DB")
        return

    try:
        cur = conn.cursor()
        
        # Liste des colonnes à ajouter
        columns = [
            ("time", "TIME DEFAULT CURRENT_TIME"),
            ("name", "VARCHAR(100)"),
            ("calories", "FLOAT DEFAULT 0"),
            ("protein", "FLOAT DEFAULT 0"),
            ("carbs", "FLOAT DEFAULT 0"),
            ("fat", "FLOAT DEFAULT 0"),
            ("quantity", "FLOAT DEFAULT 100"),
            ("unit", "VARCHAR(20) DEFAULT 'g'")
        ]

        for col_name, col_def in columns:
            try:
                cur.execute(f"ALTER TABLE meals ADD COLUMN {col_name} {col_def};")
                print(f"Colonne {col_name} ajoutée.")
            except psycopg2.errors.DuplicateColumn:
                print(f"Colonne {col_name} existe déjà.")
                conn.rollback() # Important après une erreur dans une transaction
            except Exception as e:
                print(f"Erreur lors de l'ajout de {col_name}: {e}")
                conn.rollback()
        
        conn.commit()
        print("Migration terminée.")
        cur.close()
        conn.close()

    except Exception as e:
        print(f"Erreur globale de migration: {e}")

if __name__ == "__main__":
    migrate()
