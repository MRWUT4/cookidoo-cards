//
//  AuthToken.swift
//  cookidoo-cards
//
//  Created by David Ochmann on 27.01.26.
//

import Foundation

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
    let sub: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case sub
    }
}
