import Foundation
import CoreGraphics

public enum ResetReason: String, Sendable {
    case spaceChange
    case fullscreenToggle
    case screenLock
    case systemSleep
    case missionControl
    case displayConfigurationChange
    case appDeactivated
    case manual
}

public enum OverlayState: Equatable, Sendable {
    case hidden
    case pendingShow(generation: UInt64, corner: CornerPosition, displayID: CGDirectDisplayID)
    case visible(generation: UInt64, corner: CornerPosition, displayID: CGDirectDisplayID, isInteracting: Bool)
    case pendingHide(generation: UInt64, corner: CornerPosition, displayID: CGDirectDisplayID)

    public var isVisibleOrPending: Bool {
        switch self {
        case .hidden: return false
        case .pendingShow, .visible, .pendingHide: return true
        }
    }

    public var isVisible: Bool {
        switch self {
        case .visible: return true
        default: return false
        }
    }
}

public enum OverlayEvent: Sendable {
    case mouseEnteredHotZone(corner: CornerPosition, displayID: CGDirectDisplayID)
    case dwellTimerFired(generation: UInt64)
    case mouseMovedInsideDial
    case mouseExitedDialZone
    case hideTimerFired(generation: UInt64)
    case startInteraction
    case stopInteraction
    case reset(reason: ResetReason)
}

public struct TransitionEffect: Sendable {
    public enum Action: Equatable, Sendable {
        case scheduleDwellTimer(generation: UInt64, delaySeconds: TimeInterval)
        case cancelDwellTimer(generation: UInt64)
        case showDial(generation: UInt64, corner: CornerPosition, displayID: CGDirectDisplayID)
        case scheduleHideTimer(generation: UInt64, delaySeconds: TimeInterval)
        case cancelHideTimer(generation: UInt64)
        case hideDial(generation: UInt64, corner: CornerPosition, displayID: CGDirectDisplayID)
    }

    public let oldState: OverlayState
    public let newState: OverlayState
    public let actions: [Action]
}

public final class OverlayStateMachine {
    public private(set) var currentState: OverlayState = .hidden
    private var currentGeneration: UInt64 = 0

    public let dwellDelaySeconds: TimeInterval
    public let hideDelaySeconds: TimeInterval

    public init(
        dwellDelaySeconds: TimeInterval = Defaults.HotCorner.defaultDwellDelaySeconds,
        hideDelaySeconds: TimeInterval = Defaults.HotCorner.defaultHideDelaySeconds
    ) {
        self.dwellDelaySeconds = max(Defaults.HotCorner.minDwellDelaySeconds, min(Defaults.HotCorner.maxDwellDelaySeconds, dwellDelaySeconds))
        self.hideDelaySeconds = max(Defaults.HotCorner.minHideDelaySeconds, min(Defaults.HotCorner.maxHideDelaySeconds, hideDelaySeconds))
    }

    public func handle(event: OverlayEvent) -> TransitionEffect {
        let oldState = currentState
        var actions: [TransitionEffect.Action] = []

        switch (currentState, event) {
        case (.hidden, .mouseEnteredHotZone(let corner, let displayID)):
            currentGeneration += 1
            let gen = currentGeneration
            currentState = .pendingShow(generation: gen, corner: corner, displayID: displayID)
            actions.append(.scheduleDwellTimer(generation: gen, delaySeconds: dwellDelaySeconds))

        case (.pendingShow(let gen, let corner, let displayID), .dwellTimerFired(let timerGen)):
            if gen == timerGen {
                currentState = .visible(generation: gen, corner: corner, displayID: displayID, isInteracting: false)
                actions.append(.showDial(generation: gen, corner: corner, displayID: displayID))
            }

        case (.pendingShow(let gen, _, _), .mouseExitedDialZone):
            actions.append(.cancelDwellTimer(generation: gen))
            currentState = .hidden

        case (.visible(let gen, let corner, let displayID, false), .mouseExitedDialZone):
            currentState = .pendingHide(generation: gen, corner: corner, displayID: displayID)
            actions.append(.scheduleHideTimer(generation: gen, delaySeconds: hideDelaySeconds))

        case (.pendingHide(let gen, let corner, let displayID), .mouseMovedInsideDial):
            actions.append(.cancelHideTimer(generation: gen))
            currentState = .visible(generation: gen, corner: corner, displayID: displayID, isInteracting: false)

        case (.pendingHide(let gen, let corner, let displayID), .hideTimerFired(let timerGen)):
            if gen == timerGen {
                currentState = .hidden
                actions.append(.hideDial(generation: gen, corner: corner, displayID: displayID))
            }

        case (.visible(let gen, let corner, let displayID, _), .startInteraction):
            currentState = .visible(generation: gen, corner: corner, displayID: displayID, isInteracting: true)

        case (.visible(let gen, let corner, let displayID, true), .stopInteraction):
            currentState = .visible(generation: gen, corner: corner, displayID: displayID, isInteracting: false)

        case (.pendingHide(let gen, let corner, let displayID), .startInteraction):
            actions.append(.cancelHideTimer(generation: gen))
            currentState = .visible(generation: gen, corner: corner, displayID: displayID, isInteracting: true)

        case (_, .reset):
            switch currentState {
            case .pendingShow(let gen, _, _):
                actions.append(.cancelDwellTimer(generation: gen))
            case .pendingHide(let gen, let corner, let displayID):
                actions.append(.cancelHideTimer(generation: gen))
                actions.append(.hideDial(generation: gen, corner: corner, displayID: displayID))
            case .visible(let gen, let corner, let displayID, _):
                actions.append(.hideDial(generation: gen, corner: corner, displayID: displayID))
            case .hidden:
                break
            }
            currentState = .hidden

        default:
            // Invalid or no-op transition for current state
            break
        }

        return TransitionEffect(oldState: oldState, newState: currentState, actions: actions)
    }
}
