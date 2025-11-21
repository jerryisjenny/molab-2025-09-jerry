//
//  ContentView.swift
//  finaldemo3
//
//  Created by Jieyin Tan on 11/21/25.
//
//
//  ImprovedContentView.swift
//  finaldemo3
//
//  Enhanced UI for precise face editing
//  Created by Claude on 11/21/25.
//

import SwiftUI
import PhotosUI

struct ImprovedFaceDetectionView: View {
    @StateObject var model = ImprovedFaceDetectionModel()
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showEditMode = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Spacer()
                
                // Image Display with Enhanced Preview
                EnhancedImageDisplayView()
                
                // Status Label
                StatusView()
                
                Spacer()
                
                // Edit Options (show when face detected)
                if model.faceDetected {
                    EditOptionsView()
                }
                
                // Buttons
                ButtonsView()
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .navigationTitle("Face edition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.hasEdits {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clean all") {
                            model.clearAllEdits()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .alert("Detection failed", isPresented: $model.showingFailAlert) {
            Button("Sure", role: .cancel) { }
        } message: {
            Text("Please upload the photo with face")
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $model.selectedImage, onImageCaptured: {
                model.detectFace()
            })
        }
    }
    
    func EnhancedImageDisplayView() -> some View {
        ZStack {
            if let displayImage = model.displayImage {
                VStack(spacing: 10) {
                    // Image with maintained aspect ratio
                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(model.faceDetected ? Color.green : Color.clear, lineWidth: 2)
                        )
                    
                    // Processing indicator overlay
                    if model.isProcessing {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Dealing with...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                    }
                }
            } else {
                VStack(spacing: 30) {
                    ContentUnavailableView(
                        "Haven't selected photo",
                        systemImage: "photo.badge.plus",
                        description: Text("Select photo")
                    )
                    
                    HStack(spacing: 20) {
                        PhotosPicker(selection: $selectedItem) {
                            VStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 40))
                                Text("Album")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        .onChange(of: selectedItem, loadImage)
                        
                        Button(action: { showCamera = true }) {
                            VStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 40))
                                Text("Take a photo")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .frame(height: 400)
            }
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
            } else if model.isProcessing {
                HStack {
                    ProgressView()
                    Text("Dealing with...")
                        .padding(.leading, 10)
                }
            } else if let statusText = model.statusText {
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(model.statusColor)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minHeight: 40)
    }
    
    func EditOptionsView() -> some View {
        VStack(spacing: 15) {
            // Enhanced tabs with descriptions
            VStack(spacing: 5) {
                Picker("Edition mode", selection: $model.editMode) {
                    Text("Filter").tag(EditMode.filter)
                    Text("Face edition").tag(EditMode.warp)
                    Text("Weired changes").tag(EditMode.element)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Mode description
                Text(getModeDescription())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            // Content based on selected mode
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    switch model.editMode {
                    case .filter:
                        FilterOptionsView()
                    case .warp:
                        EnhancedWarpOptionsView()
                    case .element:
                        EnhancedElementOptionsView()
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 100)
            
            // Applied edits summary with enhanced UI
            if model.hasEdits {
                AppliedEditsView()
            }
        }
    }
    
    func getModeDescription() -> String {
        switch model.editMode {
        case .filter:
            return "Adapting filter"
        case .warp:
            return "Editing details"
        case .element:
            return "Adding weired element"
        }
    }
    
    func FilterOptionsView() -> some View {
        ForEach(FaceEffect.allCases, id: \.self) { effect in
            EnhancedEffectButton(
                effect: effect,
                isApplied: model.appliedEffects.contains(effect)
            ) {
                model.toggleEffect(effect)
            }
        }
    }
    
    func EnhancedWarpOptionsView() -> some View {
        ForEach(WarpEffect.allCases, id: \.self) { warp in
            EnhancedWarpButton(
                warp: warp,
                isApplied: model.appliedWarps.contains(warp)
            ) {
                model.toggleWarp(warp)
            }
        }
    }
    
    func EnhancedElementOptionsView() -> some View {
        ForEach(FaceElement.allCases, id: \.self) { element in
            EnhancedElementButton(
                element: element,
                isApplied: model.appliedElements.contains(element)
            ) {
                model.toggleElement(element)
            }
        }
    }
    
    func AppliedEditsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Added edition:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(model.getAppliedEditsList().count) 项")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(model.getAppliedEditsList(), id: \.self) { edit in
                        Text(edit)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    func ButtonsView() -> some View {
        VStack(spacing: 15) {
            if model.displayImage != nil {
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItem) {
                        Label("Select photo", systemImage: "photo")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .onChange(of: selectedItem, loadImage)
                    
                    Button(action: { showCamera = true }) {
                        Label("Take a picture", systemImage: "camera")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    if model.hasEdits {
                        Button(action: { model.saveImage() }) {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
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

// MARK: - Enhanced Button Views

struct EnhancedEffectButton: View {
    let effect: FaceEffect
    let isApplied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: effect.icon)
                    .font(.system(size: 28, weight: .medium))
                Text(effect.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isApplied ?
                         LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                         LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .foregroundColor(isApplied ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isApplied ? Color.blue : Color.gray.opacity(0.3), lineWidth: isApplied ? 2 : 1)
            )
            .scaleEffect(isApplied ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isApplied)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedWarpButton: View {
    let warp: WarpEffect
    let isApplied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Image(systemName: warp.icon)
                        .font(.system(size: 28, weight: .medium))
                    
                    if isApplied {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .background(Circle().fill(.purple).frame(width: 18, height: 18))
                            .offset(x: 15, y: -15)
                    }
                }
                
                Text(warp.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isApplied ?
                         LinearGradient(colors: [.purple, .purple.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                         LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .foregroundColor(isApplied ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isApplied ? Color.purple : Color.gray.opacity(0.3), lineWidth: isApplied ? 2 : 1)
            )
            .scaleEffect(isApplied ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isApplied)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedElementButton: View {
    let element: FaceElement
    let isApplied: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Image(systemName: element.icon)
                        .font(.system(size: 28, weight: .medium))
                    
                    if isApplied {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .offset(x: 15, y: -15)
                    }
                }
                
                Text(element.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isApplied ?
                         LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                         LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .foregroundColor(isApplied ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isApplied ? Color.orange : Color.gray.opacity(0.3), lineWidth: isApplied ? 2 : 1)
            )
            .scaleEffect(isApplied ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isApplied)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Camera View (keeping the same implementation)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageCaptured: () -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageCaptured()
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ImprovedFaceDetectionView()
}
