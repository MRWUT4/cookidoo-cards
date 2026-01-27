//
//  AuthService.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation

@Observable
class AuthService {
    var token: AuthToken?
    var isAuthenticated: Bool { token != nil }
    var isLoading = false
    var errorMessage: String?

    private let tokenURL = URL(string: "https://de.tmmobile.vorwerk-digital.com/ciam/auth/token")!
    private let clientID = "kupferwerk-client-nwot"
    private let clientSecret = "Ls50ON1woySqs1dCdJge"

    private var basicAuthHeader: String {
        let credentials = "\(clientID):\(clientSecret)"
        let data = Data(credentials.utf8)
        return "Basic \(data.base64EncodedString())"
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("vrkPreAccessGranted=true", forHTTPHeaderField: "Cookie")

        let body = "grant_type=password&username=\(urlEncode(email))&password=\(urlEncode(password))"
        request.httpBody = Data(body.utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }

            guard httpResponse.statusCode == 200 else {
                errorMessage = "Login failed (HTTP \(httpResponse.statusCode))"
                return
            }

            token = try JSONDecoder().decode(AuthToken.self, from: data)
        } catch {
            errorMessage = "Login failed: \(error.localizedDescription)"
        }
    }

    func refresh() async {
        guard let refreshToken = token?.refreshToken else { return }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue(basicAuthHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "grant_type=refresh_token&refresh_token=\(urlEncode(refreshToken))&client_id=\(urlEncode(clientID))"
        request.httpBody = Data(body.utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                token = nil
                return
            }

            token = try JSONDecoder().decode(AuthToken.self, from: data)
        } catch {
            token = nil
        }
    }

    func logout() {
        token = nil
    }

    private func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}
