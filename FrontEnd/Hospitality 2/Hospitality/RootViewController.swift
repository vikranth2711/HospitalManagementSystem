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
                switch userType {
                case "admin":
                    AdminHomeView()
                case "staff":
                    DoctorDashboard()
                case "patient":
                    HomePatient()
                default:
                    Onboarding()
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
