//
//  AppDelegate.swift
//  ObjectDetection-YOLO
//
//  Created by Gabriel on 18/09/19.
//  Copyright © 2019 Gabriel. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialVC = mainStoryboard.instantiateInitialViewController()
        window?.rootViewController = initialVC!
        return true
    }

    // MARK: UISceneSession Lifecycle
}

