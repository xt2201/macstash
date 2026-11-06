import Foundation
import CoreGraphics
import MacStashCore

public enum OverlayStateMachineTests {
    public static func run() {
        testNormalShowAndHideFlow()
        testQuickLeaveBeforeDwellCancelsShow()
        testReenteringDialCancelsHide()
        testResetImmediatelyHidesAll()
    }

    private static func testNormalShowAndHideFlow() {
        let fsm = OverlayStateMachine(dwellDelaySeconds: 0.2, hideDelaySeconds: 0.25)
        TestAssertion.assertEqual(fsm.currentState, OverlayState.hidden)

        let enterEffect = fsm.handle(event: .mouseEnteredHotZone(corner: CornerPosition.bottomRight, displayID: 1))
        guard case .pendingShow(let gen, let corner, let displayID) = fsm.currentState else {
            TestAssertion.assertTrue(false, "State should be pendingShow")
            return
        }
        TestAssertion.assertEqual(corner, CornerPosition.bottomRight)
        TestAssertion.assertEqual(displayID, CGDirectDisplayID(1))
        TestAssertion.assertEqual(enterEffect.actions, [.scheduleDwellTimer(generation: gen, delaySeconds: 0.2)])

        let dwellEffect = fsm.handle(event: .dwellTimerFired(generation: gen))
        guard case .visible(let visibleGen, _, _, let isInteracting) = fsm.currentState else {
            TestAssertion.assertTrue(false, "State should be visible")
            return
        }
        TestAssertion.assertEqual(visibleGen, gen)
        TestAssertion.assertFalse(isInteracting)
        TestAssertion.assertEqual(dwellEffect.actions, [.showDial(generation: gen, corner: CornerPosition.bottomRight, displayID: 1)])

        let exitEffect = fsm.handle(event: .mouseExitedDialZone)
        guard case .pendingHide(let hideGen, _, _) = fsm.currentState else {
            TestAssertion.assertTrue(false, "State should be pendingHide")
            return
        }
        TestAssertion.assertEqual(hideGen, gen)
        TestAssertion.assertEqual(exitEffect.actions, [.scheduleHideTimer(generation: gen, delaySeconds: 0.25)])

        let hideEffect = fsm.handle(event: .hideTimerFired(generation: gen))
        TestAssertion.assertEqual(fsm.currentState, OverlayState.hidden)
        TestAssertion.assertEqual(hideEffect.actions, [.hideDial(generation: gen, corner: CornerPosition.bottomRight, displayID: 1)])
    }

    private static func testQuickLeaveBeforeDwellCancelsShow() {
        let fsm = OverlayStateMachine(dwellDelaySeconds: 0.2, hideDelaySeconds: 0.25)
        _ = fsm.handle(event: .mouseEnteredHotZone(corner: CornerPosition.topLeft, displayID: 2))

        guard case .pendingShow(let gen, _, _) = fsm.currentState else {
            TestAssertion.assertTrue(false, "State should be pendingShow")
            return
        }

        let cancelEffect = fsm.handle(event: .mouseExitedDialZone)
        TestAssertion.assertEqual(fsm.currentState, OverlayState.hidden)
        TestAssertion.assertEqual(cancelEffect.actions, [.cancelDwellTimer(generation: gen)])

        let staleEffect = fsm.handle(event: .dwellTimerFired(generation: gen))
        TestAssertion.assertEqual(fsm.currentState, OverlayState.hidden)
        TestAssertion.assertTrue(staleEffect.actions.isEmpty)
    }

    private static func testReenteringDialCancelsHide() {
        let fsm = OverlayStateMachine(dwellDelaySeconds: 0.2, hideDelaySeconds: 0.25)
        _ = fsm.handle(event: .mouseEnteredHotZone(corner: CornerPosition.bottomLeft, displayID: 1))
        guard case .pendingShow(let gen, _, _) = fsm.currentState else { return }
        _ = fsm.handle(event: .dwellTimerFired(generation: gen))
        _ = fsm.handle(event: .mouseExitedDialZone)

        guard case .pendingHide = fsm.currentState else {
            TestAssertion.assertTrue(false, "Should be pendingHide")
            return
        }

        let reenterEffect = fsm.handle(event: .mouseMovedInsideDial)
        TestAssertion.assertEqual(fsm.currentState, OverlayState.visible(generation: gen, corner: CornerPosition.bottomLeft, displayID: 1, isInteracting: false))
        TestAssertion.assertEqual(reenterEffect.actions, [.cancelHideTimer(generation: gen)])
    }

    private static func testResetImmediatelyHidesAll() {
        let fsm = OverlayStateMachine()
        _ = fsm.handle(event: .mouseEnteredHotZone(corner: CornerPosition.topRight, displayID: 1))
        guard case .pendingShow(let gen, _, _) = fsm.currentState else { return }
        _ = fsm.handle(event: .dwellTimerFired(generation: gen))

        let resetEffect = fsm.handle(event: .reset(reason: ResetReason.spaceChange))
        TestAssertion.assertEqual(fsm.currentState, OverlayState.hidden)
        TestAssertion.assertEqual(resetEffect.actions, [.hideDial(generation: gen, corner: CornerPosition.topRight, displayID: 1)])
    }
}
