import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms, models
import os
import matplotlib.pyplot as plt

def train_model():
    # 1. Configuration
    DATA_DIR = "dataset"
    MODEL_SAVE_PATH = "banana_model_v1.pth"
    NUM_EPOCHS = 5
    BATCH_SIZE = 16
    LEARNING_RATE = 0.001

    # Check if dataset exists
    if not os.path.exists(os.path.join(DATA_DIR, "banana")) or not os.path.exists(os.path.join(DATA_DIR, "other")):
        print(f"ERROR: Directories {DATA_DIR}/banana and {DATA_DIR}/other must exist and contain images!")
        return

    # 2. Data Transformations (Augmentation + Normalization)
    data_transforms = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.RandomHorizontalFlip(),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    # 3. Load Data
    try:
        dataset = datasets.ImageFolder(DATA_DIR, transform=data_transforms)
        print(f"Found {len(dataset)} images in {len(dataset.classes)} classes: {dataset.classes}")
    except Exception as e:
        print(f"Error loading data: {e}")
        return

    dataloader = DataLoader(dataset, batch_size=BATCH_SIZE, shuffle=True)

    # 4. Load Pre-trained Model (MobileNetV2)
    print("Loading MobileNetV2...")
    model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.DEFAULT)

    # Freeze weights (Transfer Learning)
    for param in model.parameters():
        param.requires_grad = False

    # Replace last layer for binary classification (Banana vs Other)
    # MobileNetV2 classifier is a Sequential block, last item is Linear
    model.classifier[1] = nn.Linear(model.last_channel, 2)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Training on device: {device}")
    model = model.to(device)

    # 5. Loss and Optimizer
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.classifier.parameters(), lr=LEARNING_RATE)

    # 6. Training Loop
    print("Starting training...")
    loss_history = []
    
    for epoch in range(NUM_EPOCHS):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0

        for inputs, labels in dataloader:
            inputs, labels = inputs.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(inputs)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            _, predicted = torch.max(outputs.data, 1)
            total += labels.size(0)
            correct += (predicted == labels).sum().item()

        epoch_loss = running_loss / len(dataloader)
        epoch_acc = 100 * correct / total
        loss_history.append(epoch_loss)
        print(f"Epoch [{epoch+1}/{NUM_EPOCHS}] Loss: {epoch_loss:.4f} Acc: {epoch_acc:.2f}%")

    # 7. Save Model
    torch.save(model.state_dict(), MODEL_SAVE_PATH)
    print(f"Model saved to {MODEL_SAVE_PATH}")
    print("Class mapping:", dataset.class_to_idx)
    
    # Save class mapping to a text file for inference
    with open("class_mapping.txt", "w") as f:
        f.write(str(dataset.class_to_idx))
    
    # Plot training loss
    plt.plot(loss_history)
    plt.title("Training Loss")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.savefig("training_loss.png")
    print("Loss plot saved to training_loss.png")

if __name__ == "__main__":
    train_model()
