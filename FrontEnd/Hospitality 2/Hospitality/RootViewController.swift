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
    @AppStorage("userId") private var userId = ""
    @AppStorage("staffSubRole") private var staffSubRole = "doctor" // Add this line
    @State private var showSplashScreen = true
    
    var body: some View {
        ZStack {
            if showSplashScreen {
                SplashScreen(onComplete: {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                })
            } else {
                Group {
                    if isLoggedIn {
                        switch userType {
                        case "admin":
                            AdminHomeView()
                        case "staff":
                            // Check staffSubRole to determine which view to show
                            if staffSubRole == "doctor" {
                                DoctorDashboardView(doctorId: userId)
                            } else {
//                                LabTechnicianView() // Make sure this view is properly imported
                            }
                        case "patient":
                            HomePatient()
                        default:
                            Login()
                        }
                    } else {
                        Login()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .logout)) { _ in
                    print("Logout notification received")
                    isLoggedIn = false
                    UserDefaults.clearAuthData()
                }
                .transition(.opacity) // Add smooth transition
            }
        }
    }
}
