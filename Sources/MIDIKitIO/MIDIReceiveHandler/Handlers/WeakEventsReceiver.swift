//
//  WeakEventsReceiver.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//  © 2021-2023 Steffan Andrews • Licensed under MIT License
//

#if !os(tvOS) && !os(watchOS)

extension MIDIReceiveHandler {
    /// MIDI Event receive handler that holds a weak reference to a receiver object.
    internal final class WeakEventsReceiver: MIDIReceiveHandlerProtocol {
        public weak var receiver: ReceivesMIDIEvents?
    
        internal let midi1Parser = MIDI1Parser()
        internal let midi2Parser = MIDI2Parser()
    
        public func packetListReceived(
            _ packets: [MIDIPacketData]
        ) {
            for midiPacket in packets {
                let events = midi1Parser.parsedEvents(in: midiPacket)
                guard !events.isEmpty else { continue }
                receiver?.midiIn(events: events)
            }
        }
    
        @available(macOS 11, iOS 14, macCatalyst 14, *)
        public func eventListReceived(
            _ packets: [UniversalMIDIPacketData],
            protocol midiProtocol: MIDIProtocolVersion
        ) {
            for midiPacket in packets {
                let events = midi2Parser.parsedEvents(in: midiPacket)
                guard !events.isEmpty else { continue }
                receiver?.midiIn(events: events)
            }
        }
    
        internal init(
            translateMIDI1NoteOnZeroVelocityToNoteOff: Bool = true,
            receiver: ReceivesMIDIEvents
        ) {
            midi1Parser.translateNoteOnZeroVelocityToNoteOff =
                translateMIDI1NoteOnZeroVelocityToNoteOff
            self.receiver = receiver
        }
    }
}

#endif
