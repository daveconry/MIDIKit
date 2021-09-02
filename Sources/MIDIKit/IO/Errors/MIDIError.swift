//
//  MIDIError.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//

import CoreMIDI

extension MIDI.IO {
    
    /// Error type returned by `MIDI.IO` methods.
    public enum MIDIError: Error, Hashable {
        
        // General
        
        case internalInconsistency(_ verboseError: String)
        
        case malformed(_ verboseError: String)
        
        // Connections
        
        case connectionError(_ verboseError: String)
        
        case readError(_ verboseError: String)
        
        // Core MIDI.OSStatus
        
        case osStatus(MIDI.IO.MIDIOSStatus)
        
    }
    
}

extension MIDI.IO.MIDIError {
    
    /// Convenience to return a case of `osStatus` with its associated `MIDI.IO.MIDIOSStatus` formed from a raw Core MIDI `OSStatus` (Int32) integer value.
    public static func osStatus(_ rawValue: OSStatus) -> Self {
        
        .osStatus(.init(rawValue: rawValue))
        
    }
    
}

extension MIDI.IO.MIDIError: CustomStringConvertible {
    
    public var localizedDescription: String {
        
        description
        
    }
    
    public var description: String {
        
        switch self {
        case .internalInconsistency(let verboseError):
            return verboseError
            
        case .malformed(let verboseError):
            return verboseError
            
        case .connectionError(let verboseError):
            return verboseError
            
        case .readError(let verboseError):
            return verboseError
            
        case .osStatus(let midiOSStatus):
            return midiOSStatus.description
            
        }
        
    }
    
}
