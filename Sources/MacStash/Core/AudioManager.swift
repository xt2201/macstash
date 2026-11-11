import Foundation
import CoreAudio
import AudioToolbox
import Combine

public struct AudioDeviceItem: Identifiable, Equatable {
    public var id: AudioDeviceID
    public var name: String
    public var isDefault: Bool
}

/// Manages macOS system master volume, mute, and output device routing via CoreAudio
@MainActor
public final class AudioManager: ObservableObject {
    public static let shared = AudioManager()

    @Published public private(set) var volume: Float = 0.5
    @Published public private(set) var isMuted: Bool = false
    @Published public private(set) var deviceName: String = "Internal Speakers"
    @Published public private(set) var outputDevices: [AudioDeviceItem] = []

    private var defaultOutputDeviceID: AudioDeviceID = 0
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var scalarVolumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var muteListenerBlock: AudioObjectPropertyListenerBlock?
    private var defaultDeviceListenerBlock: AudioObjectPropertyListenerBlock?
    private var syncTimer: Timer?
    private var preMuteVolume: Float = 0.35
    private let hardwareQueue = DispatchQueue(label: "com.macstash.audio.hardware", qos: .userInteractive)
    private var lastUserVolumeSetTime: TimeInterval = 0

    private init() {
        refreshDefaultDevice()
        refreshOutputDevices()
        setupListeners()
        setupDefaultDeviceListener()
        updateVolumeFromHardware(force: true)
        setupPeriodicSync()
    }

