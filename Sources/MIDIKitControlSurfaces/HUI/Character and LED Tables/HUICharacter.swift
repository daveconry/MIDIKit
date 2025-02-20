//
//  HUICharacter.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2023 Steffan Andrews • Licensed under MIT License
//

import Foundation

public protocol HUICharacter: CustomStringConvertible
where Self: RawRepresentable, RawValue == UInt8, Self: CaseIterable {
    /// Returns the user-facing display string of the character.
    var string: String { get }
    
    /// Initialize from the user-facing display string of the character.
    init?<S: StringProtocol>(_ string: S)
    
    /// Suitable default case for use as a default/neutral character.
    static func `default`() -> Self
    
    /// Suitable default case for use as a substitute for an unknown character.
    static func unknown() -> Self
}

internal protocol _HUICharacter: HUICharacter {
    /// Internal:
    /// Table of characters. Array index corresponds to raw HUI encoding value.
    static var stringTable: [String] { get }
}

// MARK: - Default Implementation

extension _HUICharacter {
    /// Returns the user-facing display string of the character.
    public var string: String {
        Self.stringTable[Int(rawValue)]
    }
    
    /// Initialize from the user-facing display string of the character.
    public init?<S: StringProtocol>(_ string: S) {
        guard let idx = Self.stringTable.firstIndex(of: String(string))
        else { return nil }
        self.init(rawValue: UInt8(idx))
    }
}

// MARK: - CustomStringConvertible

extension HUICharacter /* : CustomStringConvertible */ {
    public var description: String {
        string
    }
}

// MARK: - Sequence Category Methods

extension RangeReplaceableCollection where Element: HUICharacter {
    /// Returns the HUI character sequence as a single concatenated string of characters.
    public var stringValue: String {
        map { $0.string }.joined()
    }
    
    /// Internal:
    /// Pad digits array to static count length.
    func pad(count padCount: Int, with pad: Element) -> [Element] {
        let padCount = padCount.clamped(to: 0...)
        
        switch count {
        case ..<padCount:
            return Array(self) + .init(repeating: pad, count: padCount - count)
        case (padCount + 1)...:
            return Array(prefix(padCount))
        default:
            return Array(self)
        }
    }
}
