//
//  Common.swift
//  SwiftXAtlas
//
//  Created by Tatsuya Ogawa on 2025/05/11.
//
import Foundation
func getShaderUrl(name: String) throws -> URL {
    #if false
    guard let url = Bundle.module.url(forResource: name, withExtension: "metallib") else {
        throw NSError(domain: "resource not found", code: 0)
    }
    return url
    #else
    guard let url = Bundle.main.url(forResource: name, withExtension: "metallib") else {
        throw NSError(domain: "resource not found", code: 0)
    }
    return url
    #endif
}
