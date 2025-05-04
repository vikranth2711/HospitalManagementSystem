//
//  HospitalityApp.swift
//  Hospitality
//
//  Created by Ashish Shiv on 16/04/25.
//

import SwiftUI

@main
struct HospitalityApp: App {
    @StateObject private var dataStore = MockHospitalDataStore()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
        }
    }
}
