//
//  Model3DGenerator.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//
//
//  Model3DGenerator.swift
//  FaceGlitch3D
//
//  3D模型生成器 - 从2D人脸照片生成低面数3D模型
//

import UIKit
import SceneKit
import Vision

enum Model3DError: Error {
    case invalidData
    case generationFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidData:
            return "数据无效"
        case .generationFailed:
            return "3D模型生成失败"
        }
    }
}

class Model3DGenerator {
    
    // 网格分辨率（数值越小越抽象/低面数）
    private let meshResolution: Int = 25
    
    // MARK: - Main Generation Function
    func generate3DModel(from image: UIImage, faceData: FaceData, completion: @escaping (Result<SCNNode, Model3DError>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 1. 从人脸特征点生成3D顶点
            let vertices = self.generate3DVertices(from: faceData)
            
            // 2. 创建纹理坐标
            let texCoords = self.generateTextureCoordinates(faceData: faceData)
            
            // 3. 生成三角形网格
            let indices = self.generateTriangleIndices()
            
            // 4. 创建SceneKit几何体
            guard let geometry = self.createGeometry(
                vertices: vertices,
                texCoords: texCoords,
                indices: indices
            ) else {
                completion(.failure(.generationFailed))
                return
            }
            
            // 5. 创建节点并应用材质
            let faceNode = SCNNode(geometry: geometry)
            self.applyMaterial(to: faceNode, texture: image, style: .scanStyle)
            
            completion(.success(faceNode))
        }
    }
    
    // MARK: - Generate 3D Vertices
    private func generate3DVertices(from faceData: FaceData) -> [SCNVector3] {
        
        var vertices: [SCNVector3] = []
        
        let resolution = meshResolution
        
        // 创建网格点
        for y in 0...resolution {
            for x in 0...resolution {
                let u = Float(x) / Float(resolution)
                let v = Float(y) / Float(resolution)
                
                // 计算该点的深度（Z轴）
                let depth = calculateDepth(u: u, v: v, landmarks: faceData.landmarks)
                
                // 转换到[-0.5, 0.5]范围，便于居中显示
                let vertex = SCNVector3(
                    u - 0.5,
                    v - 0.5,
                    depth
                )
                
                vertices.append(vertex)
            }
        }
        
        return vertices
    }
    
    // MARK: - Calculate Depth (核心算法)
    private func calculateDepth(u: Float, v: Float, landmarks: VNFaceLandmarks2D) -> Float {
        
        let point = CGPoint(x: CGFloat(u), y: CGFloat(v))
        var depth: Float = 0.0
        
        // 基础深度：根据到中心的距离
        let centerX: Float = 0.5
        let centerY: Float = 0.5
        let distanceFromCenter = sqrtf(powf(u - centerX, 2) + powf(v - centerY, 2))
        
        // 创建基础凸起（中心向外）
        let baseDepth: Float = 0.15 * (1.0 - min(distanceFromCenter * 1.5, 1.0))
        depth = baseDepth
        
        // 增强鼻子区域
        if let nosePoints = landmarks.nose?.normalizedPoints {
            let noseDepth = calculateRegionDepth(point: point,
                                                 regionPoints: nosePoints,
                                                 maxDepth: 0.35,
                                                 falloff: 0.08)
            depth = max(depth, noseDepth)
        }
        
        // 眼睛区域稍微凹陷
        if let leftEye = landmarks.leftEye?.normalizedPoints {
            let eyeDepth = calculateRegionDepth(point: point,
                                               regionPoints: leftEye,
                                               maxDepth: 0.08,
                                               falloff: 0.05)
            depth = max(depth, eyeDepth)
        }
        
        if let rightEye = landmarks.rightEye?.normalizedPoints {
            let eyeDepth = calculateRegionDepth(point: point,
                                               regionPoints: rightEye,
                                               maxDepth: 0.08,
                                               falloff: 0.05)
            depth = max(depth, eyeDepth)
        }
        
        // 嘴巴区域
        if let mouth = landmarks.outerLips?.normalizedPoints {
            let mouthDepth = calculateRegionDepth(point: point,
                                                 regionPoints: mouth,
                                                 maxDepth: 0.12,
                                                 falloff: 0.06)
            depth = max(depth, mouthDepth)
        }
        
        // 前额区域
        let foreheadFactor = max(0, (0.7 - Float(v)) / 0.2)
        depth = max(depth, 0.05 * foreheadFactor)
        
        return depth
    }
    
