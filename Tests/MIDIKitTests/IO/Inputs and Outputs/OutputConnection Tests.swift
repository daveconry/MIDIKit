//
//  OutputConnection Tests.swift
//  MIDIKit • https://github.com/orchetect/MIDIKit
//

// iOS Simulator XCTest testing does not give enough permissions to allow creating virtual MIDI ports, so skip these tests on iOS targets
#if shouldTestCurrentPlatform && !targetEnvironment(simulator)

import XCTest
import MIDIKit
import CoreMIDI

final class InputsAndOutputs_OutputConnection_Tests: XCTestCase {
	
    @MIDI.Atomic var input1Events: [MIDI.Event] = []
    @MIDI.Atomic var input2Events: [MIDI.Event] = []
    
	func testOutputConnection() throws {
		
        let manager = MIDI.IO.Manager(clientName: UUID().uuidString,
                                      model: "MIDIKit123",
                                      manufacturer: "MIDIKit")
        
		// start midi client
		try manager.start()
		wait(sec: 0.1)
		
        input1Events = []
        input2Events = []
        
        // create a virtual input
        let input1Tag = "input1"
        try manager.addInput(
            name: "MIDIKit IO Tests Input 1",
            tag: input1Tag,
            uniqueID: .none, // allow system to generate random ID
            receiveHandler: .events { events in
                self.input1Events.append(contentsOf: events)
            }
        )
        let input1 = try XCTUnwrap(manager.managedInputs[input1Tag])
        let input1ID = try XCTUnwrap(input1.uniqueID)
        let input1Ref = try XCTUnwrap(input1.coreMIDIInputPortRef)
        
        // add new connection
        let connTag = "testOutputConnection"
        try manager.addOutputConnection(
            toInputs: [.uniqueID(input1ID)],
            tag: connTag
        )
		
        let conn = try XCTUnwrap(manager.managedOutputConnections[connTag])
        wait(sec: 0.5) // some time for connection to setup
        
        XCTAssertEqual(conn.inputsCriteria, [.uniqueID(input1ID)])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [input1Ref])
        XCTAssertEqual(conn.endpoints, [input1.endpoint])
        
        // attempt to send a midi message
        try conn.send(event: .start())
        wait(sec: 0.2)
        XCTAssertEqual(input1Events, [.start()])
        XCTAssertEqual(input2Events, [])
        input1Events = []
        input2Events = []
        
        // create a 2nd virtual input
        let input2Tag = "input2"
        try manager.addInput(
            name: "MIDIKit IO Tests Input 2",
            tag: input2Tag,
            uniqueID: .none, // allow system to generate random ID
            receiveHandler: .events { events in
                self.input2Events.append(contentsOf: events)
            }
        )
        let input2 = try XCTUnwrap(manager.managedInputs[input2Tag])
        let input2ID = try XCTUnwrap(input2.uniqueID)
        let input2Ref = try XCTUnwrap(input2.coreMIDIInputPortRef)
        
