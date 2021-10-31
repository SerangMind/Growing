//
//  GrowingApp.swift
//  Growing
//
//  Created by Serang MacBook Pro 16 on 2021/10/31.
//

import SwiftUI

@main
struct GrowingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
