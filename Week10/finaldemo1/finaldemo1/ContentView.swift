
//
//  FaceDetectionView.swift
//  CaptureRecorder
//
//  Created by User
//

import SwiftUI
import PhotosUI

struct FaceDetectionView: View {
    @StateObject var model = FaceDetectionModel()
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // Image Display with PhotosPicker
                PhotosPicker(selection: $selectedItem) {
                    if let displayImage = model.displayImage {
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(12)
                            .shadow(radius: 10)
                    } else {
                        ContentUnavailableView(
                            "Haven't selected photo",
                            systemImage: "photo.badge.plus",
                            description: Text("Upload Image")
                        )
                        .frame(height: 400)
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                
                // Status Label
                StatusView()
                
                Spacer()
                
                // Buttons
                ButtonsView()
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Face Detection")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Detection fail", isPresented: $model.showingFailAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    

    
    func StatusView() -> some View {
        Group {
            if model.isDetecting {
                HStack {
                    ProgressView()
                    Text("Detecting...")
                        .padding(.leading, 10)
                }
            } else if let statusText = model.statusText {
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(model.statusColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 50)
    }
    
    func ButtonsView() -> some View {
        VStack(spacing: 15) {
            // Pixelate Button (only show if face detected)
            if model.faceDetected && !model.isPixelated {
                Button(action: {
                    model.pixelateImage()
                }) {
                    Text("Pixelize")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .disabled(model.isProcessing)
                .opacity(model.isProcessing ? 0.6 : 1.0)
            }
            
            // Reset Button (only show if pixelated)
            if model.isPixelated {
                Button(action: {
                    model.resetImage()
                }) {
                    Text("Reset photo")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            
            await MainActor.run {
                model.selectedImage = inputImage
                model.detectFace()
            }
        }
    }
}
//}

#Preview {
    FaceDetectionView()
}
