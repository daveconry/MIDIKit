//
//  MIDIManager State.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2023 Steffan Andrews • Licensed under MIT License
//

#if !os(tvOS) && !os(watchOS)

import Foundation
import MIDIKitCore
@_implementationOnly import CoreMIDI

extension MIDIManager {
    /// Starts the manager and registers itself with the Core MIDI subsystem.
    /// Call this method once after initializing a new instance.
    /// Subsequent calls will not have any effect.
    ///
    /// - Throws: `MIDIIOError.osStatus`
    public func start() throws {
        try eventQueue.sync {
            // if start() was already called, return
            guard coreMIDIClientRef == MIDIClientRef() else { return }
    
            try MIDIClientCreateWithBlock(clientName as CFString, &coreMIDIClientRef)
                { [weak self] notificationPtr in
                    guard let self = self else { return }
                    self.internalNotificationHandler(notificationPtr)
                }
                .throwIfOSStatusErr()
    
            // initial cache of endpoints
    
            updateObjectsCache()
        }
    }
    
    internal func internalNotificationHandler(_ pointer: UnsafePointer<MIDINotification>) {
        let internalNotification = MIDIIOInternalNotification(pointer)
    
        let cache = MIDIIOObjectCache(from: self)
    
        switch internalNotification {
        case .setupChanged,
             .added,
             .removed,
             .propertyChanged:
    
            updateObjectsCache()
    
        default:
            break
        }
    
        if let notification = MIDIIONotification(
            internalNotification,
            cache: cache
        ) {
            sendNotification(notification)
        }
    
        // propagate notification to managed objects
    
        for outputConnection in managedOutputConnections.values {
            outputConnection.notification(internalNotification)
        }
    
        for inputConnection in managedInputConnections.values {
            inputConnection.notification(internalNotification)
        }
    }
}

#endif
