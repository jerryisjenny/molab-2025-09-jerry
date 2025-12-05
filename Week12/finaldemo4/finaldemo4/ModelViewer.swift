//
//  ModelViewer.swift
//  finaldemo4
//
//  Created by Jieyin Tan on 11/26/25.
//


import SwiftUI
import SceneKit
import SceneKit.ModelIO

struct ModelViewer: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = true
        view.backgroundColor = .clear
        

        DispatchQueue.global(qos: .userInitiated).async {
            let scene = loadScene(from: url)
            DispatchQueue.main.async {
                view.scene = scene
                
                //Rotation
                let rotation = SCNAction.rotateBy(x: 0, y: 2 * .pi, z: 0, duration: 10)
                let repeatAction = SCNAction.repeatForever(rotation)
                view.scene?.rootNode.runAction(repeatAction)
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    // Loading
    private func loadScene(from url: URL) -> SCNScene? {
        // 1. USDZ
        if url.pathExtension.lowercased() == "usdz" {
            do {
                let scene = try SCNScene(url: url, options: nil)
                print("✅ Successfully load USDZ")
                return scene
            } catch {
                print("❌ USDZ Loading error: \(error)")
            }
        }
        
        // GLB
        let standardUrl = url.standardizedFileURL
        let asset = MDLAsset(url: standardUrl)
        
        // Check
        if asset.count == 0 {
            print("⚠️ ModelIO was unable to parse a 3D object from the file.")
            return nil
        }
        
        let scene = SCNScene(mdlAsset: asset)
        print("✅ Successfully loaded the GLB file with ModelIO.")
        return scene
    }
}
