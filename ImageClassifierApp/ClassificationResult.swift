//
//  ClassificationResult.swift
//  ImageClassifierApp
//
//  Created by Brandon Baker on 4/4/26.
//

import Foundation

// This struct is used to store a prediction result from the model
// Each result includes the label and how confident the model is
struct ClassificationResult: Identifiable {
    
    // This gives each result a unique ID for SwiftUI lists
    let id = UUID()
    
    // The name of what the model predicted
    let label: String
    
    // The confidence score (0.0 to 1.0)
    let confidence: Double
}
