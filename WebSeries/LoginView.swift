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

    var body: some View {
        VStack(spacing: 24) {

            Spacer()

            VStack(spacing: 8) {
                Text("SerieGal")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.serieGalText)

                Text(isRegister ? "Crear cuenta" : "Iniciar sesión")
                    .foregroundColor(.serieGalSecondary)
            }

            VStack(spacing: 14) {

                TextField("Usuario", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)

                SecureField("Contraseña", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            }

            if let error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                Task {
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
                Text(isRegister ? "Registrarse" : "Entrar")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.serieGalBlue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }

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
        .background(Color.serieGalBackground)
    }
}
