//
//  Error.swift
//  GraphJS
//
//  Created by CAMOBAP on 9/1/18.
//  Copyright © 2018 Pho Networks. All rights reserved.
//

import Foundation

enum GraphJsApiError: Error {
    case invalidEmailError(String)
    case serverError(String)
}

extension GraphJsApiError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidEmailError:
            return "Valid email required."
        case .serverError(let reason):
            return reason
        }
    }
}
