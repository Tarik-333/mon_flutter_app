import torch
from torchvision import models, transforms
from PIL import Image
import io
import os
import ast

MODEL_PATH = "banana_model_v1.pth"
CLASS_MAPPING_PATH = "class_mapping.txt"

class FoodReconService:
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.class_mapping = {}
        self.load_model()
        
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])

    def load_model(self):
        if not os.path.exists(MODEL_PATH):
            print(f"Warning: {MODEL_PATH} not found. Prediction will fail until model is trained.")
            return

        try:
            # Recreate the model structure
            self.model = models.mobilenet_v2(weights=None) # No need for weights, we load ours
            self.model.classifier[1] = torch.nn.Linear(self.model.last_channel, 2)
            
            # Load weights
            self.model.load_state_dict(torch.load(MODEL_PATH, map_location=self.device))
            self.model.to(self.device)
            self.model.eval()
            print("Food recognition model loaded successfully!")
            
            # Load class mapping
            if os.path.exists(CLASS_MAPPING_PATH):
                with open(CLASS_MAPPING_PATH, "r") as f:
                    content = f.read()
                    self.class_mapping = ast.literal_eval(content)
                    # Invert mapping: index -> class name
                    self.idx_to_class = {v: k for k, v in self.class_mapping.items()}
            else:
                # Default fallback if file missing
                self.idx_to_class = {0: "banana", 1: "other"} 

        except Exception as e:
            print(f"Error loading model: {e}")

    def predict(self, image_bytes):
        if self.model is None:
            # Try reloading in case it was just trained
            self.load_model()
            if self.model is None:
                return {"error": "Model not trained yet"}

        try:
            image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
            tensor = self.transform(image).unsqueeze(0).to(self.device)

            with torch.no_grad():
                outputs = self.model(tensor)
                probabilities = torch.nn.functional.softmax(outputs, dim=1)
                confidence, predicted = torch.max(probabilities, 1)
                
                class_idx = predicted.item()
                class_name = self.idx_to_class.get(class_idx, "unknown")
                prob = confidence.item()

                is_banana = "banana" in class_name.lower()
                
                # Nutritional information for banana (per 100g)
                nutritional_info = None
                if is_banana:
                    nutritional_info = {
                        "calories": 89,
                        "protein": 1.1,
                        "carbs": 22.8,
                        "fat": 0.3
                    }
                
                return {
                    "is_recognized": is_banana,
                    "food_name": "Banane" if is_banana else "Inconnu",
                    "confidence": round(prob * 100, 2),
                    "class_name": class_name,
                    "nutritional_info": nutritional_info
                }
        except Exception as e:
            return {"error": str(e)}

food_service = FoodReconService()
