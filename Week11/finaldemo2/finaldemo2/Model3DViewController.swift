//
//  Model3DViewController.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//
//
//  Model3DViewController.swift
//  FaceGlitch3D
//
//  3D模型查看器 - 显示生成的3D模型，支持旋转、缩放
//

import UIKit
import SceneKit

class Model3DViewController: UIViewController {
    
    // MARK: - Properties
    var modelNode: SCNNode?
    
    private var sceneView: SCNView!
    private var scene: SCNScene!
    private var cameraNode: SCNNode!
    
    private var closeButton: UIButton!
    private var saveButton: UIButton!
    private var styleSegment: UISegmentedControl!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupUI()
        setupGestures()
        
        if let model = modelNode {
            addModelToScene(model)
        }
    }
    
    // MARK: - Scene Setup
    private func setupScene() {
        // 创建场景视图
        sceneView = SCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .black
        view.addSubview(sceneView)
        
        // 创建场景
        scene = SCNScene()
        sceneView.scene = scene
        
        // 允许用户控制相机
        sceneView.allowsCameraControl = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = false
        
        // 设置相机
        setupCamera()
        
        // 添加灯光
        setupLighting()
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2.5)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting() {
        // 环境光
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // 主光源
        let mainLight = SCNNode()
        mainLight.light = SCNLight()
        mainLight.light?.type = .directional
        mainLight.light?.color = UIColor.white
        mainLight.position = SCNVector3(x: 5, y: 5, z: 5)
        mainLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(mainLight)
        
        // 背光（轮廓光）
        let backLight = SCNNode()
        backLight.light = SCNLight()
        backLight.light?.type = .omni
        backLight.light?.color = UIColor.cyan
        backLight.position = SCNVector3(x: 0, y: 0, z: -3)
        scene.rootNode.addChildNode(backLight)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 关闭按钮
        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .boldSystemFont(ofSize: 24)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 25
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        // 保存按钮
        saveButton = UIButton(type: .system)
        saveButton.setTitle("💾 保存", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        saveButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        saveButton.layer.cornerRadius = 22
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        view.addSubview(saveButton)
        
        // 风格切换
        styleSegment = UISegmentedControl(items: ["纹理", "扫描", "全息"])
        styleSegment.selectedSegmentIndex = 1 // 默认扫描风格
        styleSegment.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        styleSegment.selectedSegmentTintColor = .systemBlue
        styleSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        styleSegment.translatesAutoresizingMaskIntoConstraints = false
        styleSegment.addTarget(self, action: #selector(styleChanged), for: .valueChanged)
        view.addSubview(styleSegment)
        
        // 布局
        NSLayoutConstraint.activate([
            // 关闭按钮
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 50),
            
            // 保存按钮
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 120),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 风格切换
            styleSegment.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -20),
            styleSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            styleSegment.widthAnchor.constraint(equalToConstant: 240),
        ])
    }
    
    // MARK: - Add Model
    private func addModelToScene(_ model: SCNNode) {
        scene.rootNode.addChildNode(model)
        
        // 添加自动旋转动画
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 8)
        let repeatRotation = SCNAction.repeatForever(rotation)
        model.runAction(repeatRotation, forKey: "autoRotate")
    }
    
    // MARK: - Gestures
    private func setupGestures() {
        // 双击停止/开始旋转
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func handleDoubleTap() {
        guard let model = modelNode else { return }
        
        if model.action(forKey: "autoRotate") != nil {
            model.removeAction(forKey: "autoRotate")
        } else {
            let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 8)
            let repeatRotation = SCNAction.repeatForever(rotation)
            model.runAction(repeatRotation, forKey: "autoRotate")
        }
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        // 截图保存
        let image = sceneView.snapshot()
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let alert: UIAlertController
        
        if let error = error {
            alert = UIAlertController(title: "保存失败", message: error.localizedDescription, preferredStyle: .alert)
        } else {
            alert = UIAlertController(title: "保存成功", message: "3D模型截图已保存到相册", preferredStyle: .alert)
        }
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func styleChanged() {
        guard let model = modelNode,
              let material = model.geometry?.firstMaterial else {
            return
        }
        
        // 保存原始纹理
        let originalTexture = material.diffuse.contents
        
        switch styleSegment.selectedSegmentIndex {
        case 0: // 纹理模式
            material.diffuse.contents = originalTexture
            material.fillMode = .fill
            material.transparency = 1.0
            material.emission.contents = nil
            material.lightingModel = .blinn
            
        case 1: // 扫描模式
            material.diffuse.contents = originalTexture
            material.fillMode = .lines
            material.emission.contents = UIColor(red: 0, green: 1, blue: 1, alpha: 0.3)
            material.lightingModel = .constant
            
        case 2: // 全息模式
            material.diffuse.contents = originalTexture
            material.fillMode = .fill
            material.transparency = 0.6
            material.emission.contents = UIColor.cyan
            material.lightingModel = .constant
            
        default:
            break
        }
    }
}
