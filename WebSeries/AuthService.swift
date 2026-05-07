//
//  AuthService.swift
//  WebSeries
//
//  Created by alvaro on 4/1/26.
//


import Foundation
import SwiftUI

@MainActor
final class AuthService: ObservableObject {

    @Published var token: String? {
        didSet {
            if let token {
                UserDefaults.standard.set(token, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }

    init() {
        token = UserDefaults.standard.string(forKey: "auth_token")
        debugLog("🔐 AuthService init. Token guardado:", token == nil ? "no" : "sí")
    }

    var isLoggedIn: Bool {
        token != nil
    }

    func login(username: String, password: String) async throws {
        debugLog("🔐 Intentando login para usuario:", username)
        let body = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let data = try await APIClient.request(
            endpoint: "/login",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        token = response.token
        debugLog("✅ Login correcto. Token actualizado.")
    }

    func register(username: String, password: String) async throws {
        debugLog("🔐 Intentando registro para usuario:", username)
        let body = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let data = try await APIClient.request(
            endpoint: "/register",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        token = response.token
        debugLog("✅ Registro correcto. Token actualizado.")
    }

    func ensureValidSession() async -> Bool {
        guard let token else {
            debugLog("⚠️ ensureValidSession: no hay token en memoria.")
            return false
        }

        do {
            _ = try await APIClient.request(
                endpoint: "/me",
                token: token
            )
            debugLog("✅ Sesión válida en /me")
            return true
        } catch {
            if let apiError = error as? APIError,
               apiError.statusCode == 401 || apiError.statusCode == 403 {
                debugLog("❌ Sesión inválida por auth en /me:", error)
                self.token = nil
                return false
            }

            if let urlError = error as? URLError {
                debugLog("🌐 No hay conexión para validar /me (\(urlError.code.rawValue)). Manteniendo sesión local.")
                return true
            }

            debugLog("⚠️ No se pudo validar /me por error no-auth. Manteniendo sesión:", error)
            return true
        }
    }

    func logout() {
        debugLog("👋 Logout manual")
        token = nil
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
}
