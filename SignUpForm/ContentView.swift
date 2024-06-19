//
//  ContentView.swift
//  SignUpForm
//
//  Created by Jungjin Park on 2024-06-18.
//

import SwiftUI
import Combine

class SignUpFormViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var passwordConfirmation: String = ""
    
    @Published var usernameMessage: String = ""
    @Published var passwordMessage: String = ""
    @Published var isValid: Bool = false
    
    @Published var isUserNameAvailable: Bool = false
    
    private let authenticationService = AuthenticationService()
    
    private var cancellables: Set<AnyCancellable> = []
    
    private lazy var isUsernameLengthValidPublisher: AnyPublisher<Bool, Never> = {
        $username.map { $0.count >= 3 }.eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordEmptyPublisher: AnyPublisher<Bool, Never> = {
        $password.map(\.isEmpty).eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordMatchingPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest($password, $passwordConfirmation)
            .map(==)
            .eraseToAnyPublisher()
    }()
    
    private lazy var isPasswordValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest(isPasswordEmptyPublisher, isPasswordMatchingPublisher)
            .map { !$0 && $1}
            .eraseToAnyPublisher()
    }()
    
    private lazy var isFormValidPublisher: AnyPublisher<Bool, Never> = {
        Publishers.CombineLatest3(isUsernameLengthValidPublisher, $isUserNameAvailable, isPasswordValidPublisher)
            .map { $0 && $1 && $2 }
            .eraseToAnyPublisher()
    }()
    
    func checkUserNameAvailable(_ userName: String) {
        authenticationService.checkUserNameAvailableWithClosure(userName: userName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isAvailable):
                    self?.isUserNameAvailable = isAvailable
                case .failure(let error):
                    print("error: \(error)")
                    self?.isUserNameAvailable = false
                }
            }
        }
    }
    
    init() {
        // username 이 바뀌어도 기다렸다가 0.5초에 한번 요청하도록 debounce 사용
        $username
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] userName in
                self?.checkUserNameAvailable(userName)
            }
            .store(in: &cancellables)
        
        isFormValidPublisher.assign(to: &$isValid)
        
        Publishers.CombineLatest(isUsernameLengthValidPublisher, $isUserNameAvailable)
            .map { isUsernameLengthValid, isUserNameAvailable in
                if !isUsernameLengthValid {
                    return "Username must be at leat three characters!"
                } else if !isUserNameAvailable {
                    return "This username is already taken."
                }
                return ""
            }
//        isUsernameLengthValidPublisher.map { $0 ? "" : "Username must be at least three characters!"}
            .assign(to: &$usernameMessage)
        
        Publishers.CombineLatest(isPasswordEmptyPublisher, isPasswordMatchingPublisher)
            .map { isPasswordEmtpy, isPasswordMatching in
                if isPasswordEmtpy {
                    return "Password must not be empty"
                } else if !isPasswordMatching {
                    return "Passwords do not match"
                }
                return ""
            }
            .assign(to: &$passwordMessage)
    }
}
struct ContentView: View {
    @StateObject var viewModel = SignUpFormViewModel()
    var body: some View {
        Form {
            // Username
            Section {
                TextField("Username", text: $viewModel.username)
                    .textInputAutocapitalization(.never)
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
