//
//  StringEx.swift
//  Cache
//
//  Created by Do Thang on 19/12/2022.
//

import Foundation
import CommonCrypto

extension String {
    var md5: String {
        return self.hashed(.md5) ?? self
    }

    var ext: String? {
        var ext = ""
        if let index = self.lastIndex(of: ".") {
            let extRange = self.index(index, offsetBy: 1)..<self.endIndex
            ext = String(self[extRange])
        }
        guard let firstSeg = ext.split(separator: "@").first else {
            return nil
        }
        return firstSeg.count > 0 ? String(firstSeg) : nil
    }
}
