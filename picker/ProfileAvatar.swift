//
//  ProfileDemo.swift
//  Mi Baliza V16
//
//  Created by Codelaby on 06/04/2026.
//

/// https://www.idownloadblog.com/2016/03/11/how-to-change-ios-icloud-profile-picture/
/// https://mszpro.com/memoji-textfield-picking

// Need add crop image

import SwiftUI

// MARK: - User Model
struct UserModel {
    let givenName: String
    let familyName: String
}

// Extensión para formatear el nombre según locale
extension UserModel {
    var formattedName: String {
        let formatter = PersonNameComponentsFormatter()
        var components = PersonNameComponents()
        components.givenName = givenName
        components.familyName = familyName
        return formatter.string(from: components)
    }
}


// MARK: - Profile Row View
struct ProfileRowView: View {
    var userPhoto: Image?
    var user: UserModel
    var summary: String
    
    var body: some View {
        HStack(spacing: 16) {
            if let photo = userPhoto {
                photo
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(.circle)
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(.secondary)
            }
            
            // Text (name and summary)
            VStack(alignment: .leading, spacing: 4) {
                Text(user.formattedName)
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(summary)
                    .font(.footnote)
                    .lineLimit(1)
            }
            
            Spacer()
        }
    }
}

// MARK: - Profile Detail View
struct ProfileDetailView: View {
    @State private var showingAvatarEditor = false
    
    @State private var userPhoto: Image?
    var userName: String
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Button {
                        showingAvatarEditor = true
                    } label: {
                        if let photo = userPhoto {
                            photo
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipShape(.circle)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 72, height: 72)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    
                    Text(userName)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("Apple ID, iCloud, Media & Purchases")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(userName)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Apple ID")
                    Spacer()
                    Text("juan.perez@example.com")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("iCloud Status")
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                Text("Sign Out")
                    .foregroundStyle(.red)
            }
        }
        
        .navigationTitle("Acount ID")
#if os(iOS)
        // .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .sheet(isPresented: $showingAvatarEditor) {
            AvatarEditView(currentPhoto: $userPhoto)
        }
    }
}

// MARK: - Avatar Edit View
struct AvatarEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentPhoto: Image?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        // Current avatar preview
                        if let photo = currentPhoto {
                            photo
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 96)
                                .clipShape(.circle)
                                .overlay(
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 96, height: 96)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("Current Avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        
                        HStack {
                            Group {
                                Button("Camera", systemImage: "camera") {
                                    print("open camera")
                                }
                                .labelStyle(.iconOnly)

                                Button("Photo", systemImage: "photo") {
                                    print("open photopicker")
                                }
                                .labelStyle(.iconOnly)

                                Button("Emoji", systemImage: "face.smiling") {
                                    print("open emoji custom")
                                }
                                .labelStyle(.iconOnly)

                                Button("CA") {
                                    print("open text custom")
                                }
                                
                            }
                            .controlSize(.large)
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                        }
                        
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                Section("Emojis") {
       

                }
          //      .listRowBackground(Color.clear)

 
            }
            .navigationTitle("Edit Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(role: .cancel) {
                        dismiss()
                    }
                })
                
                ToolbarItem(placement: .confirmationAction, content: {
                    Button(role: .confirm) {
                        dismiss()
                    }
                })
            }
        }
    }
}


// MARK: - Demo
struct ProfileDemo: View {
    let user = UserModel(
        givenName: "Juan",
        familyName: "Pérez"
    )
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileDetailView(userName: "Juan Pérez")
                    } label: {
                        ProfileRowView(
                            userPhoto: nil,
                            user: user,
                            summary: "Apple ID, iCloud, Media & Purchases"
                        )
                    }
                }
                
                Text("iCloud Settings")
                Text("Password & Security")
                Text("Payment Methods")
            }
            .navigationTitle("Account")
#if os(iOS)
            //   .listStyle(.insetGrouped)
#endif
        }
    }
}

// MARK: - Preview
#Preview {
    ProfileDemo()
}
