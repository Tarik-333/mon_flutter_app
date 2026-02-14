from flask import Flask, request, jsonify
import db
from sklearn.neighbors import KNeighborsClassifier
import numpy as np
import base64
import io
# from PIL import Image # Uncomment if image processing is needed

app = Flask(__name__)

# Initialiser la DB au démarrage
db.init_db()

# --- Simulation Scikit-learn ---
# Dans un cas réel, vous chargeriez votre modèle ici : model = joblib.load('model.pkl')
# Pour l'exemple, on entraîne un modèle simple sur des données dummy au démarrage.
X_train = np.array([[100, 10, 20], [200, 5, 5], [50, 20, 0]]) # Dummy features (ex: histogramme couleur)
y_train = ['Pomme', 'Pain', 'Eau']
knn = KNeighborsClassifier(n_neighbors=1)
knn.fit(X_train, y_train)

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Simulation de prédiction d'image
        # On attendrait une image en base64 ou multipart
        # Ici on simule une réponse aléatoire ou basée sur un 'fake' input
        
        # data = request.get_json()
        # image_data = base64.b64decode(data['image'])
        # image = Image.open(io.BytesIO(image_data))
        # features = extract_features(image)
        # prediction = knn.predict([features])
        
        # Pour le prototype, on retourne un résultat "Pomme" hardcodé ou aléatoire
        # pour montrer que le lien fonctionne.
        
        mock_result = {
            "name": "Pomme Rouge",
            "calories": 52,
            "protein": 0.3,
            "carbs": 14,
            "fat": 0.2,
            "confidence": 0.95
        }
        return jsonify(mock_result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/user', methods=['GET', 'POST'])
def user():
    conn = db.get_db_connection()
    if not conn:
        return jsonify({"error": "DB Connection failed"}), 500
    
    cur = conn.cursor(cursor_factory=db.RealDictCursor)
    
    if request.method == 'GET':
        cur.execute("SELECT * FROM users LIMIT 1") # On prend le premier user pour l'exemple
        user = cur.fetchone()
        cur.close()
        conn.close()
        return jsonify(user)
    
    elif request.method == 'POST':
        data = request.json
        cur.execute("""
            UPDATE users SET 
            age = %s, height = %s, weight = %s, goal = %s, activity_level = %s
            WHERE id = 1
        """, (data['age'], data['height'], data['weight'], data['goal'], data['activity_level']))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "Profil mis à jour"})

@app.route('/meals', methods=['GET', 'POST'])
def meals():
    conn = db.get_db_connection()
    if not conn:
        return jsonify({"error": "DB connection failed"}), 500
    cur = conn.cursor(cursor_factory=db.RealDictCursor)

    if request.method == 'GET':
        cur.execute("SELECT * FROM meals WHERE date = CURRENT_DATE")
        meals = cur.fetchall()
        cur.close()
        conn.close()
        return jsonify(meals)
    
    elif request.method == 'POST':
        data = request.json
        # On insère les données détaillées du repas
        # Si product_id est fourni, on le garde pour référence, sinon null
        product_id = data.get('product_id') 
        
        cur.execute("""
            INSERT INTO meals (user_id, product_id, meal_type, date, time, name, calories, protein, carbs, fat, quantity, unit) 
            VALUES (1, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            product_id,
            data.get('meal_type', 'snack'),
            data.get('date'), # Format YYYY-MM-DD attendu
            data.get('time'), # Format HH:MM attendu
            data.get('name', 'Repas inconnu'),
            data.get('calories', 0),
            data.get('protein', 0),
            data.get('carbs', 0),
            data.get('fat', 0),
            data.get('quantity', 100),
            data.get('unit', 'g')
        ))
        conn.commit()
        return jsonify({"message": "Repas ajouté"})

@app.route('/products/search', methods=['GET'])
def search_products():
    query = request.args.get('q', '')
    if not query:
        return jsonify([])
        
    conn = db.get_db_connection()
    if not conn:
        return jsonify({"error": "DB connection failed"}), 500
    cur = conn.cursor(cursor_factory=db.RealDictCursor)
    
    # Recherche simple insensible à la casse
    search_pattern = f"%{query}%"
    cur.execute("""
        SELECT * FROM products 
        WHERE name ILIKE %s 
        LIMIT 20
    """, (search_pattern,))
    
    results = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify(results)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
