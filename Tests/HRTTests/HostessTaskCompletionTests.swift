//
//  HostessTaskCompletionTests.swift
//  HOSTESS Reference Toolkit Tests
//
//  Created by Ky on 2026-06-04.
//

import Foundation
import Testing

import HRT



@Suite("HostessTask.Completion init(taskState:completionPercentage:)")
struct HostessTaskCompletionInitTests {
    
    // MARK: nil state
    
    @Test("nil state and nil percentage produce .notStarted")
    func nilStateNilPercentage() {
        let completion = HostessTask.Completion(taskState: nil, completionPercentage: nil)
        #expect(completion == .notStarted)
    }
    
    
    @Test("nil state with a percentage produces .inProgress with that percentage",
          arguments: [CGFloat(0.0), 0.25, 0.5, 0.75, 1.0])
    func nilStateWithPercentage(percentage: CGFloat) {
        let completion = HostessTask.Completion(taskState: nil, completionPercentage: percentage)
        #expect(completion == .inProgress(percentage: percentage))
    }
    
    
    // MARK: .open state
    
    @Test(".open with nil percentage produces .notStarted")
    func openNilPercentage() {
        let completion = HostessTask.Completion(taskState: .open, completionPercentage: nil)
        #expect(completion == .notStarted)
    }
    
    
    @Test(".open with non-positive percentage produces .notStarted",
          arguments: [CGFloat(0.0), -0.1, -1.0])
    func openNonPositivePercentage(percentage: CGFloat) {
        // The implementation uses `> 0`, so zero and negative percentages
        // are treated as "not started yet".
        let completion = HostessTask.Completion(taskState: .open, completionPercentage: percentage)
        #expect(completion == .notStarted)
    }
    
    
    @Test(".open with positive percentage <= 1 produces .inProgress with that percentage",
          arguments: [CGFloat(0.01), 0.25, 0.5, 0.75, 1.0])
    func openPositivePercentage(percentage: CGFloat) {
        let completion = HostessTask.Completion(taskState: .open, completionPercentage: percentage)
        #expect(completion == .inProgress(percentage: percentage))
    }
    
    
    /// An over-1.0 percentage paired with `.open` is implementation-defined:
    /// the current behavior is to clamp to `.complete`, treating "more than
    /// 100% done" as "done". This pins the contract down.
    @Test(".open with percentage > 1 produces .complete",
          arguments: [CGFloat(1.001), 1.5, 2.0, 100.0])
    func openOverhundredPercent(percentage: CGFloat) {
        let completion = HostessTask.Completion(taskState: .open, completionPercentage: percentage)
        #expect(completion == .complete)
    }
    
    
    // MARK: .complete state
    
    @Test(".complete always produces .complete regardless of percentage",
          arguments: [Optional<CGFloat>.none, .some(0.0), .some(0.5), .some(1.0), .some(2.0)])
    func completeIgnoresPercentage(percentage: CGFloat?) {
        let completion = HostessTask.Completion(taskState: .complete, completionPercentage: percentage)
        #expect(completion == .complete)
    }
    
    
    // MARK: .dropped state
    
    @Test(".dropped always produces .dropped regardless of percentage",
          arguments: [Optional<CGFloat>.none, .some(0.0), .some(0.5), .some(1.0)])
    func droppedIgnoresPercentage(percentage: CGFloat?) {
        let completion = HostessTask.Completion(taskState: .dropped, completionPercentage: percentage)
        #expect(completion == .dropped)
    }
}



@Suite("HostessTask.Completion to-primitive conversion")
struct HostessTaskCompletionToPrimitiveTests {
    
    @Test("taskState maps each completion to its expected state",
          arguments: zip(
            [HostessTask.Completion.notStarted,
             .inProgress(percentage: 0.5),
             .complete,
             .dropped],
            [HostessTask.State.open,
             .open,
             .complete,
             .dropped]
          ))
    func taskStateMapping(completion: HostessTask.Completion, expected: HostessTask.State) {
        #expect(completion.taskState == expected)
    }
    
    
    @Test("completionPercentage maps each completion to its numeric percentage",
          arguments: zip(
            [HostessTask.Completion.notStarted,
             .inProgress(percentage: 0.42),
             .complete,
             .dropped],
            [Optional<CGFloat>.none,
             .some(0.42),
             .some(1.0),
             .none]
          ))
    func completionPercentageMapping(completion: HostessTask.Completion, expected: CGFloat?) {
        #expect(completion.completionPercentage == expected)
    }
    
    
    /// A round-trip through the two primitive views must not lose information
    /// for any "reasonable" completion value. (We exclude `.inProgress` with
    /// out-of-range percentages because the init explicitly clamps those.)
    @Test("Round-trip through state+percentage preserves the completion",
          arguments: [
            HostessTask.Completion.notStarted,
            .inProgress(percentage: 0.5),
            .complete,
            .dropped,
          ])
    func primitiveRoundTrip(completion: HostessTask.Completion) {
        let recovered = HostessTask.Completion(
            taskState: completion.taskState,
            completionPercentage: completion.completionPercentage
        )
        #expect(recovered == completion)
    }
}



