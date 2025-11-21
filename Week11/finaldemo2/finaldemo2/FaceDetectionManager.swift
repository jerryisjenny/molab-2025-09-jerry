//
//  FaceDetectionManager.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//
//
//  FaceDetectionManager.swift
//  FaceGlitch3D
//
//  人脸检测管理器 - 使用Vision框架检测人脸
//

import UIKit
import Vision

// MARK: - Face Data Model
struct FaceData {
    let boundingBox: CGRect
    let landmarks: VNFaceLandmarks2D
    let imageSize: CGSize
}

// MARK: - Face Detection Errors
enum FaceDetectionError: Error {
    case noFaceDetected
    case multipleFacesDetected
    case invalidImage
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .noFaceDetected:
            return "未检测到人脸，请使用包含清晰人脸的照片"
        case .multipleFacesDetected:
            return "检测到多张人脸，请使用只有一张人脸的照片"
        case .invalidImage:
            return "图片格式无效"
        case .processingFailed:
            return "处理失败，请重试"
        }
    }
}

// MARK: - Face Detection Manager
class FaceDetectionManager {
    
    // 检测人脸
    func detectFace(in image: UIImage, completion: @escaping (Result<FaceData, FaceDetectionError>) -> Void) {
        
        guard let cgImage = image.cgImage else {
            completion(.failure(.invalidImage))
            return
        }
        
        // 创建人脸检测请求（包含特征点）
        let request = VNDetectFaceLandmarksRequest { request, error in
            
            if error != nil {
                completion(.failure(.processingFailed))
                return
            }
            
            guard let observations = request.results as? [VNFaceObservation] else {
                completion(.failure(.noFaceDetected))
                return
            }
            
            // 检查人脸数量
            if observations.isEmpty {
                completion(.failure(.noFaceDetected))
                return
            }
            
            if observations.count > 1 {
                completion(.failure(.multipleFacesDetected))
                return
            }
            
            // 获取人脸数据
            let observation = observations[0]
            
            guard let landmarks = observation.landmarks else {
                completion(.failure(.processingFailed))
                return
            }
            
            // 转换坐标系（Vision使用左下角为原点）
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let boundingBox = self.convertBoundingBox(observation.boundingBox, imageSize: imageSize)
            
            let faceData = FaceData(
                boundingBox: boundingBox,
                landmarks: landmarks,
                imageSize: imageSize
            )
            
            completion(.success(faceData))
        }
        
        // 执行检测
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                completion(.failure(.processingFailed))
            }
        }
    }
    
    // 转换Vision坐标系到UIKit坐标系
    private func convertBoundingBox(_ visionRect: CGRect, imageSize: CGSize) -> CGRect {
        let x = visionRect.origin.x * imageSize.width
        let y = (1 - visionRect.origin.y - visionRect.height) * imageSize.height
        let width = visionRect.width * imageSize.width
        let height = visionRect.height * imageSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // 获取特定面部特征点（用于3D建模）
    func extractKeyPoints(from landmarks: VNFaceLandmarks2D) -> [CGPoint] {
        var keyPoints: [CGPoint] = []
        
        // 提取所有可用的特征点
        if let allPoints = landmarks.allPoints {
            keyPoints.append(contentsOf: allPoints.normalizedPoints)
        }
        
        return keyPoints
    }
    
    // 获取人脸轮廓点
    func getFaceContour(from landmarks: VNFaceLandmarks2D) -> [CGPoint]? {
        return landmarks.faceContour?.normalizedPoints
    }
    
    // 获取鼻子特征点
    func getNosePoints(from landmarks: VNFaceLandmarks2D) -> [CGPoint]? {
        return landmarks.nose?.normalizedPoints
    }
    
    // 获取眼睛特征点
    func getEyePoints(from landmarks: VNFaceLandmarks2D) -> (left: [CGPoint]?, right: [CGPoint]?) {
        return (
            left: landmarks.leftEye?.normalizedPoints,
            right: landmarks.rightEye?.normalizedPoints
        )
    }
    
    // 获取嘴巴特征点
    func getMouthPoints(from landmarks: VNFaceLandmarks2D) -> [CGPoint]? {
        return landmarks.outerLips?.normalizedPoints
    }
}
