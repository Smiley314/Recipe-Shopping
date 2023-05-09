//
//  ShopinApp.swift
//  Shopin
//
//  Created by Melissa Benefer on 4/19/23.
//

import SwiftUI

@main
struct ShopinApp: App {
@StateObject var recipeStore = RecipeStore()
    var body: some Scene {
        WindowGroup {
            RecipeListView(recipeStore: recipeStore)
        }
    }
}
