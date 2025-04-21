//
//  adminTabBar.swift
//  Hospitality
//
//  Created by admin@33 on 21/04/25.
//

import SwiftUI

struct adminTabBarView : View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selectedTab) {
                    HomeContent(showProfile: $showProfile)
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    ReportsContent()
                        .tabItem {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Reports")
                        }
                        .tag(1)
                    BillsContent()
                        .tabItem {
                            Image(systemName: "dollarsign.circle")
                            Text("Bills")
                        }
                        .tag(2)
                }
                .accentColor(colorScheme == .dark ? .blue : Color(hex: "4A90E2"))
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }
}
