//
//  CalmieAppApp.swift
//  CalmieApp
//
//  Created by Mateusz Mlynarski on 29/06/2023.
//

import SwiftUI

@main
struct CalmieAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
