//
//  WindowContextActions.swift
//  MacStash
//
//  Shared builder for the per-window section of context menus shown in the
//  hover preview popover and the Cmd-Tab switcher overlay. Mirrors the macOS
//  Window menu (Minimize / Zoom / Fill / Center / Move & Resize) using AX
//  geometry under the hood — no menu-walking, so this works for every app
//  that responds to AX position/size, not just Cocoa apps with a standard
//  Window menu.
//

import AppKit
import MacStashCore

@MainActor
func windowMenuContextActions(
    for window: AppWindow,
    dismiss: @escaping () -> Void
) -> [ContextAction] {
    let workspace = WorkspaceService.shared
    let loc = LocalizationService.shared

    func run(_ action: @escaping (AppWindow) -> Bool) -> () -> Void {
        return {
            dismiss()
            _ = action(window)
        }
    }

    return [
        .action(loc.localized("dock.menu.minimize"), image: contextMenuSymbol("minus.circle"), handler: run(workspace.minimize(window:))),
        .action(loc.localized("dock.menu.zoom"), image: contextMenuSymbol("arrow.up.left.and.arrow.down.right"), handler: run(workspace.zoom(window:))),
        .action(loc.localized("dock.menu.fill"), image: contextMenuSymbol("rectangle.fill"), handler: run(workspace.fill(window:))),
        .action(loc.localized("dock.menu.center"), image: contextMenuSymbol("rectangle.center.inset.filled"), handler: run(workspace.center(window:))),
        .submenu(loc.localized("dock.menu.moveAndResize"), children: [
            .action(loc.localized("dock.menu.left"), image: contextMenuSymbol("rectangle.lefthalf.filled"), handler: run(workspace.fillLeftHalf(window:))),
            .action(loc.localized("dock.menu.right"), image: contextMenuSymbol("rectangle.righthalf.filled"), handler: run(workspace.fillRightHalf(window:))),
            .action(loc.localized("dock.menu.top"), image: contextMenuSymbol("rectangle.tophalf.filled"), handler: run(workspace.fillTopHalf(window:))),
            .action(loc.localized("dock.menu.bottom"), image: contextMenuSymbol("rectangle.bottomhalf.filled"), handler: run(workspace.fillBottomHalf(window:))),
            .divider,
            .action(loc.localized("dock.menu.topLeft"), image: contextMenuSymbol("arrow.up.left"), handler: run(workspace.fillTopLeftQuarter(window:))),
            .action(loc.localized("dock.menu.topRight"), image: contextMenuSymbol("arrow.up.right"), handler: run(workspace.fillTopRightQuarter(window:))),
            .action(loc.localized("dock.menu.bottomLeft"), image: contextMenuSymbol("arrow.down.left"), handler: run(workspace.fillBottomLeftQuarter(window:))),
            .action(loc.localized("dock.menu.bottomRight"), image: contextMenuSymbol("arrow.down.right"), handler: run(workspace.fillBottomRightQuarter(window:))),
        ]),
    ]
}
