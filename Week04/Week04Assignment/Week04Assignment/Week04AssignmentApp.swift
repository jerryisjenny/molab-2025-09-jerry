//
//  Week04AssignmentApp.swift
//  Week04Assignment
//
//  Created by Jieyin Tan on 10/3/25.
//
import SwiftUI

@main
struct SimpleMusicApp: App {
    @State var audioDJ = AudioDJ()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioDJ)
        }
    }
}