@Suite("HostessTask.State init(_: Completion)")
struct HostessTaskStateFromCompletionTests {
    
    @Test("Each completion maps to its expected state",
          arguments: zip(
            [HostessTask.Completion.notStarted,
             .inProgress(percentage: 0.3),
             .complete,
             .dropped],
            [HostessTask.State.open,
             .open,
             .complete,
             .dropped]
          ))
    func stateInitFromCompletion(completion: HostessTask.Completion, expected: HostessTask.State) {
        #expect(HostessTask.State(completion) == expected)
    }
}



@Suite("HostessTask.Completion.toggle (default behavior)")
struct HostessTaskCompletionToggleDefaultTests {
    
    /// `.default` is documented as a stable, reasonable default. If that
    /// changes in a release, callers depending on it will break, so it's
    /// worth pinning down.
    @Test("ToggleBehavior.default is .toggleCompleteAndNotStarted")
    func defaultIsCompleteAndNotStarted() {
        #expect(HostessTask.Completion.ToggleBehavior.default == .toggleCompleteAndNotStarted)
    }
}



@Suite("HostessTask.Completion.toggled(.toggleCompleteAndNotStarted)")
struct HostessTaskCompletionToggleCompleteTests {
    
    /// These cases enumerate the contract documented on `.toggleCompleteAndNotStarted`:
    /// `.notStarted` and `.inProgress` and `.dropped` all flip to `.complete` or
    /// `.notStarted`, never staying put.
    @Test("Each starting completion toggles to its documented partner",
          arguments: [
            (start: HostessTask.Completion.notStarted,                    expected: .complete),
            (start: .inProgress(percentage: 0.0),                         expected: .complete),
            (start: .inProgress(percentage: 0.5),                         expected: .complete),
            (start: .inProgress(percentage: 1.0),                         expected: .complete),
            (start: .inProgress(percentage: 1.5),                         expected: .complete),
            (start: .complete,                                            expected: .notStarted),
            (start: .dropped,                                             expected: .notStarted),
          ] as [(start: HostessTask.Completion, expected: HostessTask.Completion)])
    func toggleCompleteAndNotStarted(start: HostessTask.Completion,
                                     expected: HostessTask.Completion) {
        #expect(start.toggled(withBehavior: .toggleCompleteAndNotStarted) == expected)
    }
    
    
    /// `toggle()` (the in-place variant) is equivalent to assigning the
    /// result of `toggled()`. This guards against the two going out of sync.
    @Test("Mutating toggle() matches non-mutating toggled()",
          arguments: [
            HostessTask.Completion.notStarted,
            .inProgress(percentage: 0.5),
            .complete,
            .dropped,
          ])
    func mutatingMatchesNonmutating(start: HostessTask.Completion) {
        var completion = start
        completion.toggle(withBehavior: .toggleCompleteAndNotStarted)
        
        #expect(completion == start.toggled(withBehavior: .toggleCompleteAndNotStarted))
    }
}



@Suite("HostessTask.Completion.toggled(.toggleDroppedAndNotStarted)")
struct HostessTaskCompletionToggleDroppedTests {
    
    @Test("Each starting completion toggles to its documented partner",
          arguments: [
            (start: HostessTask.Completion.notStarted,           expected: .dropped),
            (start: .inProgress(percentage: 0.5),                expected: .dropped),
            (start: .complete,                                   expected: .dropped),
            (start: .dropped,                                    expected: .notStarted),
          ] as [(start: HostessTask.Completion, expected: HostessTask.Completion)])
    func toggleDroppedAndNotStarted(start: HostessTask.Completion,
                                    expected: HostessTask.Completion) {
        #expect(start.toggled(withBehavior: .toggleDroppedAndNotStarted) == expected)
    }
    
    
    @Test("Mutating toggle() matches non-mutating toggled()",
          arguments: [
            HostessTask.Completion.notStarted,
            .inProgress(percentage: 0.5),
            .complete,
            .dropped,
          ])
    func mutatingMatchesNonmutating(start: HostessTask.Completion) {
        var completion = start
        completion.toggle(withBehavior: .toggleDroppedAndNotStarted)
        
        #expect(completion == start.toggled(withBehavior: .toggleDroppedAndNotStarted))
    }
}
