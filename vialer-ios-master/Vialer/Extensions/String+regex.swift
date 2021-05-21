//
//  String+regex.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

extension NSString {

    /// Replace regex in String with a string
    ///
    /// - Parameters:
    ///   - pattern: The regex pattern (1 capture group needed).
    ///   - with: The string that will replace the pattern.
    /// - Returns: String with replaces regexes.
    @objc func replaceRegex(pattern: String, with substitute: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let matches = regex.matches(in: self as String, range: NSRange(location: 0, length: self.length))
            var result = self
            for match in matches {
                result = result.replacingCharacters(in: match.range(at: 1), with: substitute) as NSString
            }
            return result as String
        } catch let error {
            VialerLogError("Couldn't replace regex: \(pattern) in \(self). Error: \(error)")
            return self as String
        }
    }
}

extension String {

    /// Find the first match of the capture group.
    ///
    /// - Parameter regex: The regex pattern (1 capture group needed).
    /// - Returns: String with with the capture group.
    func firstMatch(for regex: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = self as NSString
            if let result = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: nsString.length)) {
                return nsString.substring(with: result.range(at: 1))
            }
            return nil
        } catch let error {
            VialerLogError("invalid regex: \(error.localizedDescription)")
            return nil
        }
    }
}
