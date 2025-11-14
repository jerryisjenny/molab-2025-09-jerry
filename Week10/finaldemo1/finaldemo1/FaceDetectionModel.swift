
import SwiftUI
import Vision
import CoreImage
import Combine

class FaceDetectionModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var displayImage: UIImage?
    @Published var statusText: String?
    @Published var statusColor: Color = .white
    @Published var faceDetected: Bool = false
    @Published var isDetecting: Bool = false
    @Published var isProcessing: Bool = false
    @Published var isPixelated: Bool = false
    @Published var showingFailAlert: Bool = false
    
    private var originalImage: UIImage?
    private var context: CIContext?
    
    init() {
        context = CIContext(options: nil)
    }
    

    
    func detectFace() {
        guard let image = selectedImage else { return }
        
        isDetecting = true
        statusText = "Detecting..."
        statusColor = .blue
        faceDetected = false
        isPixelated = false
        displayImage = image
        originalImage = image
        
        guard let cgImage = image.cgImage else {
            showDetectionFail()
            return
        }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isDetecting = false
                
                if let error = error {
                    print("Face detection error: \(error.localizedDescription)")
                    self.showDetectionFail()
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      !observations.isEmpty else {
                    self.showDetectionFail()
                    return
                }
                
                // Face detected successfully
                self.faceDetected = true
                self.statusText = "✓ Detected \(observations.count) face"
                self.statusColor = .green
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform request: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.showDetectionFail()
                }
            }
        }
    }
    
    private func showDetectionFail() {
        faceDetected = false
        isDetecting = false
        statusText = "Detection fail"
        statusColor = .red
        showingFailAlert = true
    }
    
 
    
    func pixelateImage() {
        guard let image = originalImage else { return }
        
        isProcessing = true
        statusText = "Editing..."
        statusColor = .blue
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if let pixelatedImage = self.applyPixelateFilter(to: image) {
                DispatchQueue.main.async {
                    self.displayImage = pixelatedImage
                    self.isPixelated = true
                    self.statusText = "Finish"
                    self.statusColor = .green
                    self.isProcessing = false
                }
            } else {
                DispatchQueue.main.async {
                    self.statusText = "Edition failed"
                    self.statusColor = .red
                    self.isProcessing = false
                }
            }
        }
    }
    
    func resetImage() {
        guard let original = originalImage else { return }
        displayImage = original
        isPixelated = false
        statusText = "Successfully Reset"
        statusColor = .blue
    }
    

    
    private func applyPixelateFilter(to image: UIImage, pixelSize: CGFloat = 20) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(image: image) ?? CIImage(cgImage: cgImage)
        
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(pixelSize, forKey: kCIInputScaleKey)
        
        guard let outputImage = filter.outputImage,
              let context = context,
              let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
