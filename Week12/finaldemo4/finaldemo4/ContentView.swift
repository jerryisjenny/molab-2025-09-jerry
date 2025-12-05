

import SwiftUI
import PhotosUI

struct FaceGenContentView: View {
    // State management
    enum AppState {
        case home
        case editing
        case generating3D
    }

    @State private var appState: AppState = .home
    
    @StateObject private var editorVM = FaceEditorViewModel()
    @StateObject private var threeDVM = ThreeDGeneratorViewModel()
    

    @State private var showCamera = false
    @State private var showCameraAlert = false
    

    @State private var photosPickerItem: PhotosPickerItem? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                switch appState {
                case .home:
                    HomeView().transition(.opacity)
                case .editing:
                    EditingView().transition(.opacity)
                case .generating3D:
                    GeneratingView().transition(.move(edge: .trailing))
                }
            }
            .navigationBarHidden(true)
        }
        // Error notification
        .alert("Haven't detected faces", isPresented: $editorVM.showNoFaceError) {
            Button("Retry", role: .cancel) { appState = .home }
        } message: {
            Text("Please upload images with faces")
        }
        // 相机不可用提示 (针对模拟器)
        .alert("Caamera can't be used", isPresented: $showCameraAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Please use the real phone or upload from the album")
        }
        // Camera page
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(selectedImage: Binding(
                get: { editorVM.originalImage },
                set: { img in
                    if let img = img {
                        editorVM.setImage(img)
                        appState = .editing
                    }
                }
            ))
            .ignoresSafeArea()
        }

        .onChange(of: photosPickerItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        editorVM.setImage(image)
                        appState = .editing
                        photosPickerItem = nil // Reset
                    }
                }
            }
        }
    }
    

    @ViewBuilder
    func HomeView() -> some View {
        VStack(spacing: 30) {
            Spacer()
            Text("Create your virtual avatar")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
            Image(systemName: "face.smiling.inverse")
                .resizable().scaledToFit().frame(width: 120)
                .foregroundStyle(.purple).opacity(0.8)
            Text("What are you really like?")
                .foregroundColor(.gray)
                Spacer()
            VStack(spacing: 39) {
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showCameraAlert = true
                    }
                }) {
                    Label("Take a picture", systemImage: "camera.fill")
                        .font(.title3.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(colors: [Color.purple, Color.indigo], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                

                PhotosPicker(selection: $photosPickerItem, matching: .images) {
                    Label("Select from album", systemImage: "photo.on.rectangle")
                        .font(.title3.bold())
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(
                                                LinearGradient(colors: [Color.blue, Color.indigo], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .foregroundColor(.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }.padding(.horizontal, 40).padding(.bottom, 50)
        }
    }
    
    // EditionPage
    func EditingView() -> some View {
        VStack {
            ZStack {
                            Text("Edit")
                                .font(.headline)
                                .foregroundColor(.white)
                    
                            HStack {
                                Button(action: { appState = .home }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                
                                Spacer()
                                
                                Button("Next Step") {
                                    if let result = editorVM.editedImage {
                                        threeDVM.selectedImage = result
                                        appState = .generating3D
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(Capsule())
                            }
                        }
                        .padding()
            
//make picture lokks stable
            ZStack {
                Color.clear
                if let image = editorVM.editedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .frame(maxHeight: 400)
                        .padding()
                } else {
                    ProgressView()
                }
                if editorVM.isProcessing {
                    ZStack {
                        Color.black.opacity(0.3).cornerRadius(12)
                        ProgressView("Processing...")
                            .foregroundColor(.white).padding()
                            .background(Material.ultraThinMaterial).cornerRadius(10)
                    }.frame(maxHeight: 400)
                }
            }.frame(maxWidth: .infinity, maxHeight: 400)
            
            Spacer()
            

            VStack(spacing: 20) {
                ControlRow(title: "👁️ Eyes", value: $editorVM.eyeScale, leftLabel: "Smaller", rightLabel: "Bigger")
                ControlRow(title: "👄 Mouth", value: $editorVM.mouthScale, leftLabel: "Smaller", rightLabel: "Bigger")
                ControlRow(title: "🌀 Distort", value: $editorVM.faceTwist, leftLabel: "Left", rightLabel: "Right")
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // Generation
    @ViewBuilder
    func GeneratingView() -> some View {
        VStack(spacing: 20) {
                        ZStack {
                            Text("Generating 3D Model")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Button(action: { appState = .editing }) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .foregroundColor(.white)
                                }
                                
                                Spacer() 
                            }
                        }
                        .padding()
            
            if let image = threeDVM.selectedImage {
                Image(uiImage: image)
                    .resizable().aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple, lineWidth: 2))
            }
            
            Divider()
            
            if let modelUrl = threeDVM.localModelURL {
                VStack {
                    Text("Success！").font(.title3).bold().foregroundColor(.green)
                    ModelViewer(url: modelUrl)
                        .frame(height: 250).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3)))
                    ShareLink(item: modelUrl) {
                        Label("Save the model", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue).foregroundColor(.white).cornerRadius(12)
                    }
                }.padding()
            } else {
                if threeDVM.generationState == .idle {
                    Button(action: { threeDVM.startGeneration() }) {
                        Text("Generate the 3D model")
                            .font(.title3).bold().frame(maxWidth: .infinity).padding()
                            .background(Color.green).foregroundColor(.white).cornerRadius(12)
                    }.padding()
                } else {
                    if case .processing(let s) = threeDVM.generationState {
                        Text("Creating: \(s) \(Int(threeDVM.progress * 100))%")
                    } else if case .uploading = threeDVM.generationState { Text("Uploading...") }
                    else if case .downloading = threeDVM.generationState { Text("Downloading...") }
                    else if case .failed = threeDVM.generationState {
                        Text("Failure: \(threeDVM.errorMessage ?? "")").foregroundColor(.red)
                        Button("Retry") { threeDVM.startGeneration() }
                    }
                    ProgressView().padding()
                }
            }
            Spacer()
        }
    }
    
    // Slider
    @ViewBuilder
    func ControlRow(title: String, value: Binding<Double>, leftLabel: String, rightLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title).font(.subheadline).bold()
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue)).font(.caption).foregroundColor(.gray)
            }
            HStack {
                Text(leftLabel).font(.caption2).foregroundColor(.secondary)
                Slider(value: value, in: -1.0...1.0)
                    .onChange(of: value.wrappedValue) { _ in editorVM.applyEffects() }
                    .onChange(of: value.wrappedValue) { newValue in
                        if abs(newValue) < 0.05 { value.wrappedValue = 0 }
                    }
                Text(rightLabel).font(.caption2).foregroundColor(.secondary)
            }
        }
    }
}

// Camera view

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        }
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Fix
                parent.selectedImage = image.fixOrientation()
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


struct LoadingView: View {
    let text: String
    let progress: Double
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.5)
            Text(text).font(.headline)
            if progress > 0 { ProgressView(value: progress).frame(width: 200) }
        }.padding(30).background(Color(UIColor.secondarySystemBackground)).cornerRadius(16).shadow(radius: 5)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    FaceGenContentView()
}
