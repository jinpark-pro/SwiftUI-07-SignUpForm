//
//  ContentView.swift
//  SignUpForm
//
//  Created by Jungjin Park on 2024-06-18.
//

import SwiftUI

class SignUpFormViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    @Published var usernameMessage: String = ""
    @Published var passwordMessage: String = ""
    @Published var isValid: Bool = false
    
    init() {
        // 작업지시서이니까 실제 데이터가 들어오기전에 선언해도 됨
        $username.map { $0.count >= 3 }
            .assign(to: &$isValid)
        $username.map { $0.count >= 3 ? "" : "Username must be at least three characters"}
            .assign(to: &$usernameMessage)
    }
}
struct ContentView: View {
    @StateObject var viewModel = SignUpFormViewModel()
    var body: some View {
        Form {
            // Username
            Section {
                TextField("Username", text: $viewModel.username)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
            } footer: {
                Text(viewModel.usernameMessage)
                    .foregroundStyle(Color.red)
            }
            // Password
            Section {
                SecureField("Password", text: $viewModel.password)
                SecureField("Repeat password", text: $viewModel.passwordConfirmation)
            } footer: {
                Text(viewModel.passwordMessage)
                    .foregroundStyle(Color.red)
            }
            // Button
            Section {
                Button("Sign up") {
                    print("Signing up as \(viewModel.username)")
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
}

#Preview {
    ContentView()
}
