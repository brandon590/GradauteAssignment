//
//  ModelType.swift
//  ImageClassifierApp
//
//  Created by Brandon Baker on 4/4/26.
//

import Foundation

// This enum is used to store all the models we want to use in the app
// It makes it easier to switch between models in the UI
enum ModelType: String, CaseIterable, Identifiable {
    
    // These are the 3 models used in the project
    case mobileNet = "MobileNetV2"
    case fastViT = "FastViT T8"
    case resnet = "ResNet-50"
    
    // This helps SwiftUI identify each item in lists or pickers
    var id: String { rawValue }
}
