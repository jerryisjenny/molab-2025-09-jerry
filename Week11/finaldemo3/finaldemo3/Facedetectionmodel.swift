//
//  Facedetectionmodel.swift
//  finaldemo3
//
//  Created by Jieyin Tan on 11/21/25.
//
//
//  ImprovedFaceDetectionModel.swift
//  finaldemo3
//
//  Enhanced version with precise landmark-based editing
//  Created by Claude on 11/21/25.
//

//
//  Facedetectionmodel.swift
//  finaldemo3
//
//  Enhanced version with improved creative elements
//  Modified by Claude on 11/21/25.
//

import SwiftUI
import Vision
import CoreImage
import CoreGraphics
import Combine
import Photos

// MARK: - Edit Mode
enum EditMode {
    case filter
    case warp
    case element
}

// MARK: - Face Effect (Filters)
enum FaceEffect: String, CaseIterable {
    case pixelate = "pixelate"
    case blur = "blur"
    case cartoon = "cartoon"
    case sketch = "sketch"
    case sepia = "sepia"
    case vignette = "vignette"
    case crystallize = "crystallize"
    case comic = "comic"
    
    var name: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .pixelate: return "square.grid.3x3.fill"
        case .blur: return "aqi.medium"
        case .cartoon: return "face.smiling"
        case .sketch: return "pencil.tip"
        case .sepia: return "camera.filters"
        case .vignette: return "circle.circle"
        case .crystallize: return "diamond.fill"
        case .comic: return "bubble.left.and.bubble.right"
        }
    }
}

// MARK: - Warp Effect
enum WarpEffect: String, CaseIterable {
    case bigEyes = "bigEyes"
    case smallEyes = "smallEyes"
    case bigNose = "bigNose"
    case smallNose = "smallNose"
    case bigMouth = "bigMouth"
    case smallMouth = "smallMouth"
    case wideface = "wideface"
    case thinFace = "thinFace"
    
    var name: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .bigEyes: return "eye.fill"
        case .smallEyes: return "eye"
        case .bigNose: return "nose.fill"
        case .smallNose: return "nose"
        case .bigMouth: return "mouth.fill"
        case .smallMouth: return "mouth"
        case .wideface: return "rectangle.expand.vertical"
        case .thinFace: return "rectangle.compress.vertical"
        }
    }
}

// MARK: - Face Element
enum FaceElement: String, CaseIterable {
    case extraEyes = "extraEyes"
    case thirdEye = "thirdEye"
    case extraMouth = "extraMouth"
    case duplicateFace = "duplicateFace"
    case mirrorFace = "mirrorFace"
    case upsideDown = "upsideDown"
    
    var name: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .extraEyes: return "eyes"
        case .thirdEye: return "eye.trianglebadge.exclamationmark"
        case .extraMouth: return "mouth"
        case .duplicateFace: return "square.on.square"
        case .mirrorFace: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .upsideDown: return "arrow.up.and.down"
        }
    }
}

// MARK: - Landmark Points Helper
struct LandmarkPoints {
    var leftEye: CGPoint?
    var rightEye: CGPoint?
    var nose: CGPoint?
    var leftMouth: CGPoint?
    var rightMouth: CGPoint?
    var mouthCenter: CGPoint?
    var chin: CGPoint?
    var leftCheek: CGPoint?
    var rightCheek: CGPoint?
    