    private func setupPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateVolumeFromHardware(force: false)
            }
        }
    }


    // MARK: - Device Queries & Switching

    public func refreshDefaultDevice() {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout.size(ofValue: deviceID))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        if status == noErr {
            self.defaultOutputDeviceID = deviceID
            fetchDeviceName(deviceID: deviceID)
        }
    }

    public func refreshOutputDevices() {
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        )
        guard status == noErr else { return }

        let count = Int(size) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        let getStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceIDs
        )
        guard getStatus == noErr else { return }

        var list: [AudioDeviceItem] = []
        for dev in deviceIDs {
            var streamSize: UInt32 = 0
            var streamAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectGetPropertyDataSize(dev, &streamAddr, 0, nil, &streamSize)

            if streamSize > 0 {
                var name: Unmanaged<CFString>?
                var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
                var nameAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioObjectPropertyName,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                AudioObjectGetPropertyData(dev, &nameAddr, 0, nil, &nameSize, &name)
                if let str = name?.takeRetainedValue() as String? {
                    list.append(AudioDeviceItem(id: dev, name: str, isDefault: dev == self.defaultOutputDeviceID))
                }
            }
        }

        DispatchQueue.main.async {
            self.outputDevices = list
        }
    }

    public func selectOutputDevice(id: AudioDeviceID) {
        var targetID = id
        let size = UInt32(MemoryLayout.size(ofValue: targetID))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &targetID
        )

        if status == noErr {
            refreshDefaultDevice()
            refreshOutputDevices()
            updateVolumeFromHardware()
        }
    }

    private func fetchDeviceName(deviceID: AudioDeviceID) {
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &name
        )

        if status == noErr, let cfName = name?.takeRetainedValue() {
            DispatchQueue.main.async {
                self.deviceName = cfName as String
            }
        }
    }

    // MARK: - Get & Set Volume

    public func setVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        if defaultOutputDeviceID == 0 {
            refreshDefaultDevice()
        }
        let devID = defaultOutputDeviceID
        guard devID != 0 else { return }

        // Optimistically update UI state immediately for 120fps zero-latency scrubbing
        self.lastUserVolumeSetTime = ProcessInfo.processInfo.systemUptime
        self.volume = clamped
        let shouldUnmute = self.isMuted && clamped > 0
        if shouldUnmute {
            self.isMuted = false
        }

        // Dispatch CoreAudio IPC asynchronously so the main thread never stalls during drag/scroll
        hardwareQueue.async {
            var vol = clamped
            let size = UInt32(MemoryLayout.size(ofValue: vol))
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )

            var status = AudioObjectSetPropertyData(
                devID,
                &address,
                0,
                nil,
                size,
                &vol
            )

            if status != noErr {
                var scalarAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                status = AudioObjectSetPropertyData(
                    devID,
                    &scalarAddr,
                    0,
                    nil,
                    size,
                    &vol
                )
            }

            if shouldUnmute {
                var muteVal: UInt32 = 0
                let muteSize = UInt32(MemoryLayout.size(ofValue: muteVal))
                var muteAddr = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyMute,
                    mScope: kAudioObjectPropertyScopeOutput,
                    mElement: kAudioObjectPropertyElementMain
                )
                _ = AudioObjectSetPropertyData(devID, &muteAddr, 0, nil, muteSize, &muteVal)
            }
        }
    }

    public func toggleMute() {
        setMute(!isMuted)
    }

    public func setMute(_ mute: Bool) {
        if defaultOutputDeviceID == 0 {
            refreshDefaultDevice()
        }
        guard defaultOutputDeviceID != 0 else { return }

        if mute && volume > 0.02 {
            preMuteVolume = volume
        }

        var muteVal: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout.size(ofValue: muteVal))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            size,
            &muteVal
        )

        self.isMuted = mute

        if mute {
            if status != noErr {
                setVolume(0.0)
            }
        } else {
            // When unmuting: restore preMuteVolume if volume was at 0
            if volume <= 0.01 {
                setVolume(max(0.20, preMuteVolume))
            } else if status != noErr {
                setVolume(volume)
            }
        }

        // Background AppleScript trigger as robust system-wide fallback
        DispatchQueue.global(qos: .userInitiated).async {
            let script = "set volume output muted \(mute ? "true" : "false")"
            if let appleScript = NSAppleScript(source: script) {
                var err: NSDictionary?
                appleScript.executeAndReturnError(&err)
            }
        }
    }

    public func updateVolumeFromHardware(force: Bool = false) {
        if !force && (ProcessInfo.processInfo.systemUptime - lastUserVolumeSetTime) < 0.18 {
            return
        }
        if defaultOutputDeviceID == 0 {
            refreshDefaultDevice()
        }
        guard defaultOutputDeviceID != 0 else { return }

        var vol: Float32 = 0.0
        var size = UInt32(MemoryLayout.size(ofValue: vol))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var status = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &size,
            &vol
        )

        if status != noErr {
            var scalarAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            status = AudioObjectGetPropertyData(
                defaultOutputDeviceID,
                &scalarAddr,
                0,
                nil,
                &size,
                &vol
            )
        }

        var muteVal: UInt32 = 0
        var muteSize = UInt32(MemoryLayout.size(ofValue: muteVal))
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let muteStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &muteVal
        )

        let hardwareMuted = (muteStatus == noErr && muteVal == 1)
        let isEffectivelySilent = hardwareMuted || (status == noErr && vol <= 0.001)

        if status == noErr {
            self.volume = vol
            if vol > 0.02 {
                self.preMuteVolume = vol
            }
        }
        self.isMuted = isEffectivelySilent
    }

    // MARK: - Real-time Listeners

    private func setupDefaultDeviceListener() {
        var defaultDeviceAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        defaultDeviceListenerBlock = { [weak self] (_, _) in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.removeListeners()
                self.refreshDefaultDevice()
                self.refreshOutputDevices()
                self.setupListeners()
                self.updateVolumeFromHardware(force: true)
            }
        }
        if let block = defaultDeviceListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &defaultDeviceAddr,
                DispatchQueue.main,
                block
            )
        }
    }

    private func setupListeners() {
        guard defaultOutputDeviceID != 0 else { return }

        // 1. Virtual Main Volume Listener
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        volumeListenerBlock = { [weak self] (_, _) in
            Task { @MainActor [weak self] in
                self?.updateVolumeFromHardware(force: false)
            }
        }
        if let block = volumeListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                defaultOutputDeviceID,
                &volumeAddress,
                DispatchQueue.main,
                block
            )
        }

        // 2. Scalar Volume Listener (fallback for devices that do not expose virtual main volume)
        var scalarAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        scalarVolumeListenerBlock = { [weak self] (_, _) in
            Task { @MainActor [weak self] in
                self?.updateVolumeFromHardware(force: false)
            }
        }
        if let block = scalarVolumeListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                defaultOutputDeviceID,
                &scalarAddress,
                DispatchQueue.main,
                block
            )
        }

        // 3. Hardware Mute / Silent Listener
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        muteListenerBlock = { [weak self] (_, _) in
            Task { @MainActor [weak self] in
                self?.updateVolumeFromHardware(force: true)
            }
        }
        if let block = muteListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                defaultOutputDeviceID,
                &muteAddress,
                DispatchQueue.main,
                block
            )
        }
    }

    private func removeListeners() {
        guard defaultOutputDeviceID != 0 else { return }

        if let block = volumeListenerBlock {
            var volumeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                defaultOutputDeviceID,
                &volumeAddress,
                DispatchQueue.main,
                block
            )
            volumeListenerBlock = nil
        }

        if let block = scalarVolumeListenerBlock {
            var scalarAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                defaultOutputDeviceID,
                &scalarAddress,
                DispatchQueue.main,
                block
            )
            scalarVolumeListenerBlock = nil
        }

        if let block = muteListenerBlock {
            var muteAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyMute,
                mScope: kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                defaultOutputDeviceID,
                &muteAddress,
                DispatchQueue.main,
                block
            )
            muteListenerBlock = nil
        }
    }
}
