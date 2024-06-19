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
        Publishers.CombineLatest3(isUsernameLengthValidPublisher, isUsernameAvailablePublisher, isPasswordValidPublisher)
            .map { $0 && $1 && $2 }
            .eraseToAnyPublisher()
    }()
    
    private lazy var isUsernameAvailablePublisher: AnyPublisher<Bool, Never> = {
        $username
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .removeDuplicates()
            // 중첩 배열을 단일 배열로
            // Combine 에서는 개시자를 Publisher 개체로 변경
            .flatMap { username -> AnyPublisher<Bool, Never> in
                self.authenticationService.checkUserNameAvailable(userName: username)
                    .catch { error in
                        return Just(false)
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .share()
            .print("share")
            .eraseToAnyPublisher()
    }()
    
    init() {
        
        isFormValidPublisher.assign(to: &$isValid)
        
        Publishers.CombineLatest(isUsernameLengthValidPublisher, isUsernameAvailablePublisher)
            .map { isUsernameLengthValid, isUserNameAvailable in
                if !isUsernameLengthValid {
                    return "Username must be at leat three characters!"
                } else if !isUserNameAvailable {
                    return "This username is already taken."
                }
                return ""
            }
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
