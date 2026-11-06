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

    private init() {
        refreshDefaultDevice()
        refreshOutputDevices()
        setupListeners()
        updateVolumeFromHardware()
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
        refreshDefaultDevice()
        guard defaultOutputDeviceID != 0 else { return }

        var vol = clamped
        let size = UInt32(MemoryLayout.size(ofValue: vol))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioHardwareServiceSetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            size,
            &vol
        )

        if status == noErr {
            DispatchQueue.main.async {
                self.volume = clamped
                if self.isMuted && clamped > 0 {
                    self.setMute(false)
                }
            }
        }
    }

    public func toggleMute() {
        setMute(!isMuted)
    }

    public func setMute(_ mute: Bool) {
        refreshDefaultDevice()
        guard defaultOutputDeviceID != 0 else { return }

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

        if status == noErr {
            DispatchQueue.main.async {
                self.isMuted = mute
            }
        }
    }

    public func updateVolumeFromHardware() {
        refreshDefaultDevice()
        guard defaultOutputDeviceID != 0 else { return }

        var vol: Float32 = 0.0
        var size = UInt32(MemoryLayout.size(ofValue: vol))
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioHardwareServiceGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &size,
            &vol
        )

        var muteVal: UInt32 = 0
        var muteSize = UInt32(MemoryLayout.size(ofValue: muteVal))
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        _ = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &muteAddress,
            0,
            nil,
            &muteSize,
            &muteVal
        )

        DispatchQueue.main.async {
            if status == noErr {
                self.volume = vol
            }
            self.isMuted = (muteVal == 1)
        }
    }

    // MARK: - Real-time Listeners

    private func setupListeners() {
        guard defaultOutputDeviceID != 0 else { return }

        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        volumeListenerBlock = { [weak self] (_, _) in
            self?.updateVolumeFromHardware()
        }

        if let block = volumeListenerBlock {
            AudioObjectAddPropertyListenerBlock(
                defaultOutputDeviceID,
                &volumeAddress,
                DispatchQueue.main,
                block
            )
        }
    }

    private func removeListeners() {
        guard defaultOutputDeviceID != 0, let block = volumeListenerBlock else { return }
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
    }
}
