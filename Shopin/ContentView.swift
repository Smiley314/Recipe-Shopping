import SwiftUI
import UIKit


struct Recipe: Identifiable, Codable {
    var id = UUID()
    var title: String
    var image: Data?
    var instructions: String
    var ingredients: [String]
    var haveIngredient: [String: Bool] = [:]
    
}

class RecipeStorage {
    static let shared = RecipeStorage()

    private let userDefaults = UserDefaults.standard
    private let key = "recipes"

    func save(_ recipes: [Recipe]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(recipes)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Error encoding recipes: \(error.localizedDescription)")
        }
    }

    func load() -> [Recipe] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            let recipes = try decoder.decode([Recipe].self, from: data)
            return recipes
        } catch {
            print("Error decoding recipes: \(error.localizedDescription)")
            return []
        }
    }
}

class RecipeStore: ObservableObject {
    @Published var recipes: [Recipe] = []

    init() {
        self.recipes = RecipeStorage.shared.load()
    }

    func add(_ recipe: Recipe) {
        recipes.append(recipe)
        RecipeStorage.shared.save(recipes)
    }

    func delete(at indexSet: IndexSet) {
        recipes.remove(atOffsets: indexSet)
        RecipeStorage.shared.save(recipes)
    }
}

struct RecipeListRowView: View {
    var recipe: Recipe

    var body: some View {
        HStack {
            if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(5)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(5)
            }

            Text(recipe.title)
                .lineLimit(1)
                .padding(.leading, 8)
            
        }
        
    }
    
}

struct RecipeDetailView: View {
    var recipe: Recipe
    
    
    @State var selectedIngredients: Set<String> = []

    var body: some View {
        ScrollView {
            VStack {
                if let imageData = recipe.image, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                        .padding()
                }
                
                Text(recipe.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                
                Divider()
                
                Text("Instructions:")
                    .font(.headline)
                
                Text(recipe.instructions)
                    .padding()
                
                Divider()
                
                Text("Ingredients:")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    VStack(alignment: .leading) {
                       
                        HStack {
                            Text(ingredient)
                                .padding(.leading)
                            Spacer()
                            Button(action: {
                                if selectedIngredients.contains(ingredient) {
                                    selectedIngredients.remove(ingredient)
                                } else {
                                    selectedIngredients.insert(ingredient)
                                }
                            }) {
                                Image(systemName: selectedIngredients.contains(ingredient) ? "checkmark.square.fill" : "square")
                            }
                            .padding(.trailing)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle(Text(recipe.title), displayMode: .inline)
            
        }
    }
}

struct AddRecipeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var recipeStore: RecipeStore
    

    @State private var inputImage: UIImage?
    @State private var title: String = ""
    @State private var instructions: String = ""
    @State private var ingredients: [String] = []
    @State private var newIngredient: String = ""
    
    

    private var isFormValid: Bool {
        !title.isEmpty && !instructions.isEmpty
    }
    

    private func saveRecipe() {
        guard let inputImage = inputImage else {
            return
        }

        let recipe = Recipe(
            title: title,
            image: inputImage.jpegData(compressionQuality: 0.9),
            instructions: instructions,
            ingredients: ingredients
        )

        recipeStore.add(recipe)

        presentationMode.wrappedValue.dismiss()
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    if let inputImage = inputImage {
                        Image(uiImage: inputImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .frame(maxHeight: 300)
                            .onTapGesture {
                                self.inputImage = nil
                            }
                    } else {
                        Button(action: {
                            self.showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.title)
                                Text("Add Photo")
                                    .font(.title)
                            }
                            .foregroundColor(.accentColor)
                        }
                        .sheet(isPresented: $showImagePicker) {
                            ImagePicker(image: $inputImage)
                        }
                    }
                    
                }
                

                Section {
                    TextField("Title", text: $title)
                        .autocapitalization(.words)
                    TextEditor(text: $instructions)
                        .frame(minHeight: 200)
                }
                
                Section(header: Text("Ingredients")) {
                                   ForEach(ingredients, id: \.self) { ingredient in
                                       Text(ingredient)
                                   }
                                   .onDelete(perform: { indexSet in
                                       ingredients.remove(atOffsets: indexSet)
                                   })
                                   HStack {
                                       TextField("New Ingredient", text: $newIngredient)
                                       Button(action: {
                                           ingredients.append(newIngredient)
                                           newIngredient = ""
                                       }) {
                                           Image(systemName: "plus.circle.fill")
                                       }
                                       .disabled(newIngredient.isEmpty)
                                   }
                               }

                Section {
                    Button(action: {
                        saveRecipe()
                    }) {
                        Text("Save")
                    }
                    .disabled(!isFormValid)
                }
                
            }
            .navigationBarTitle("New Recipe", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                self.presentationMode.wrappedValue.dismiss()
            })
            
        }
        
    }
    

    // Image Picker
    @State private var showImagePicker: Bool = false
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.image = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct RecipeListView: View {
    @ObservedObject var recipeStore: RecipeStore
    @State private var showingColorPicker = false
 // @State private var backgroundColor = Color.white
    
    var body: some View {
        NavigationView {
            List {
                ForEach(recipeStore.recipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        RecipeListRowView(recipe: recipe)
                    }
                }
                .onDelete(perform: recipeStore.delete)
            }
            .navigationBarTitle("Recipes")
            .navigationBarItems(trailing: NavigationLink(destination: AddRecipeView(recipeStore: recipeStore)) {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
            })
           /* .navigationBarItems(trailing:
                            HStack {
                                Button(action: {
                                    self.showingColorPicker = true
                                }) {
                                    Image(systemName: "paintbrush")
                                }
                            }
                        )
                        .sheet(isPresented: $showingColorPicker) {
                            ColorPicker("Background Color", selection: self.$backgroundColor)
                        }
                        .background(backgroundColor)
            */
        }
    }
    
}
