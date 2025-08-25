//
//  ProfileManagementView.swift
//  SwingIQ
//
//  Created by Jonathan Raney on 7/20/25.
//

import SwiftUI

struct ProfileManagementView: View {
    @State private var playerName = ""
    @State private var handicapIndex = ""
    @State private var homeCourse = ""
    @State private var bio = ""
    @State private var profileImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    
    private var isValidHandicap: Bool {
        guard !handicapIndex.isEmpty else { return true }
        if let value = Double(handicapIndex) {
            return value >= -10.0 && value <= 54.0
        }
        return false
    }
    
    var body: some View {
        Form {
                Section("Profile Photo") {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                
                Section("Personal Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Enter your name", text: $playerName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Handicap Index")
                        Spacer()
                        TextField("0.0", text: $handicapIndex)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(isValidHandicap ? .primary : .red)
                    }
                    
                    if !isValidHandicap {
                        Text("Handicap must be between -10.0 and 54.0")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Text("Home Course")
                        Spacer()
                        TextField("Course name", text: $homeCourse)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Bio") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About You")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                    }
                }
                
                Section("Actions") {
                    Button("Save Changes") {
                        saveProfile()
                    }
                    .foregroundColor(.blue)
                    .disabled(!isValidHandicap)
                    
                    Button("Reset to Default") {
                        resetProfile()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile Management")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker) {
                ProfileImagePicker(image: $profileImage)
            }
            .onAppear {
                loadProfile()
            }
            .alert("Profile Update", isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveMessage)
            }
    }
    
    // MARK: - Helper Methods
    
    private func saveProfile() {
        guard isValidHandicap else {
            saveMessage = "Please enter a valid handicap index between -10.0 and 54.0"
            showingSaveAlert = true
            return
        }
        
        do {
            // Save profile data to UserDefaults
            UserDefaults.standard.set(playerName, forKey: "playerName")
            UserDefaults.standard.set(handicapIndex, forKey: "handicapIndex")
            UserDefaults.standard.set(homeCourse, forKey: "homeCourse")
            UserDefaults.standard.set(bio, forKey: "playerBio")
            
            // Save profile image to Documents directory if available
            if let profileImage = profileImage,
               let imageData = profileImage.jpegData(compressionQuality: 0.8) {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let imagePath = documentsPath.appendingPathComponent("profileImage.jpg")
                try imageData.write(to: imagePath)
            }
            
            saveMessage = "Profile saved successfully!"
            showingSaveAlert = true
        } catch {
            saveMessage = "Failed to save profile: \(error.localizedDescription)"
            showingSaveAlert = true
        }
    }
    
    private func loadProfile() {
        playerName = UserDefaults.standard.string(forKey: "playerName") ?? ""
        handicapIndex = UserDefaults.standard.string(forKey: "handicapIndex") ?? ""
        homeCourse = UserDefaults.standard.string(forKey: "homeCourse") ?? ""
        bio = UserDefaults.standard.string(forKey: "playerBio") ?? ""
        
        // Load profile image from Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("profileImage.jpg")
        if let imageData = try? Data(contentsOf: imagePath) {
            profileImage = UIImage(data: imageData)
        }
    }
    
    private func resetProfile() {
        playerName = ""
        handicapIndex = ""
        homeCourse = ""
        bio = ""
        profileImage = nil
        
        // Clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: "playerName")
        UserDefaults.standard.removeObject(forKey: "handicapIndex")
        UserDefaults.standard.removeObject(forKey: "homeCourse")
        UserDefaults.standard.removeObject(forKey: "playerBio")
        
        // Remove profile image file
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("profileImage.jpg")
        try? FileManager.default.removeItem(at: imagePath)
    }
}

// MARK: - Profile Image Picker

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    ProfileManagementView()
}