        // add 2nd input to the connection
        conn.add(inputs: [.uniqueID(input2ID)])
        wait(sec: 0.3)
        XCTAssertEqual(conn.inputsCriteria, [.uniqueID(input1ID), .uniqueID(input2ID)])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [input1Ref, input2Ref])
        XCTAssertEqual(Set(conn.endpoints), [input1.endpoint, input2.endpoint])
        
        // attempt to send a midi message
        try conn.send(event: .stop())
        wait(sec: 0.2)
        XCTAssertEqual(input1Events, [.stop()])
        XCTAssertEqual(input2Events, [.stop()])
        input1Events = []
        input2Events = []
        
        // remove 1st input from connection
        conn.remove(inputs: [.uniqueID(input1ID)])
        wait(sec: 0.3)
        XCTAssertEqual(conn.inputsCriteria, [.uniqueID(input2ID)])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [input2Ref])
        XCTAssertEqual(conn.endpoints, [input2.endpoint])
        
        // attempt to send a midi message
        try conn.send(event: .continue())
        wait(sec: 0.2)
        XCTAssertEqual(input1Events, [])
        XCTAssertEqual(input2Events, [.continue()])
        input1Events = []
        input2Events = []
        
        // remove 2nd input from connection
        conn.remove(inputs: [.uniqueID(input2ID)])
        wait(sec: 0.3)
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
        // attempt to send a midi message
        try conn.send(event: .songSelect(number: 2))
        wait(sec: 0.2)
        XCTAssertEqual(input1Events, [])
        XCTAssertEqual(input2Events, [])
        input1Events = []
        input2Events = []
        
    }
    
    /// Test to ensure a new input appearing in the system gets added to the connection. (Allowing manager-owned virtual inputs to be added)
    func testOutputConnection_automaticallyAddNewInputs() throws {
        
        let manager = MIDI.IO.Manager(clientName: UUID().uuidString,
                                      model: "MIDIKit123",
                                      manufacturer: "MIDIKit")
        
        // start midi client
        try manager.start()
        wait(sec: 0.1)
        
        input1Events = []
        input2Events = []
        
        // add new connection
        let connTag = "testOutputConnection"
        try manager.addOutputConnection(
            toInputs: [],
            tag: connTag,
            automaticallyAddNewInputs: true,
            preventAddingManagedInputs: false
        )
        
        let conn = try XCTUnwrap(manager.managedOutputConnections[connTag])
        wait(sec: 0.5) // some time for connection to setup
        
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
        // create a virtual input
        let input1Tag = "input1"
        try manager.addInput(
            name: "MIDIKit IO Tests Input 1",
            tag: input1Tag,
            uniqueID: .none, // allow system to generate random ID
            receiveHandler: .events { events in
                self.input1Events.append(contentsOf: events)
            }
        )
        let input1 = try XCTUnwrap(manager.managedInputs[input1Tag])
        let input1ID = try XCTUnwrap(input1.uniqueID)
        let input1Ref = try XCTUnwrap(input1.coreMIDIInputPortRef)
        
        wait(for: conn.coreMIDIInputEndpointRefs, equals: [input1Ref], timeout: 1.0)
        
        // assert that input1 was automatically added to the connection
        XCTAssertEqual(conn.inputsCriteria, [.uniqueID(input1ID)])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [input1Ref])
        XCTAssertEqual(conn.endpoints, [input1.endpoint])
        
        // send an event - it should be received by the connection
        try conn.send(event: .start())
        wait(for: input1Events, equals: [.start()], timeout: 0.5)
        XCTAssertEqual(input1Events, [.start()])
        XCTAssertEqual(input2Events, [])
        input1Events = []
        input2Events = []
        
    }
    
    /// Test to ensure creating a new manager-owned virtual input does not get added to the connection if `preventAddingManagedInputs == true`
    func testOutputConnection_automaticallyAddNewInputs_preventAddingManagedInputs() throws {
        
        let manager = MIDI.IO.Manager(clientName: UUID().uuidString,
                                      model: "MIDIKit123",
                                      manufacturer: "MIDIKit")
        
        // start midi client
        try manager.start()
        wait(sec: 0.1)
        
        input1Events = []
        input2Events = []
        
        // add new connection
        let connTag = "testOutputConnection"
        try manager.addOutputConnection(
            toInputs: [],
            tag: connTag,
            automaticallyAddNewInputs: true,
            preventAddingManagedInputs: true
        )
        
        let conn = try XCTUnwrap(manager.managedOutputConnections[connTag])
        wait(sec: 0.5) // some time for connection to setup
        
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
        // create a virtual input
        let input1Tag = "input1"
        try manager.addInput(
            name: "MIDIKit IO Tests Input 1",
            tag: input1Tag,
            uniqueID: .none, // allow system to generate random ID
            receiveHandler: .events { events in
                self.input1Events.append(contentsOf: events)
            }
        )
        let input1 = try XCTUnwrap(manager.managedInputs[input1Tag]) ; _ = input1
//        let input1ID = try XCTUnwrap(input1.uniqueID)
//        let input1Ref = try XCTUnwrap(input1.coreMIDIInputPortRef)
        
        wait(sec: 0.5) // some time for connection to be notified of new input
        
        // assert that input1 was automatically added to the connection
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
        // send an event - it should not be received by the connection
        try conn.send(event: .start())
        wait(sec: 0.2) // wait a bit in case an event is sent
        XCTAssertEqual(input1Events, [])
        XCTAssertEqual(input2Events, [])
        input1Events = []
        input2Events = []
        
    }
	
    /// Test to ensure virtual input(s) owned by the manager do not get added to the connection when creating the connection.
    func testOutputConnection_preventAddingManagedInputs_onInit() throws {
        
        let manager = MIDI.IO.Manager(clientName: UUID().uuidString,
                                      model: "MIDIKit123",
                                      manufacturer: "MIDIKit")
        
        // start midi client
        try manager.start()
        wait(sec: 0.1)
        
        input1Events = []
        input2Events = []
        
        // create a virtual input
        let input1Tag = "input1"
        try manager.addInput(
            name: "MIDIKit IO Tests Input 1",
            tag: input1Tag,
            uniqueID: .none, // allow system to generate random ID
            receiveHandler: .events { events in
                self.input1Events.append(contentsOf: events)
            }
        )
        let input1 = try XCTUnwrap(manager.managedInputs[input1Tag]) ; _ = input1
//        let input1ID = try XCTUnwrap(input1.uniqueID)
//        let input1Ref = try XCTUnwrap(input1.coreMIDIInputPortRef)
        
        wait(sec: 0.2)
        
        // add new connection, attempting to connect to input1
        let connTag = "testOutputConnection"
        try manager.addOutputConnection(
            toInputs: [input1.endpoint],
            tag: connTag,
            automaticallyAddNewInputs: true,
            preventAddingManagedInputs: true
        )
        
        let conn = try XCTUnwrap(manager.managedOutputConnections[connTag])
        wait(sec: 0.5) // some time for connection to setup
        
        // assert input1 was not added to the connection
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
        // send an event - it should not be received by the connection
        try conn.send(event: .start())
        wait(sec: 0.2) // wait a bit in case an event is sent
        XCTAssertEqual(input1Events, [])
        XCTAssertEqual(input2Events, [])
        input1Events = []
        input2Events = []
        
        // check that manually adding input1 is also not allowed
        conn.add(inputs: [input1.endpoint])
        
        // assert input1 was not added to the connection
        XCTAssertEqual(conn.inputsCriteria, [])
        XCTAssertEqual(conn.coreMIDIInputEndpointRefs, [])
        XCTAssertEqual(conn.endpoints, [])
        
    }
    
}

#endif
