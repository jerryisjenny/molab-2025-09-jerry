//
//  GlitchEffectManager.swift
//  FaceGlitch3D
//
//  Glitch特效管理器 - 只在人脸区域应用特效
//

import UIKit
import CoreImage

enum GlitchEffectError: Error {
    case invalidImage
    case processingFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "图片格式无效"
        case .processingFailed:
            return "特效处理失败"
        }
    }
}

class GlitchEffectManager {
    
    private let context = CIContext()
    
    // MARK: - Main Function
    func applyGlitchEffect(to image: UIImage, faceData: FaceData, intensity: Float, completion: @escaping (Result<UIImage, GlitchEffectError>) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let ciImage = CIImage(image: image) else {
                completion(.failure(.invalidImage))
                return
            }
            
            // 1. 创建人脸蒙版
            guard let faceMask = self.createFaceMask(faceData: faceData, imageSize: image.size) else {
                completion(.failure(.processingFailed))
                return
            }
            
            // 2. 应用Glitch效果
            guard let glitchedImage = self.applyGlitch(to: ciImage, intensity: intensity) else {
                completion(.failure(.processingFailed))
                return
            }
            
            // 3. 使用蒙版混合原图和特效图
            guard let blendedImage = self.blendWithMask(
                original: ciImage,
                glitched: glitchedImage,
                mask: faceMask
            ) else {
                completion(.failure(.processingFailed))
                return
            }
            
            // 4. 转换为UIImage
            guard let cgImage = self.context.createCGImage(blendedImage, from: blendedImage.extent) else {
                completion(.failure(.processingFailed))
                return
            }
            
            let resultImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
            completion(.success(resultImage))
        }
    }
    
    // MARK: - Create Face Mask
    private func createFaceMask(faceData: FaceData, imageSize: CGSize) -> CIImage? {
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // 填充黑色背景
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: imageSize))
        
        // 在人脸区域绘制白色椭圆（带羽化效果）
        context.setFillColor(UIColor.white.cgColor)
        
        // 扩大人脸区域一点，让过渡更自然
        let expandedRect = faceData.boundingBox.insetBy(dx: -faceData.boundingBox.width * 0.1,
                                                        dy: -faceData.boundingBox.height * 0.1)
        
        context.fillEllipse(in: expandedRect)
        
        let maskImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let mask = maskImage,
              let ciMask = CIImage(image: mask) else {
            return nil
        }
        
        // 应用高斯模糊让蒙版边缘更柔和
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(ciMask, forKey: kCIInputImageKey)
        blurFilter?.setValue(20.0, forKey: kCIInputRadiusKey)
        
        return blurFilter?.outputImage
    }
    
    // MARK: - Apply Glitch Effects
    private func applyGlitch(to image: CIImage, intensity: Float) -> CIImage? {
        
        // Glitch效果1: RGB通道偏移
        guard let rgbShifted = applyRGBShift(to: image, intensity: intensity) else {
            return nil
        }
        
        // Glitch效果2: 颜色失真
        guard let colorDistorted = applyColorDistortion(to: rgbShifted, intensity: intensity) else {
            return nil
        }
        
        // Glitch效果3: 添加噪点
        guard let withNoise = addNoise(to: colorDistorted, intensity: intensity * 0.3) else {
            return nil
        }
        
        return withNoise
    }
    
    // RGB通道偏移效果
    private func applyRGBShift(to image: CIImage, intensity: Float) -> CIImage? {
        
        let shiftAmount = CGFloat(intensity * 15.0)
        
        // 分离RGB通道
        guard let redFilter = CIFilter(name: "CIColorMatrix"),
              let greenFilter = CIFilter(name: "CIColorMatrix"),
              let blueFilter = CIFilter(name: "CIColorMatrix") else {
            return nil
        }
        
        // 红色通道
        redFilter.setValue(image, forKey: kCIInputImageKey)
        redFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
        redFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        redFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
        // 绿色通道
        greenFilter.setValue(image, forKey: kCIInputImageKey)
        greenFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        greenFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
        greenFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputBVector")
        
        // 蓝色通道
        blueFilter.setValue(image, forKey: kCIInputImageKey)
        blueFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputRVector")
        blueFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputGVector")
        blueFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
        
        guard let redChannel = redFilter.outputImage,
              let greenChannel = greenFilter.outputImage,
              let blueChannel = blueFilter.outputImage else {
            return nil
        }
        
        // 偏移通道
        let redShifted = redChannel.transformed(by: CGAffineTransform(translationX: -shiftAmount, y: 0))
        let blueShifted = blueChannel.transformed(by: CGAffineTransform(translationX: shiftAmount, y: 0))
        
        // 合并通道
        guard let addFilter1 = CIFilter(name: "CIAdditionCompositing"),
              let addFilter2 = CIFilter(name: "CIAdditionCompositing") else {
            return nil
        }
        
        addFilter1.setValue(redShifted, forKey: kCIInputImageKey)
        addFilter1.setValue(greenChannel, forKey: kCIInputBackgroundImageKey)
        
        guard let temp = addFilter1.outputImage else { return nil }
        
        addFilter2.setValue(blueShifted, forKey: kCIInputImageKey)
        addFilter2.setValue(temp, forKey: kCIInputBackgroundImageKey)
        
        return addFilter2.outputImage
    }
    
    // 颜色失真效果
    private func applyColorDistortion(to image: CIImage, intensity: Float) -> CIImage? {
        
        // 色相调整
        guard let hueFilter = CIFilter(name: "CIHueAdjust") else { return nil }
        hueFilter.setValue(image, forKey: kCIInputImageKey)
        hueFilter.setValue(CGFloat(intensity) * 0.5, forKey: kCIInputAngleKey)
        
        guard let hueAdjusted = hueFilter.outputImage else { return nil }
        
        // 颜色控制
        guard let colorFilter = CIFilter(name: "CIColorControls") else { return nil }
        colorFilter.setValue(hueAdjusted, forKey: kCIInputImageKey)
        colorFilter.setValue(1.0 + CGFloat(intensity) * 0.5, forKey: kCIInputSaturationKey)
        colorFilter.setValue(1.0 + CGFloat(intensity) * 0.3, forKey: kCIInputContrastKey)
        
        return colorFilter.outputImage
    }
    
    // 添加噪点效果
    private func addNoise(to image: CIImage, intensity: Float) -> CIImage? {
        
        // 生成随机噪点
        guard let noiseGenerator = CIFilter(name: "CIRandomGenerator") else { return nil }
        guard var noiseImage = noiseGenerator.outputImage else { return nil }
        
        // 调整噪点范围到图片大小
        noiseImage = noiseImage.cropped(to: image.extent)
        
        // 控制噪点强度
        guard let multiplyFilter = CIFilter(name: "CIColorMatrix") else { return nil }
        multiplyFilter.setValue(noiseImage, forKey: kCIInputImageKey)
        
        let amount = CGFloat(intensity)
        multiplyFilter.setValue(CIVector(x: amount, y: 0, z: 0, w: 0), forKey: "inputRVector")
        multiplyFilter.setValue(CIVector(x: 0, y: amount, z: 0, w: 0), forKey: "inputGVector")
        multiplyFilter.setValue(CIVector(x: 0, y: 0, z: amount, w: 0), forKey: "inputBVector")
        multiplyFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        
        guard let scaledNoise = multiplyFilter.outputImage else { return nil }
        
        // 混合噪点和原图
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        blendFilter.setValue(scaledNoise, forKey: kCIInputImageKey)
        blendFilter.setValue(image, forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage
    }
    
    // MARK: - Blend with Mask
    private func blendWithMask(original: CIImage, glitched: CIImage, mask: CIImage) -> CIImage? {
        
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
        
        blendFilter.setValue(glitched, forKey: kCIInputImageKey)
        blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        return blendFilter.outputImage
    }
}//
//  GlitchEffectManager.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//

