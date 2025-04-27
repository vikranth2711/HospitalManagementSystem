//
//  RootViewController.swift
//  Hospitality
//
//  Created by admin@33 on 27/04/25.
//

import Foundation
import SwiftUI

struct RootView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userType") private var userType = ""
    
    var body: some View {
        Group {
            if isLoggedIn {
                if userType == "Admin" {
                    AdminHomeView()
                } else {
                    HomePatient()
                }
            } else {
                Onboarding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .logout)) { _ in
            print("Logout notification received")
            isLoggedIn = false
            UserDefaults.clearAuthData()
        }
    }
}
