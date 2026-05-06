//
//  LoginView.swift
//  WebSeries
//
//  Created by alvaro on 4/1/26.
//


import SwiftUI

struct LoginView: View {

    @EnvironmentObject var auth: AuthService

    @State private var username = ""
    @State private var password = ""
    @State private var isRegister = false
    @State private var error: String?
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.serieGalBackground, Color.serieGalSurface],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Text("SerieGal")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.serieGalText)

                    Text("Tu catálogo personal, en cualquier momento")
                        .font(.subheadline)
                        .foregroundColor(.serieGalSecondary)
                }

                VStack(spacing: 16) {
                    Text(isRegister ? "Crear cuenta" : "Iniciar sesión")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.serieGalText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    TextField("Usuario", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(ModernTextFieldStyle())

                    SecureField("Contraseña", text: $password)
                        .textFieldStyle(ModernTextFieldStyle())

                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            isSubmitting = true
                            defer { isSubmitting = false }
                            do {
                                if isRegister {
                                    try await auth.register(username: username, password: password)
                                } else {
                                    try await auth.login(username: username, password: password)
                                }
                            } catch {
                                if let apiError = error as? APIError {
                                    self.error = apiError.localizedDescription
                                } else {
                                    self.error = "Error de conexión"
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isRegister ? "Registrarse" : "Entrar")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.serieGalBlue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(username.isEmpty || password.isEmpty || isSubmitting)
                    .opacity((username.isEmpty || password.isEmpty || isSubmitting) ? 0.65 : 1)
                }
                .padding(20)
                .background(Color.serieGalCardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

                Button {
                    isRegister.toggle()
                    error = nil
                } label: {
                    Text(isRegister ? "¿Ya tienes cuenta? Inicia sesión"
                                    : "¿No tienes cuenta? Regístrate")
                        .font(.caption)
                        .foregroundColor(.serieGalSecondary)
                }

                Spacer()
            }
            .padding()
        }
    }
}

private struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.serieGalSurface)
            .foregroundColor(.serieGalText)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
