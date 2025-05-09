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
    @AppStorage("staffSubRole") private var staffSubRole = "doctor"
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
                contentView
                    .transition(.opacity)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if !isLoggedIn {
            Login()
        } else if !UserDefaults.hasCompletedOnboarding {
            onboardingView
        } else {
            mainView
        }
    }
    
    @ViewBuilder
    private var onboardingView: some View {
        switch userType {
        case "admin":
            AdminOnboarding()
        case "staff":
            staffSubRole == "doctor" ? AnyView(DoctorOnboarding(doctorId: userId)) : AnyView(LabTechOnboarding())
        case "patient":
            PatientOnboarding()
        default:
            Text("Error: Unknown user type \(userType)")
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    private var mainView: some View {
        switch userType {
        case "admin":
            AdminHomeView()
        case "staff":
            staffSubRole == "doctor" ? AnyView(DoctorDashboardView(doctorId: userId)) : AnyView(LabTechnicianView())
        case "patient":
            HomePatient()
        default:
            Text("Error: Unknown user type \(userType)")
                .foregroundColor(.red)
        }
    }
}
