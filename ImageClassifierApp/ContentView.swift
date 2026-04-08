//
//  ContentView.swift
//  ImageClassifierApp
//
//  Created by Brandon Baker on 4/4/26.
//

import SwiftUI
import PhotosUI

// This is the main screen of the app.
// It shows the title, model options, image picker, selected image,
// prediction results, and the ethical warning message.
struct ContentView: View {
    
    // This creates the view model and keeps it alive while this screen is open.
    // The view model handles image loading, model selection, and classification.
    @StateObject private var viewModel = ImageClassifierViewModel()
    
    // This stores the dark mode setting.
    // AppStorage lets the app remember the user's choice even if the app closes.
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                // This adds a soft gradient background to make the app look cleaner
                // and a little more modern than using a plain background color.
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.purple.opacity(0.10),
                        Color.blue.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // This is the title section at the top of the app.
                        // It gives the user a quick idea of what the app does.
                        VStack(spacing: 8) {
                            Text("Smart Image Classifier")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("MobileNetV2 is the recommended model for this app, but you can still compare FastViT T8 and ResNet-50.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 10)
                        
                        // This card highlights the final model choice from Part 2.
                        // Since MobileNetV2 was chosen as the best overall model,
                        // this section makes that clear to the user right away.
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                
                                Text("Recommended Model")
                                    .font(.headline)
                            }
                            
                            Text("MobileNetV2")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("This model gave the best overall balance of accuracy, speed, and efficiency for a mobile app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        
                        // This section lets the user switch between light mode and dark mode.
                        // Adding this helps make the app more user-friendly and also helps
                        // meet the dark-mode-friendly part of the assignment.
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(isDarkMode ? .yellow : .orange)
                                
                                Text("Appearance")
                                    .font(.headline)
                            }
                            
                            // This toggle changes the app appearance.
                            // When the toggle is on, the app uses dark mode.
                            Toggle(isOn: $isDarkMode) {
                                Text(isDarkMode ? "Dark Mode On" : "Dark Mode Off")
                                    .font(.subheadline)
                            }
                            .toggleStyle(SwitchToggleStyle())
                            
                            Text("This makes the app easier to use in both light and dark environments.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        
                        // This section lets the user choose which model to run.
                        // MobileNetV2 is the main one, but the other two models are still
                        // included so the user can compare predictions if they want.
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose a Model")
                                .font(.headline)
                            
                            Picker("Choose a Model", selection: $viewModel.selectedModel) {
                                Text("MobileNetV2").tag(ModelType.mobileNet)
                                Text("FastViT T8").tag(ModelType.fastViT)
                                Text("ResNet-50").tag(ModelType.resnet)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: viewModel.selectedModel) { _ in
                                // If the user already selected an image,
                                // this reruns classification with the new model right away.
                                viewModel.classifyCurrentImageAgain()
                            }
                            
                            // This short text under the picker changes depending on the model.
                            // It gives the user a quick explanation of what each model is best for.
                            Text(modelDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal)
                        
                        // This is the button used to open the photo library.
                        // The user can pick an image from their device to test the model.
                        PhotosPicker(
                            selection: $viewModel.selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.title3)
                                
                                Text("Select an Image")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                // This blue gradient makes the button stand out more.
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .shadow(radius: 4)
                        }
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedPhotoItem) { _ in
                            // When the user chooses a photo, this starts loading it
                            // and sends it to the selected machine learning model.
                            Task {
                                await viewModel.loadImage()
                            }
                        }
                        
                        // This section shows the image the user selected.
                        // It only appears after an image has been picked.
                        if let image = viewModel.selectedImage {
                            VStack(spacing: 14) {
                                Text("Selected Image")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                                    .shadow(radius: 8)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .padding(.horizontal)
                        }
                        
                        // This loading section appears while the model is processing the image.
                        // It gives the user feedback so the app does not seem frozen.
                        if viewModel.isLoading {
                            VStack(spacing: 10) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                
                                Text("Classifying image...")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                        
                        // This shows an error message if something goes wrong,
                        // like if the image fails to load or classify.
                        if !viewModel.errorMessage.isEmpty {
                            Text(viewModel.errorMessage)
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // This card shows the main result after classification is finished.
                        // It includes which model was used, the top prediction,
                        // and the confidence score.
                        if !viewModel.isLoading && viewModel.selectedImage != nil {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Prediction Result")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                HStack {
                                    Text("Model Used:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(viewModel.selectedModel.rawValue)
                                }
                                
                                HStack {
                                    Text("Top Prediction:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(viewModel.topPrediction)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                HStack {
                                    Text("Confidence:")
                                        .fontWeight(.semibold)
                                    Spacer()
                                    Text(viewModel.confidenceText)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                        }
                        
                        // This section shows the top 3 predictions from the model.
                        // This is helpful because sometimes the first answer is wrong,
                        // but the real answer might still appear in the next few results.
                        if !viewModel.topResults.isEmpty {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Top 3 Predictions")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                
                                ForEach(viewModel.topResults) { result in
                                    HStack {
                                        Text(result.label)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.2f%%", result.confidence * 100))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                        }
                        
                        // This is the ethical reminder section.
                        // The app shows this after an image is selected to remind users
                        // that AI predictions are not always fair or correct.
                        // This helps address the bias and ethics requirement in the assignment.
                        if viewModel.selectedImage != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    
                                    Text("Ethical Reminder")
                                        .font(.headline)
                                }
                                
                                Text(viewModel.biasWarning)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            
            // This applies the light or dark appearance to the whole screen
            // based on the toggle value the user selected.
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
    
    // This computed property changes the short description shown under the model picker.
    // It gives the user a quick explanation of what each model is mainly good at.
    var modelDescription: String {
        switch viewModel.selectedModel {
        case .mobileNet:
            return "Recommended model. Best balance of speed, size, and accuracy."
        case .fastViT:
            return "Comparison model. Fast and lightweight."
        case .resnet:
            return "Comparison model. Strong accuracy but larger size."
        }
    }
}
