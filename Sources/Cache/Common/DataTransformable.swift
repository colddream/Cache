//
//  DataTransformable.swift
//  Cache
//
//  Created by Do Thang on 19/12/2022.
//

import Foundation

public protocol DataTransformable {
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self?
}
