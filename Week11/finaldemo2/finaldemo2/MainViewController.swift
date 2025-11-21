//
//  MainViewController.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//
//
//  MainViewController.swift
//  FaceGlitch3D
//
//  主界面 - 负责图片上传、导航和UI控制
//

import UIKit
import SceneKit

class MainViewController: UIViewController {
    
    // MARK: - UI Components
    private var imageView: UIImageView!
    private var uploadButton: UIButton!
    private var cameraButton: UIButton!
    private var detectFaceButton: UIButton!
    private var applyGlitchButton: UIButton!
    private var generate3DButton: UIButton!
    private var statusLabel: UILabel!
    
    // MARK: - Data
    private var originalImage: UIImage?
    private var editedImage: UIImage?
    private var detectedFace: FaceData?
    
    // MARK: - Managers
    private let faceDetector = FaceDetectionManager()
    private let glitchProcessor = GlitchEffectManager()
    private let model3DGenerator = Model3DGenerator()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateButtonStates()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // 图片预览
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .darkGray
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // 状态标签
        statusLabel = UILabel()
        statusLabel.text = "上传或拍摄一张包含人脸的照片"
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        
        // 上传按钮
        uploadButton = createButton(title: "📁 上传图片", color: .systemBlue)
        uploadButton.addTarget(self, action: #selector(uploadImageTapped), for: .touchUpInside)
        
        // 拍照按钮
        cameraButton = createButton(title: "📷 拍照", color: .systemBlue)
        cameraButton.addTarget(self, action: #selector(takePhotoTapped), for: .touchUpInside)
        
        // 检测人脸按钮
        detectFaceButton = createButton(title: "🔍 检测人脸", color: .systemGreen)
        detectFaceButton.addTarget(self, action: #selector(detectFaceTapped), for: .touchUpInside)
        
        // 应用Glitch按钮
        applyGlitchButton = createButton(title: "✨ 添加特效", color: .systemPurple)
        applyGlitchButton.addTarget(self, action: #selector(applyGlitchTapped), for: .touchUpInside)
        
        // 生成3D按钮
        generate3DButton = createButton(title: "🎨 生成3D模型", color: .systemOrange)
        generate3DButton.addTarget(self, action: #selector(generate3DTapped), for: .touchUpInside)
        
        // 布局约束
        NSLayoutConstraint.activate([
            // 图片视图
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),
            
            // 状态标签
            statusLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 上传按钮
            uploadButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            uploadButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            uploadButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.42),
            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 拍照按钮
            cameraButton.topAnchor.constraint(equalTo: uploadButton.topAnchor),
            cameraButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cameraButton.widthAnchor.constraint(equalTo: uploadButton.widthAnchor),
            cameraButton.heightAnchor.constraint(equalTo: uploadButton.heightAnchor),
            
            // 检测人脸按钮
            detectFaceButton.topAnchor.constraint(equalTo: uploadButton.bottomAnchor, constant: 12),
            detectFaceButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            detectFaceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            detectFaceButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Glitch按钮
            applyGlitchButton.topAnchor.constraint(equalTo: detectFaceButton.bottomAnchor, constant: 12),
            applyGlitchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            applyGlitchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            applyGlitchButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 3D按钮
            generate3DButton.topAnchor.constraint(equalTo: applyGlitchButton.bottomAnchor, constant: 12),
            generate3DButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            generate3DButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            generate3DButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        return button
    }
    
    // MARK: - Button Actions
    @objc private func uploadImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @objc private func takePhotoTapped() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(message: "相机不可用")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.cameraDevice = .front // 前置摄像头
        present(picker, animated: true)
    }
    
    @objc private func detectFaceTapped() {
        guard let image = originalImage else { return }
        
        statusLabel.text = "正在检测人脸..."
        
        faceDetector.detectFace(in: image) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let faceData):
                    self?.detectedFace = faceData
                    self?.statusLabel.text = "✅ 检测到人脸！可以添加特效了"
                    self?.updateButtonStates()
                    
                    // 在图片上绘制人脸框
                    self?.drawFaceBoundingBox(faceData: faceData)
                    
                case .failure(let error):
                    self?.statusLabel.text = "❌ \(error.localizedDescription)"
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func applyGlitchTapped() {
        guard let image = originalImage,
              let faceData = detectedFace else { return }
        
        statusLabel.text = "正在添加特效..."
        
        // 显示效果选择器（简化版，直接应用默认效果）
        glitchProcessor.applyGlitchEffect(to: image, faceData: faceData, intensity: 0.7) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let glitchedImage):
                    self?.editedImage = glitchedImage
                    self?.imageView.image = glitchedImage
                    self?.statusLabel.text = "✅ 特效已应用！可以生成3D模型了"
                    self?.updateButtonStates()
                    
                case .failure(let error):
                    self?.statusLabel.text = "❌ 特效应用失败"
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func generate3DTapped() {
        guard let image = editedImage ?? originalImage,
              let faceData = detectedFace else { return }
        
        statusLabel.text = "正在生成3D模型..."
        
        model3DGenerator.generate3DModel(from: image, faceData: faceData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model3D):
                    self?.statusLabel.text = "✅ 3D模型生成成功！"
                    self?.show3DModel(model3D)
                    
                case .failure(let error):
                    self?.statusLabel.text = "❌ 3D生成失败"
                    self?.showAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func updateButtonStates() {
        let hasImage = originalImage != nil
        let hasFace = detectedFace != nil
        let hasEdited = editedImage != nil
        
        detectFaceButton.isEnabled = hasImage
        detectFaceButton.alpha = hasImage ? 1.0 : 0.5
        
        applyGlitchButton.isEnabled = hasFace
        applyGlitchButton.alpha = hasFace ? 1.0 : 0.5
        
        generate3DButton.isEnabled = hasFace
        generate3DButton.alpha = hasFace ? 1.0 : 0.5
    }
    
    private func drawFaceBoundingBox(faceData: FaceData) {
        guard let image = originalImage else { return }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(at: .zero)
        
        let context = UIGraphicsGetCurrentContext()!
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(3.0)
        
        let rect = faceData.boundingBox
        context.stroke(rect)
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        imageView.image = resultImage
    }
    
    private func show3DModel(_ modelNode: SCNNode) {
        let viewer3D = Model3DViewController()
        viewer3D.modelNode = modelNode
        viewer3D.modalPresentationStyle = .fullScreen
        present(viewer3D, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage {
            originalImage = image
            editedImage = nil
            detectedFace = nil
            imageView.image = image
            statusLabel.text = "图片已加载，点击检测人脸"
            updateButtonStates()
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
