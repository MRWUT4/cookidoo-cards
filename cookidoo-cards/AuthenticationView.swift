//
//  AuthenticationView.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import SwiftUI

struct AuthenticationView: View {
    @Environment(AuthService.self) private var authService
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            if authService.isAuthenticated {
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Signed In")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Button("Logout", role: .destructive) {
                        authService.logout()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Account")
            } else {
                VStack(spacing: 24) {
                    Text("Cookidoo")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .textFieldStyle(.roundedBorder)
                    }

                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    Button {
                        Task {
                            await authService.login(email: email, password: password)
                        }
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Login")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
                }
                .padding(32)
                .frame(maxWidth: 400)
                .navigationTitle("Account")
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthService())
}
