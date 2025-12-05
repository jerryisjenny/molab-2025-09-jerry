//
//  FaceEditorViewModel.swift
//  finaldemo4
//
//  Created by Jieyin Tan on 12/5/25.
//
//
//  FaceEditorViewModel.swift
//  finaldemo4
//
//  Created by Jieyin Tan on 11/26/25.
//

import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

@MainActor
class FaceEditorViewModel: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var editedImage: UIImage?
    

    @Published var eyeScale: Double = 0.0
    @Published var faceTwist: Double = 0.0
    @Published var mouthScale: Double = 0.0
    
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var showNoFaceError: Bool = false
    
    private let context = CIContext()
    
    // Detecting faces
    func setImage(_ image: UIImage) {
        self.originalImage = image
        self.editedImage = image
        // Reset
        self.eyeScale = 0.0
        self.faceTwist = 0.0
        self.mouthScale = 0.0
        
        detectFace(in: image)
    }
    
    private func detectFace(in image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        
        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                self.showNoFaceError = false
            } else {
                self.showNoFaceError = true
                self.originalImage = nil
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up)
        try? handler.perform([request])
    }
    
    // Apply Effects
    func applyEffects() {
        guard let original = originalImage, let ciInput = CIImage(image: original) else { return }
        

        if abs(eyeScale) < 0.05 && abs(faceTwist) < 0.05 && abs(mouthScale) < 0.05 {
            self.editedImage = original
            return
        }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInteractive).async {
            let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
                guard let self = self, let faces = request.results as? [VNFaceObservation] else { return }
                
                var resultImage = ciInput
                
                for face in faces {
                    guard let landmarks = face.landmarks else { continue }
                    let box = face.boundingBox
                    let size = original.size
                    
                    // 1. Eyes
                    if abs(self.eyeScale) > 0.05 {
                        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
                            let leftCenter = self.getPoint(points: leftEye.normalizedPoints, boundingBox: box, size: size)
                            let rightCenter = self.getPoint(points: rightEye.normalizedPoints, boundingBox: box, size: size)
                            let eyeWidth = self.calculateRegionWidth(points: leftEye.normalizedPoints, boundingBox: box, size: size)
                            let radius = Float(eyeWidth * 2.0)
                            let scale = Float(self.eyeScale)
                            
                            resultImage = self.applyBump(to: resultImage, center: leftCenter, radius: radius, scale: scale)
                            resultImage = self.applyBump(to: resultImage, center: rightCenter, radius: radius, scale: scale)
                        }
                    }
                    
                    // 2. Mouth
                    if abs(self.mouthScale) > 0.05, let lips = landmarks.outerLips {
                        let mouthCenter = self.getPoint(points: lips.normalizedPoints, boundingBox: box, size: size)
                        let mouthWidth = self.calculateRegionWidth(points: lips.normalizedPoints, boundingBox: box, size: size)
                        let radius = Float(mouthWidth * 1.5)
                        let scale = Float(self.mouthScale)
                        resultImage = self.applyBump(to: resultImage, center: mouthCenter, radius: radius, scale: scale)
                    }
                    
                    // 3. Twist
                    if abs(self.faceTwist) > 0.05 {
                        let faceCenter = self.getBoundingBoxCenter(boundingBox: box, size: size)
                        let faceWidth = box.width * size.width
                        let filter = CIFilter.twirlDistortion()
                        filter.inputImage = resultImage
                        filter.center = faceCenter
                        filter.radius = Float(faceWidth / 1.5)
                        filter.angle = Float(self.faceTwist * 1.5)
                        if let output = filter.outputImage { resultImage = output }
                    }
                }
                
                // Maintain scale and orientation
   
                if let cgImage = self.context.createCGImage(resultImage, from: resultImage.extent) {
                    let processed = UIImage(cgImage: cgImage, scale: original.scale, orientation: original.imageOrientation)
                    DispatchQueue.main.async {
                        self.editedImage = processed
                        self.isProcessing = false
                    }
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: ciInput, orientation: .up)
            try? handler.perform([request])
        }
    }
    

    private func applyBump(to input: CIImage, center: CGPoint, radius: Float, scale: Float) -> CIImage {
        let filter = CIFilter.bumpDistortion()
        filter.inputImage = input
        filter.center = center
        filter.radius = radius
        filter.scale = scale
        return filter.outputImage ?? input
    }
    
    private func getPoint(points: [CGPoint], boundingBox: CGRect, size: CGSize) -> CGPoint {
        let centerPoint = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let avgPoint = CGPoint(x: centerPoint.x / CGFloat(points.count), y: centerPoint.y / CGFloat(points.count))
        let x = (boundingBox.origin.x + avgPoint.x * boundingBox.size.width) * size.width
        let y = (boundingBox.origin.y + avgPoint.y * boundingBox.size.height) * size.height
        return CGPoint(x: x, y: y)
    }
    
    private func calculateRegionWidth(points: [CGPoint], boundingBox: CGRect, size: CGSize) -> CGFloat {
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        return (maxX - minX) * boundingBox.width * size.width
    }
    
    private func getBoundingBoxCenter(boundingBox: CGRect, size: CGSize) -> CGPoint {
        let x = (boundingBox.origin.x + boundingBox.width / 2) * size.width
        let y = (boundingBox.origin.y + boundingBox.height / 2) * size.height
        return CGPoint(x: x, y: y)
    }
}
