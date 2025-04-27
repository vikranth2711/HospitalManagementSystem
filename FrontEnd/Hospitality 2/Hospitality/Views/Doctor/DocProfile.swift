//
//  DocProfile.swift
//  Hospitality
//
//  Created by admin@33 on 28/04/25.
//

import SwiftUI
import UIKit // For potential haptic feedback

struct DocProfile: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var showLogoutConfirmation = false
    
    // Mock doctor data (replace with actual data source)
    private let doctorName = UserDefaults.email
    private let doctorSpecialty = "Cardiology" // Replace with actual data
    private let staffID = "DOC-12345" // Replace with actual data
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(Color(hex: "4A90E2"))
                            .padding(.bottom, 10)
                        
                        Text(doctorName)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Doctor")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text(doctorSpecialty)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                        
                        Text("Staff ID: \(staffID)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 30)
                    
                    // Account Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("ACCOUNT")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: Text("Edit Profile")) {
                            ProfileRow(icon: "person.fill", title: "Edit Profile")
                        }
                        
                        NavigationLink(destination: Text("Change Password")) {
                            ProfileRow(icon: "lock.fill", title: "Change Password")
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("SETTINGS")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        NavigationLink(destination: Text("Notifications")) {
                            ProfileRow(icon: "bell.fill", title: "Notifications")
                        }
                        
                        NavigationLink(destination: Text("Privacy")) {
                            ProfileRow(icon: "hand.raised.fill", title: "Privacy")
                        }
                    }
                    
                    Spacer()
                    
                    // Logout Button
                    Button(action: {
                        showLogoutConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.square.fill")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                    .padding(.top, 30)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Doctor Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Log Out", isPresented: $showLogoutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
    
    private func logout() {
        // Clear all user defaults
        UserDefaults.clearAuthData()
        
        // Dismiss the profile view
        dismiss()
        
        // Post notification to trigger root view change
        NotificationCenter.default.post(name: .logout, object: nil)
    }
}



#Preview {
    DocProfile()
        .preferredColorScheme(.dark)
}