    static func from(landmarks: VNFaceLandmarks2D, faceRect: CGRect, imageSize: CGSize) -> LandmarkPoints {
        var points = LandmarkPoints()
        
        func toImageCoordinates(_ normalizedPoints: [CGPoint]) -> [CGPoint] {
            return normalizedPoints.map { point in
                CGPoint(
                    x: faceRect.origin.x + point.x * faceRect.width,
                    y: imageSize.height - (faceRect.origin.y + point.y * faceRect.height)
                )
            }
        }
        
        if let leftEyePoints = landmarks.leftEye?.normalizedPoints {
            let eyeCoords = toImageCoordinates(Array(leftEyePoints))
            points.leftEye = eyeCoords.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            points.leftEye = CGPoint(x: points.leftEye!.x / CGFloat(eyeCoords.count),
                                   y: points.leftEye!.y / CGFloat(eyeCoords.count))
        }
        
        if let rightEyePoints = landmarks.rightEye?.normalizedPoints {
            let eyeCoords = toImageCoordinates(Array(rightEyePoints))
            points.rightEye = eyeCoords.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            points.rightEye = CGPoint(x: points.rightEye!.x / CGFloat(eyeCoords.count),
                                    y: points.rightEye!.y / CGFloat(eyeCoords.count))
        }
        
        if let nosePoints = landmarks.nose?.normalizedPoints {
            let noseCoords = toImageCoordinates(Array(nosePoints))
            points.nose = noseCoords.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            points.nose = CGPoint(x: points.nose!.x / CGFloat(noseCoords.count),
                                y: points.nose!.y / CGFloat(noseCoords.count))
        }
        
        if let outerLipsPoints = landmarks.outerLips?.normalizedPoints {
            let lipCoords = toImageCoordinates(Array(outerLipsPoints))
            if lipCoords.count >= 3 {
                points.leftMouth = lipCoords[0]
                points.rightMouth = lipCoords[lipCoords.count/2]
                points.mouthCenter = lipCoords.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                points.mouthCenter = CGPoint(x: points.mouthCenter!.x / CGFloat(lipCoords.count),
                                           y: points.mouthCenter!.y / CGFloat(lipCoords.count))
            }
        }
        
        if let faceContourPoints = landmarks.faceContour?.normalizedPoints {
            let contourCoords = toImageCoordinates(Array(faceContourPoints))
            if !contourCoords.isEmpty {
                points.chin = contourCoords[contourCoords.count/2]
                points.leftCheek = contourCoords[contourCoords.count/4]
                points.rightCheek = contourCoords[3*contourCoords.count/4]
            }
        }
        
        return points
    }
}

class ImprovedFaceDetectionModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var displayImage: UIImage?
    @Published var statusText: String?
    @Published var statusColor: Color = .white
    @Published var faceDetected: Bool = false
    @Published var isDetecting: Bool = false
    @Published var isProcessing: Bool = false
    @Published var showingFailAlert: Bool = false
    @Published var editMode: EditMode = .filter
    
    @Published var appliedEffects: Set<FaceEffect> = []
    @Published var appliedWarps: Set<WarpEffect> = []
    @Published var appliedElements: Set<FaceElement> = []
    
    var hasEdits: Bool {
        !appliedEffects.isEmpty || !appliedWarps.isEmpty || !appliedElements.isEmpty
    }
    
    private var originalImage: UIImage?
    private var context: CIContext?
    private var faceRegions: [CGRect] = []
    private var faceLandmarks: [VNFaceLandmarks2D] = []
    private var faceObservations: [VNFaceObservation] = []
    private var landmarkPoints: [LandmarkPoints] = []
    
    init() {
        context = CIContext(options: nil)
    }
    
    // MARK: - Face Detection
    func detectFace() {
        guard let image = selectedImage else { return }
        
        isDetecting = true
        statusText = "Detecting..."
        statusColor = .blue
        faceDetected = false
        displayImage = image
        originalImage = image
        faceRegions = []
        faceLandmarks = []
        faceObservations = []
        landmarkPoints = []
        clearAllEdits()
        
        guard let cgImage = image.cgImage else {
            showDetectionFail()
            return
        }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
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
                
                self.faceObservations = observations
                let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
                self.faceRegions = observations.map { observation in
                    self.convertVisionRect(observation.boundingBox, imageSize: imageSize)
                }
                
                self.faceLandmarks = observations.compactMap { $0.landmarks }
                
                // Extract landmark points for precise editing
                self.landmarkPoints = observations.compactMap { observation in
                    guard let landmarks = observation.landmarks else { return nil }
                    let faceRect = self.convertVisionRect(observation.boundingBox, imageSize: imageSize)
                    return LandmarkPoints.from(landmarks: landmarks, faceRect: faceRect, imageSize: imageSize)
                }
                
                self.faceDetected = true
                let faceCount = observations.count
                self.statusText = "Successfully detect \(faceCount) faces"
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
        statusText = "Detection Failed"
        statusColor = .red
        showingFailAlert = true
    }
    
    private func convertVisionRect(_ rect: CGRect, imageSize: CGSize) -> CGRect {
        let x = rect.origin.x * imageSize.width
        let y = (1 - rect.origin.y - rect.height) * imageSize.height
        let width = rect.width * imageSize.width
        let height = rect.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // MARK: - Edit Management
    func toggleEffect(_ effect: FaceEffect) {
        if appliedEffects.contains(effect) {
            appliedEffects.remove(effect)
        } else {
            appliedEffects.insert(effect)
        }
        updateDisplayImage()
    }
    
    func toggleWarp(_ warp: WarpEffect) {
        if appliedWarps.contains(warp) {
            appliedWarps.remove(warp)
        } else {
            appliedWarps.insert(warp)
        }
        updateDisplayImage()
    }
    
    func toggleElement(_ element: FaceElement) {
        if appliedElements.contains(element) {
            appliedElements.remove(element)
        } else {
            appliedElements.insert(element)
        }
        updateDisplayImage()
    }
    
    func clearAllEdits() {
        appliedEffects.removeAll()
        appliedWarps.removeAll()
        appliedElements.removeAll()
        displayImage = originalImage
    }
    
    func getAppliedEditsList() -> [String] {
        var edits: [String] = []
        edits.append(contentsOf: appliedEffects.map { $0.name })
        edits.append(contentsOf: appliedWarps.map { $0.name })
        edits.append(contentsOf: appliedElements.map { $0.name })
        return edits
    }
    
    // MARK: - Image Processing Pipeline
    private func updateDisplayImage() {
        guard var baseImage = originalImage else { return }
        
        isProcessing = true
        statusText = "Dealing with..."
        statusColor = .blue
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Apply filters first (to whole face regions)
            if !self.appliedEffects.isEmpty {
                if let filteredImage = self.applyFilters(to: baseImage) {
                    baseImage = filteredImage
                }
            }
            
            // Apply warps (precise landmark-based)
            if !self.appliedWarps.isEmpty {
                if let warpedImage = self.applyPreciseWarps(to: baseImage) {
                    baseImage = warpedImage
                }
            }
            
            // Apply elements (IMPROVED - real pixel manipulation)
            if !self.appliedElements.isEmpty {
                if let elementImage = self.applyImprovedElements(to: baseImage) {
                    baseImage = elementImage
                }
            }
            
            DispatchQueue.main.async {
                self.displayImage = baseImage
                self.isProcessing = false
                self.statusText = "Edition finished"
                self.statusColor = .green
            }
        }
    }
    
    // MARK: - Enhanced Warp Functions (Landmark-based) - 保持原样
    private func applyPreciseWarps(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        var resultImage = ciImage
        
        // Apply each warp effect using precise landmark positions
        for (index, landmarks) in landmarkPoints.enumerated() {
            guard index < faceRegions.count else { continue }
            let faceRect = faceRegions[index]
            
            for warp in appliedWarps {
                if let warpedImage = applyPreciseWarp(warp, to: resultImage, landmarks: landmarks, faceRect: faceRect) {
                    resultImage = warpedImage
                }
            }
        }
        
        guard let outputCGImage = context?.createCGImage(resultImage, from: resultImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func applyPreciseWarp(_ warp: WarpEffect, to ciImage: CIImage, landmarks: LandmarkPoints, faceRect: CGRect) -> CIImage? {
        var filter: CIFilter?
        
        switch warp {
        case .bigEyes, .smallEyes:
            // Apply to each eye individually using precise landmark positions
            var resultImage = ciImage
            
            if let leftEye = landmarks.leftEye {
                let center = CIVector(x: leftEye.x, y: ciImage.extent.height - leftEye.y)
                filter = CIFilter(name: "CIBumpDistortion")
                filter?.setValue(resultImage, forKey: kCIInputImageKey)
                filter?.setValue(center, forKey: kCIInputCenterKey)
                filter?.setValue(faceRect.width * 0.08, forKey: kCIInputRadiusKey)
                filter?.setValue(warp == .bigEyes ? 0.6 : -0.4, forKey: kCIInputScaleKey)
                if let output = filter?.outputImage {
                    resultImage = output
                }
            }
            
            if let rightEye = landmarks.rightEye {
                let center = CIVector(x: rightEye.x, y: ciImage.extent.height - rightEye.y)
                filter = CIFilter(name: "CIBumpDistortion")
                filter?.setValue(resultImage, forKey: kCIInputImageKey)
                filter?.setValue(center, forKey: kCIInputCenterKey)
                filter?.setValue(faceRect.width * 0.08, forKey: kCIInputRadiusKey)
                filter?.setValue(warp == .bigEyes ? 0.6 : -0.4, forKey: kCIInputScaleKey)
                if let output = filter?.outputImage {
                    resultImage = output
                }
            }
            
            return resultImage
            
        case .bigNose, .smallNose:
            guard let nose = landmarks.nose else { return nil }
            let center = CIVector(x: nose.x, y: ciImage.extent.height - nose.y)
            filter = CIFilter(name: "CIPinchDistortion")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(center, forKey: kCIInputCenterKey)
            filter?.setValue(warp == .bigNose ? -0.6 : 0.5, forKey: kCIInputScaleKey)
            filter?.setValue(faceRect.width * 0.12, forKey: kCIInputRadiusKey)
            
        case .bigMouth, .smallMouth:
            guard let mouth = landmarks.mouthCenter else { return nil }
            let center = CIVector(x: mouth.x, y: ciImage.extent.height - mouth.y)
            filter = CIFilter(name: "CIBumpDistortion")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(center, forKey: kCIInputCenterKey)
            filter?.setValue(faceRect.width * 0.1, forKey: kCIInputRadiusKey)
            filter?.setValue(warp == .bigMouth ? 0.5 : -0.4, forKey: kCIInputScaleKey)
            
        case .wideface, .thinFace:
            // Apply cheek widening/narrowing
            var resultImage = ciImage
            
            if let leftCheek = landmarks.leftCheek {
                let center = CIVector(x: leftCheek.x, y: ciImage.extent.height - leftCheek.y)
                let filterName = warp == .wideface ? "CIBumpDistortion" : "CIPinchDistortion"
                filter = CIFilter(name: filterName)
                filter?.setValue(resultImage, forKey: kCIInputImageKey)
                filter?.setValue(center, forKey: kCIInputCenterKey)
                filter?.setValue(faceRect.width * 0.15, forKey: kCIInputRadiusKey)
                filter?.setValue(warp == .wideface ? 0.4 : 0.3, forKey: kCIInputScaleKey)
                if let output = filter?.outputImage {
                    resultImage = output
                }
            }
            
            if let rightCheek = landmarks.rightCheek {
                let center = CIVector(x: rightCheek.x, y: ciImage.extent.height - rightCheek.y)
                let filterName = warp == .wideface ? "CIBumpDistortion" : "CIPinchDistortion"
                filter = CIFilter(name: filterName)
                filter?.setValue(resultImage, forKey: kCIInputImageKey)
                filter?.setValue(center, forKey: kCIInputCenterKey)
                filter?.setValue(faceRect.width * 0.15, forKey: kCIInputRadiusKey)
                filter?.setValue(warp == .wideface ? 0.4 : 0.3, forKey: kCIInputScaleKey)
                if let output = filter?.outputImage {
                    resultImage = output
                }
            }
            
            return resultImage
        }
        
        return filter?.outputImage
    }
    
    // MARK: - IMPROVED Element Application - 改进版本
    private func applyImprovedElements(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        
        // Draw original image
        image.draw(at: .zero)
        
        // Apply improved elements with real pixel manipulation
        for (index, faceRect) in faceRegions.enumerated() {
            guard index < landmarkPoints.count else { continue }
            let landmarks = landmarkPoints[index]
            
            for element in appliedElements {
                drawImprovedElement(element, context: context, image: image, cgImage: cgImage, faceRect: faceRect, landmarks: landmarks)
            }
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    // MARK: - Draw Improved Elements - 核心改进
    private func drawImprovedElement(_ element: FaceElement, context: CGContext, image: UIImage, cgImage: CGImage, faceRect: CGRect, landmarks: LandmarkPoints) {
        
        switch element {
        case .upsideDown:
            // 倒置脸 - 真实旋转
            drawUpsideDownFace(context: context, cgImage: cgImage, faceRect: faceRect)
            
        case .mirrorFace:
            // 镜像脸 - 真实镜像
            drawMirrorFace(context: context, cgImage: cgImage, faceRect: faceRect)
            
        case .duplicateFace:
            // 分裂脸 - 真实分离
            drawSplitFace(context: context, cgImage: cgImage, faceRect: faceRect)
            
        case .extraMouth:
            // 多嘴巴 - 复制真实像素
            drawMultipleMouths(context: context, cgImage: cgImage, faceRect: faceRect, landmarks: landmarks)
            
        case .thirdEye:
            // 第三只眼 - 智能融合
            drawThirdEye(context: context, cgImage: cgImage, faceRect: faceRect, landmarks: landmarks)
            
        case .extraEyes:
            // 多眼睛 - 复制眼睛区域
            drawExtraEyes(context: context, cgImage: cgImage, faceRect: faceRect, landmarks: landmarks)
        }
    }
    
    // MARK: - Individual Improved Effect Implementations
    
    private func drawUpsideDownFace(context: CGContext, cgImage: CGImage, faceRect: CGRect) {
        guard let faceImage = cgImage.cropping(to: faceRect) else { return }
        
        context.saveGState()
        context.translateBy(x: faceRect.midX, y: faceRect.midY)
        context.rotate(by: .pi)
        context.translateBy(x: -faceRect.midX, y: -faceRect.midY)
        context.draw(faceImage, in: faceRect)
        context.restoreGState()
    }
    
    private func drawMirrorFace(context: CGContext, cgImage: CGImage, faceRect: CGRect) {
        let leftHalfRect = CGRect(
            x: faceRect.minX,
            y: faceRect.minY,
            width: faceRect.width / 2,
            height: faceRect.height
        )
        
        guard let leftHalf = cgImage.cropping(to: leftHalfRect) else { return }
        
        let rightHalfRect = CGRect(
            x: faceRect.midX,
            y: faceRect.minY,
            width: faceRect.width / 2,
            height: faceRect.height
        )
        
        context.saveGState()
        context.translateBy(x: rightHalfRect.midX, y: rightHalfRect.midY)
        context.scaleBy(x: -1, y: 1)
        context.translateBy(x: -rightHalfRect.midX, y: -rightHalfRect.midY)
        context.draw(leftHalf, in: rightHalfRect)
        context.restoreGState()
        
        // Blend center seam
        let blendRect = CGRect(x: faceRect.midX - 3, y: faceRect.minY, width: 6, height: faceRect.height)
        if let blendRegion = cgImage.cropping(to: blendRect) {
            context.setAlpha(0.5)
            context.draw(blendRegion, in: blendRect)
            context.setAlpha(1.0)
        }
    }
    
    private func drawSplitFace(context: CGContext, cgImage: CGImage, faceRect: CGRect) {
        let splitOffset: CGFloat = 15
        
        let leftHalfRect = CGRect(x: faceRect.minX, y: faceRect.minY, width: faceRect.width / 2, height: faceRect.height)
        if let leftHalf = cgImage.cropping(to: leftHalfRect) {
            let shiftedLeftRect = leftHalfRect.offsetBy(dx: -splitOffset, dy: 0)
            context.setFillColor(UIColor.black.cgColor)
            context.fill(leftHalfRect)
            context.draw(leftHalf, in: shiftedLeftRect)
        }
        
        let rightHalfRect = CGRect(x: faceRect.midX, y: faceRect.minY, width: faceRect.width / 2, height: faceRect.height)
        if let rightHalf = cgImage.cropping(to: rightHalfRect) {
            let shiftedRightRect = rightHalfRect.offsetBy(dx: splitOffset, dy: 0)
            context.setFillColor(UIColor.black.cgColor)
            context.fill(rightHalfRect)
            context.draw(rightHalf, in: shiftedRightRect)
        }
        
        // Draw crack
        context.setStrokeColor(UIColor.darkGray.cgColor)
        context.setLineWidth(2)
        context.move(to: CGPoint(x: faceRect.midX, y: faceRect.minY))
        context.addLine(to: CGPoint(x: faceRect.midX, y: faceRect.maxY))
        context.strokePath()
        
        // Add jagged details
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        var y = faceRect.minY
        while y < faceRect.maxY {
            let offset = CGFloat.random(in: -4...4)
            context.move(to: CGPoint(x: faceRect.midX, y: y))
            context.addLine(to: CGPoint(x: faceRect.midX + offset, y: y + 8))
            y += 12
        }
        context.strokePath()
    }
    
    private func drawMultipleMouths(context: CGContext, cgImage: CGImage, faceRect: CGRect, landmarks: LandmarkPoints) {
        guard let mouthCenter = landmarks.mouthCenter else { return }
        
        let mouthWidth = faceRect.width * 0.4
        let mouthHeight = faceRect.height * 0.12
        let padding: CGFloat = 10
        
        let mouthRect = CGRect(
            x: mouthCenter.x - mouthWidth / 2 - padding,
            y: mouthCenter.y - mouthHeight / 2 - padding,
            width: mouthWidth + padding * 2,
            height: mouthHeight + padding * 2
        )
        
        guard let mouthImage = cgImage.cropping(to: mouthRect) else { return }
        
        let positions: [(CGFloat, CGFloat, CGFloat)] = [
            (0, -mouthRect.height * 1.3, 0.85),
            (0, mouthRect.height * 1.3, 0.85),
            (-mouthRect.width * 0.7, 0, 0.8),
            (mouthRect.width * 0.7, 0, 0.8)
        ]
        
        for (offsetX, offsetY, alpha) in positions {
            let newRect = mouthRect.offsetBy(dx: offsetX, dy: offsetY)
            
            if newRect.minX >= 0 && newRect.maxX <= CGFloat(cgImage.width) &&
               newRect.minY >= 0 && newRect.maxY <= CGFloat(cgImage.height) {
                context.saveGState()
                context.setAlpha(alpha)
                context.draw(mouthImage, in: newRect)
                context.restoreGState()
            }
        }
    }
    
    private func drawThirdEye(context: CGContext, cgImage: CGImage, faceRect: CGRect, landmarks: LandmarkPoints) {
        guard let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye else { return }
        
        let eyeSize = faceRect.width * 0.15
        let eyeRect = CGRect(
            x: rightEye.x - eyeSize / 2,
            y: rightEye.y - eyeSize * 0.35,
            width: eyeSize,
            height: eyeSize * 0.7
        )
        
        guard let eyeImage = cgImage.cropping(to: eyeRect) else { return }
        
        let thirdEyeX = (leftEye.x + rightEye.x) / 2
        let thirdEyeY = max(leftEye.y, rightEye.y) - eyeRect.height * 1.2
        
        let thirdEyeRect = CGRect(
            x: thirdEyeX - eyeRect.width * 0.55,
            y: thirdEyeY - eyeRect.height * 0.5,
            width: eyeRect.width * 1.1,
            height: eyeRect.height * 1.1
        )
        
        context.saveGState()
        context.setAlpha(0.92)
        context.draw(eyeImage, in: thirdEyeRect)
        context.restoreGState()
    }
    
    private func drawExtraEyes(context: CGContext, cgImage: CGImage, faceRect: CGRect, landmarks: LandmarkPoints) {
        guard let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye else { return }
        
        let eyeDistance = abs(rightEye.x - leftEye.x)
        let eyesRect = CGRect(
            x: leftEye.x - eyeDistance * 0.1,
            y: min(leftEye.y, rightEye.y) - faceRect.height * 0.04,
            width: eyeDistance * 1.2,
            height: faceRect.height * 0.15
        )
        
        guard let eyesImage = cgImage.cropping(to: eyesRect) else { return }
        
        let extraRect = eyesRect.offsetBy(dx: 0, dy: -eyesRect.height * 1.2)
        
        context.saveGState()
        context.setAlpha(0.88)
        context.draw(eyesImage, in: extraRect)
        context.restoreGState()
    }
    
    // MARK: - Filter Application - 保持原样
    private func applyFilters(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        var resultImage = ciImage
        
        for faceRect in faceRegions {
            for effect in appliedEffects {
                if let filteredImage = applyFilterToFace(effect, ciImage: resultImage, faceRect: faceRect) {
                    resultImage = filteredImage
                }
            }
        }
        
        guard let outputCGImage = context?.createCGImage(resultImage, from: resultImage.extent) else { return nil }
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func applyFilterToFace(_ effect: FaceEffect, ciImage: CIImage, faceRect: CGRect) -> CIImage? {
        let faceRegion = CGRect(
            x: faceRect.origin.x,
            y: ciImage.extent.height - faceRect.origin.y - faceRect.height,
            width: faceRect.width,
            height: faceRect.height
        )
        
        let faceImage = ciImage.cropped(to: faceRegion)
        var filteredFace: CIImage?
        
        switch effect {
        case .pixelate:
            let filter = CIFilter(name: "CIPixellate")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(max(8.0, faceRect.width * 0.02), forKey: kCIInputScaleKey)
            filteredFace = filter?.outputImage
            
        case .blur:
            let filter = CIFilter(name: "CIGaussianBlur")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(3.0, forKey: kCIInputRadiusKey)
            filteredFace = filter?.outputImage
            
        case .sepia:
            let filter = CIFilter(name: "CISepiaTone")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(0.8, forKey: kCIInputIntensityKey)
            filteredFace = filter?.outputImage
            
        case .vignette:
            let filter = CIFilter(name: "CIVignette")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            filteredFace = filter?.outputImage
            
        case .crystallize:
            let filter = CIFilter(name: "CICrystallize")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(max(15.0, faceRect.width * 0.05), forKey: kCIInputRadiusKey)
            filteredFace = filter?.outputImage
            
        case .cartoon, .sketch, .comic:
            let filter = CIFilter(name: "CIColorPosterize")
            filter?.setValue(faceImage, forKey: kCIInputImageKey)
            filter?.setValue(6, forKey: "inputLevels")
            filteredFace = filter?.outputImage
        }
        
        guard let filtered = filteredFace else { return nil }
        
        let compositeFilter = CIFilter(name: "CISourceAtopCompositing")
        compositeFilter?.setValue(filtered, forKey: kCIInputImageKey)
        compositeFilter?.setValue(ciImage, forKey: kCIInputBackgroundImageKey)
        
        return compositeFilter?.outputImage
    }
    
    // MARK: - Save Image
    func saveImage() {
        guard let image = displayImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                DispatchQueue.main.async {
                    self.statusText = "Save to the album"
                    self.statusColor = .green
                }
            }
        }
    }
}
