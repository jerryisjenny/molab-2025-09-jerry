import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var originalImage: UIImage?
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var shuffleMode: ShuffleMode = .none
    @State private var shuffleSeed = 0
    
    let context = CIContext()
    
    enum ShuffleMode: String, CaseIterable {
        case none = "Original"
        case twist = "Twist"
        case bumpDistortion = "Bump"
        case circularWrap = "Circular"
        case torusLens = "Torus"
        
        var icon: String {
            switch self {
            case .none: return "square.grid.2x2"
            case .twist: return "tornado"
            case .bumpDistortion: return "circle.hexagongrid.fill"
            case .circularWrap: return "circle.circle"
            case .torusLens: return "circle.tophalf.filled"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                // Photo Picker and Image Display
                PhotosPicker(selection: $selectedItem) {
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                    } else {
                        ContentUnavailableView(
                            "No Photo",
                            systemImage: "photo.badge.plus",
                            description: Text("Tap to import a photo")
                        )
                        .frame(height: 400)
                    }
                }
                .buttonStyle(.plain)
                .onChange(of: selectedItem, loadImage)
                Spacer()
                // Intensity Slider
                VStack(spacing: 15) {
                    HStack {
                        Text("Crystallize Intensity")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(filterIntensity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $filterIntensity, in: 0...1)
                        .onChange(of: filterIntensity) {
                            applyProcessing()
                        }
                        .tint(.blue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                // Shuffle Mode Selection
                VStack(spacing: 10) {
                    Text("Distortion Effect")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ShuffleMode.allCases, id: \.self) { mode in
                                Button(action: {
                                    shuffleMode = mode
                                    if mode != .none {
                                        shuffleSeed += 1
                                    }
                                    applyProcessing()
                                }) {
                                    VStack {
                                        Image(systemName: mode.icon)
                                            .font(.system(size: 24))
                                        Text(mode.rawValue)
                                            .font(.caption)
                                    }
                                    .frame(width: 70, height: 60)
                                    .foregroundColor(shuffleMode == mode ? .white : .primary)
                                    .background(shuffleMode == mode ? Color.purple : Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                                .disabled(originalImage == nil)
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal)
                // Action Buttons
                HStack(spacing: 15) {
                    Button(action: randomizeShuffle) {
                        Label("Randomize", systemImage: "dice.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(originalImage != nil && shuffleMode != .none ? Color.orange : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(originalImage == nil || shuffleMode == .none)
                    Button(action: resetImage) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(originalImage != nil ? Color.red : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(originalImage == nil)
                }
                .padding(.horizontal)
                // Share Button
                if let processedImage {
                    ShareLink(
                        item: processedImage,
                        preview: SharePreview("Crystal Art", image: processedImage)
                    ) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
            .navigationTitle("Crystal Art Studio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self),
                  let inputImage = UIImage(data: imageData) else { return }
            
            originalImage = inputImage
            shuffleMode = .none
            shuffleSeed = 0
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        guard let originalImage = originalImage else { return }
        let beginImage = CIImage(image: originalImage)
        // Apply crystallize filter
        let crystallizeFilter = CIFilter.crystallize()
        crystallizeFilter.inputImage = beginImage
        crystallizeFilter.center = CGPoint(x: beginImage!.extent.width / 2, y: beginImage!.extent.height / 2)
        crystallizeFilter.radius = Float(filterIntensity * 50 + 5)
        
        guard var outputImage = crystallizeFilter.outputImage else { return }
        
        // Apply selected distortion effect
        if shuffleMode != .none {
            outputImage = applyDistortionEffect(to: outputImage, mode: shuffleMode)
        }
        
        // Convert to UIImage and display
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    func randomizeShuffle() {
        shuffleSeed += 1
        applyProcessing()
    }
    
    func resetImage() {
        shuffleMode = .none
        shuffleSeed = 0
        filterIntensity = 0.5
        applyProcessing()
    }
    
    func applyDistortionEffect(to image: CIImage, mode: ShuffleMode) -> CIImage {
        switch mode {
        case .none:
            return image
            
        case .twist:
            // Apply a twirl distortion
            let twirlFilter = CIFilter.twirlDistortion()
            twirlFilter.inputImage = image
            twirlFilter.center = CGPoint(x: image.extent.width / 2, y: image.extent.height / 2)
            twirlFilter.radius = Float(min(image.extent.width, image.extent.height) * 0.4)
            
            // Vary the angle based on seed
            let angles: [Float] = [Float.pi / 2, Float.pi, Float.pi * 1.5, Float.pi * 2]
            twirlFilter.angle = angles[shuffleSeed % angles.count]
            
            return twirlFilter.outputImage ?? image
            
        case .bumpDistortion:
            // Apply bump distortion
            let bumpFilter = CIFilter.bumpDistortion()
            bumpFilter.inputImage = image
            bumpFilter.center = CGPoint(x: image.extent.width / 2, y: image.extent.height / 2)
            bumpFilter.radius = Float(min(image.extent.width, image.extent.height) * 0.35)
            bumpFilter.scale = 0.5 + Float(shuffleSeed % 5) * 0.2
            
            return bumpFilter.outputImage ?? image
            
        case .circularWrap:
            // Apply circular wrap distortion
            let circularFilter = CIFilter.circularWrap()
            circularFilter.inputImage = image
            circularFilter.center = CGPoint(x: image.extent.width / 2, y: image.extent.height / 2)
            circularFilter.radius = Float(min(image.extent.width, image.extent.height) * 0.25)
            
            // Vary the angle based on seed
            let angles: [Float] = [0, Float.pi / 4, Float.pi / 2, Float.pi * 0.75]
            circularFilter.angle = angles[shuffleSeed % angles.count]
            
            return circularFilter.outputImage ?? image
            
        case .torusLens:
            // Apply torus lens distortion for an interesting effect
            let torusFilter = CIFilter.torusLensDistortion()
            torusFilter.inputImage = image
            torusFilter.center = CGPoint(x: image.extent.width / 2, y: image.extent.height / 2)
            torusFilter.radius = Float(min(image.extent.width, image.extent.height) * 0.4)
            torusFilter.width = Float(80 + (shuffleSeed % 4) * 20)
            torusFilter.refraction = 1.5 + Float(shuffleSeed % 3) * 0.2
            
            return torusFilter.outputImage ?? image
        }
    }
}

#Preview {
    ContentView()
}
