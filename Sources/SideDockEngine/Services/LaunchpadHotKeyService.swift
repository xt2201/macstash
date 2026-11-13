//
//  LaunchpadHotKeyService.swift
//  MacStash
//

import AppKit
import Carbon
import Combine

final class LaunchpadHotKeyService {
    static let shared = LaunchpadHotKeyService()

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerRef: EventHandlerRef?
    private var cancellables: Set<AnyCancellable> = []
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4D534C50), id: 1) // 'MSLP' (MacStash Launchpad)

    private init() {
        installHotKeyHandlerIfNeeded()
        registerHotKey(shortcut: SideDockPreferences.shared.launchpadShortcut)
        subscribeToPreferences()
    }

    deinit {
        unregisterHotKey()

        if let hotKeyHandlerRef {
            RemoveEventHandler(hotKeyHandlerRef)
        }
    }

    private func subscribeToPreferences() {
        observeChanges { [weak self] in
            let shortcut = SideDockPreferences.shared.launchpadShortcut
            self?.registerHotKey(shortcut: shortcut)
        }
        .store(in: &cancellables)

        observeChanges { [weak self] in
            let isEnabled = SideDockPreferences.shared.enablesLaunchpadOverlay
            guard let self else { return }
            self.registerHotKey(shortcut: SideDockPreferences.shared.launchpadShortcut)
            if !isEnabled {
                LaunchpadOverlayService.shared.dismiss()
            }
        }
        .store(in: &cancellables)
    }

    private func installHotKeyHandlerIfNeeded() {
        guard hotKeyHandlerRef == nil else { return }

        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData else {
                return OSStatus(eventNotHandledErr)
            }

            let service = Unmanaged<LaunchpadHotKeyService>.fromOpaque(userData).takeUnretainedValue()
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr, hotKeyID.signature == service.hotKeyID.signature else {
                return OSStatus(eventNotHandledErr)
            }

            Task { @MainActor in
                guard SideDockPreferences.shared.enablesLaunchpadOverlay else {
                    return
                }
                LaunchpadOverlayService.shared.toggle()
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &hotKeyHandlerRef
        )
    }

    private func registerHotKey(shortcut: KeyboardShortcut) {
        unregisterHotKey()

        guard SideDockPreferences.shared.enablesLaunchpadOverlay, shortcut.isValid else {
            return
        }

        RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifierFlags,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}
