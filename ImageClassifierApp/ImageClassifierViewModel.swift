//
//  ImageClassifierViewModel.swift
//  ImageClassifierApp
//
//  Created by Brandon Baker on 4/4/26.
//

import SwiftUI
import PhotosUI
import CoreML
import UIKit
import Combine
@preconcurrency import Vision

// This is the main view model that handles all logic for the app
// It connects the UI with the machine learning models
@MainActor
class ImageClassifierViewModel: ObservableObject {
    
    // This stores the image selected by the user
    // When this changes, the UI updates automatically
    @Published var selectedImage: UIImage?
    
    // This stores the photo picker item before converting it to an image
    @Published var selectedPhotoItem: PhotosPickerItem?
    
    // This stores which model is currently selected
    // MobileNetV2 is the default since it performed the best overall
    @Published var selectedModel: ModelType = .mobileNet
    
    // This shows the main prediction result on the screen
    @Published var topPrediction: String = "No prediction yet"
    
    // This shows the confidence as a formatted percentage string
    @Published var confidenceText: String = ""
    
    // This stores the top 3 predictions from the model
    @Published var topResults: [ClassificationResult] = []
    
    // This controls whether the loading spinner is shown
    @Published var isLoading: Bool = false
    
    // This is a short warning message about bias and limitations
    // It reminds users that AI is not always correct
    @Published var biasWarning: String = "AI predictions may be wrong or biased depending on the image, lighting, background, or training data."
    
    // This stores any error message if something goes wrong
    @Published var errorMessage: String = ""
    
    // This function loads the image from the photo picker
    // It also prepares the image before sending it to the model
    func loadImage() async {
        
        // Make sure a photo was actually selected
        guard let selectedPhotoItem else { return }
        
        // Reset UI states before processing
        isLoading = true
        errorMessage = ""
        topPrediction = "Loading image..."
        confidenceText = ""
        topResults = []
        
        do {
            // Try to get image data from the picker
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                
                // Resize the image so it runs faster in the model
                // Most ML models expect around 224x224 input size
                let resizedImage = resizeImage(uiImage)
                
                selectedImage = resizedImage
                
                // Run classification on the resized image
                classifyImage(resizedImage)
                
            } else {
                errorMessage = "Could not load image."
                isLoading = false
            }
            
        } catch {
            errorMessage = "There was a problem loading the image."
            isLoading = false
        }
    }
    
    // This function resizes the image to a smaller size
    // This helps improve performance and reduce lag
    func resizeImage(_ image: UIImage, targetSize: CGSize = CGSize(width: 224, height: 224)) -> UIImage {
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        let newImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        
        return newImage
    }
    
    // This function selects the correct ML model based on user choice
    func getVisionModel() -> VNCoreMLModel? {
        
        do {
            switch selectedModel {
                
            case .mobileNet:
                // MobileNetV2 is lightweight and efficient
                let model = try MobileNetV2(configuration: MLModelConfiguration())
                return try VNCoreMLModel(for: model.model)
                
            case .fastViT:
                // FastViT is faster but sometimes less accurate
                let model = try FastViTT8F16(configuration: MLModelConfiguration())
                return try VNCoreMLModel(for: model.model)
                
            case .resnet:
                // ResNet is usually more accurate but heavier
                let model = try Resnet50(configuration: MLModelConfiguration())
                return try VNCoreMLModel(for: model.model)
            }
            
        } catch {
            errorMessage = "Could not load the ML model."
            return nil
        }
    }
    
    // This function sends the image to the selected ML model
    func classifyImage(_ image: UIImage) {
        
        // Convert UIImage to CIImage (required for Vision)
        guard let ciImage = CIImage(image: image) else {
            errorMessage = "Could not convert image."
            isLoading = false
            return
        }
        
        // Get the correct ML model
        guard let visionModel = getVisionModel() else {
            isLoading = false
            return
        }
        
        // Create a request to classify the image
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            
            guard let self = self else { return }
            
            // Handle errors
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Classification failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            // Get classification results
            guard let results = request.results as? [VNClassificationObservation],
                  !results.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "No results found."
                    self.isLoading = false
                }
                return
            }
            
            let firstResult = results[0]
            
            DispatchQueue.main.async {
                
                // Show the top prediction
                self.topPrediction = firstResult.identifier.capitalized
                
                // Format confidence as percentage
                self.confidenceText = String(format: "%.2f%%", firstResult.confidence * 100)
                
                // Store the top 3 predictions
                self.topResults = results.prefix(3).map {
                    ClassificationResult(
                        label: $0.identifier.capitalized,
                        confidence: Double($0.confidence)
                    )
                }
                
                self.isLoading = false
            }
        }
        
        // This helps the model crop the image correctly
        request.imageCropAndScaleOption = .centerCrop
        
        Task {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                errorMessage = "Could not process the image."
                isLoading = false
            }
        }
    }
    
    // This reruns classification when the user switches models
    func classifyCurrentImageAgain() {
        guard let selectedImage else { return }
        classifyImage(selectedImage)
    }
}
