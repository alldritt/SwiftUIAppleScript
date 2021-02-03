//
//  AppleScriptRunner.swift
//  AppleScriptTest
//
//  Created by Mark Alldritt on 2021-02-02.
//

import SwiftUI
import Cocoa


class AppleScriptRunner: ObservableObject, Hashable {
    //  Conform to Equitable
    static func == (lhs: AppleScriptRunner, rhs: AppleScriptRunner) -> Bool {
        return lhs.id == rhs.id
    }
    
    //  Conform to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    let script: NSAppleScript

    enum State { case idle, running, complete(NSAppleEventDescriptor), error(String) }
    
    @Published private (set) var state = State.idle

    init(_ source: String) {
        if let script = NSAppleScript(source: source) {
            self.script = script
        }
        else {
            fatalError("Cannot compile source")
        }
    }
        
    private func start() {
        state = .running
    }
    
    private func completed(_ resultDesc: NSAppleEventDescriptor, error: NSDictionary?) {
        if let error = error  {
            print("error: \(error)")
            self.state = .error(error[NSAppleScript.errorMessage] as? String ?? "unknown error")
        }
        else {
            print("result: \(resultDesc)")
            self.state = .complete(resultDesc)
        }
    }
    
    public func executeSync() {
        start()
        
        var error: NSDictionary? = nil
        let resultDesc = self.script.executeAndReturnError(&error)

        completed(resultDesc, error: error)
    }
    
    public func executeAsync() {
        start()
        DispatchQueue.global(qos: .background).async {
            var error: NSDictionary? = nil
            let resultDesc = self.script.executeAndReturnError(&error)
            
            DispatchQueue.main.async {
                self.completed(resultDesc, error: error)
            }
        }
    }

}
