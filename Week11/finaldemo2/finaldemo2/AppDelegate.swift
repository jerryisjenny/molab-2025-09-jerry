//
//  AppDelegate.swift
//  finaldemo2
//
//  Created by Jieyin Tan on 11/14/25.
//
//
//  AppDelegate.swift
//  FaceGlitch3D
//
//  App入口
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 创建窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 设置根视图控制器
        let mainVC = MainViewController()
        let navigationController = UINavigationController(rootViewController: mainVC)
        navigationController.navigationBar.isHidden = true
        
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
}