    // 计算到特征区域的深度
    private func calculateRegionDepth(point: CGPoint, regionPoints: [CGPoint], maxDepth: Float, falloff: CGFloat) -> Float {
        
        // 找到最近的特征点
        var minDistance: CGFloat = .greatestFiniteMagnitude
        
        for regionPoint in regionPoints {
            let distance = sqrt(pow(point.x - regionPoint.x, 2) + pow(point.y - regionPoint.y, 2))
            minDistance = min(minDistance, distance)
        }
        
        // 根据距离计算深度（距离越近深度越大）
        if minDistance < falloff {
            let factor = 1.0 - (minDistance / falloff)
            return Float(factor) * maxDepth
        }
        
        return 0.0
    }
    
    // MARK: - Generate Texture Coordinates
    private func generateTextureCoordinates(faceData: FaceData) -> [CGPoint] {
        
        var texCoords: [CGPoint] = []
        let resolution = meshResolution
        
        for y in 0...resolution {
            for x in 0...resolution {
                let u = CGFloat(x) / CGFloat(resolution)
                let v = CGFloat(y) / CGFloat(resolution)
                
                texCoords.append(CGPoint(x: u, y: v))
            }
        }
        
        return texCoords
    }
    
    // MARK: - Generate Triangle Indices
    private func generateTriangleIndices() -> [Int32] {
        
        var indices: [Int32] = []
        let resolution = meshResolution
        
        for y in 0..<resolution {
            for x in 0..<resolution {
                let topLeft = Int32(y * (resolution + 1) + x)
                let topRight = topLeft + 1
                let bottomLeft = Int32((y + 1) * (resolution + 1) + x)
                let bottomRight = bottomLeft + 1
                
                // 第一个三角形
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                
                // 第二个三角形
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
        
        return indices
    }
    
    // MARK: - Create Geometry
    private func createGeometry(vertices: [SCNVector3], texCoords: [CGPoint], indices: [Int32]) -> SCNGeometry? {
        
        // 创建顶点源
        let vertexSource = SCNGeometrySource(vertices: vertices)
        
        // 创建法线（简化：都指向Z轴）
        var normals: [SCNVector3] = []
        for _ in vertices {
            normals.append(SCNVector3(0, 0, 1))
        }
        let normalSource = SCNGeometrySource(normals: normals)
        
        // 创建纹理坐标源
        let texCoordSource = SCNGeometrySource(textureCoordinates: texCoords)
        
        // 创建几何元素
        let element = SCNGeometryElement(
            indices: indices,
            primitiveType: .triangles
        )
        
        // 组合成几何体
        let geometry = SCNGeometry(
            sources: [vertexSource, normalSource, texCoordSource],
            elements: [element]
        )
        
        return geometry
    }
    
    // MARK: - Material Styles
    enum MaterialStyle {
        case textured       // 使用原图纹理
        case scanStyle      // 扫描风格（线框+半透明）
        case hologram       // 全息投影风格
        case pointCloud     // 点云风格
    }
    
    // MARK: - Apply Material
    private func applyMaterial(to node: SCNNode, texture: UIImage, style: MaterialStyle) {
        
        let material = SCNMaterial()
        
        switch style {
        case .textured:
            // 完整纹理模式
            material.diffuse.contents = texture
            material.lightingModel = .blinn
            
        case .scanStyle:
            // 扫描风格：线框 + 纹理
            material.diffuse.contents = texture
            material.fillMode = .lines // 线框模式
            material.emission.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.3) // 青色发光
            material.lightingModel = .constant
            
        case .hologram:
            // 全息投影风格
            material.diffuse.contents = texture
            material.transparency = 0.6
            material.emission.contents = UIColor.cyan
            material.lightingModel = .constant
            
        case .pointCloud:
            // 点云风格需要改变渲染模式
            material.diffuse.contents = UIColor.cyan
            material.lightingModel = .constant
        }
        
        node.geometry?.materials = [material]
    }
}
