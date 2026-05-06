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
    }

    var isLoggedIn: Bool {
        token != nil
    }

    func login(username: String, password: String) async throws {
        let body = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let data = try await APIClient.request(
            endpoint: "/login",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        token = response.token
    }

    func register(username: String, password: String) async throws {
        let body = try JSONEncoder().encode(LoginRequest(username: username, password: password))

        let data = try await APIClient.request(
            endpoint: "/register",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(LoginResponse.self, from: data)
        token = response.token
    }

    func logout() {
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
