//
//  Keymapping.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 23/08/2022.
//

import Foundation
import UniformTypeIdentifiers
import AppKit

struct KeyModelTransform: Codable {
    var size: Float
    var xCoord: Float
    var yCoord: Float
}

struct ButtonModel: Codable {
    var keyCode: Int
    var transform: KeyModelTransform
}

struct JoystickModel: Codable {
    var upKeyCode: Int
    var rightKeyCode: Int
    var downKeyCode: Int
    var leftKeyCode: Int
    var transform: KeyModelTransform
}

struct MouseAreaModel: Codable {
    var transform: KeyModelTransform
}

struct Keymap: Codable {
    var buttonModels: [ButtonModel] = []
    var joystickModel: [JoystickModel] = []
    var mouseAreaMode: [MouseAreaModel] = []
    var bundleIdentifier: String
    var version: Float = 2
    var version: String = "2.0.0"
}

class Keymapping {
    static var keymappingDir: URL {
        let keymappingFolder = PlayTools.playCoverContainer.appendingPathComponent("Keymapping")
        if !fileMgr.fileExists(atPath: keymappingFolder.path) {
            do {
                try fileMgr.createDirectory(at: keymappingFolder, withIntermediateDirectories: true, attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }
        return keymappingFolder
    }

    let info: AppInfo
    let keymapURL: URL
    var container: AppContainer?
    var keymap: Keymap {
        didSet {
            encode()
        }
    }

    init(_ info: AppInfo, container: AppContainer?) {
        self.info = info
        self.container = container
        self.keymapURL = Keymapping.keymappingDir.appendingPathComponent("\(info.bundleIdentifier).plist")
        self.keymap = Keymap(bundleIdentifier: info.bundleIdentifier)
        if !decode() {
            encode()
        }
    }

    public func reset() {
        keymap = Keymap(bundleIdentifier: info.bundleIdentifier)
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: keymapURL)
            keymap = try PropertyListDecoder().decode(Keymap.self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(keymap)
            try data.write(to: keymapURL)
            return true
        } catch {
            print(error)
            return false
        }
    }

    // TODO: Localise NSOpenPanel
    public func importKeymap(success: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playmap")]
        openPanel.title = "Import Keymapping"

        openPanel.begin { result in
            if result == .OK {
                do {
                    if let selectedPath = openPanel.url {
                        let data = try Data(contentsOf: selectedPath)
                        let importedKeymap = try PropertyListDecoder().decode(Keymap.self, from: data)
                        if importedKeymap.bundleIdentifier == self.keymap.bundleIdentifier {
                            self.keymap = importedKeymap
                            success(true)
                        } else {
                            Log.shared.error("Keymapping created for different app!")
                            success(false)
                        }
                    }
                } catch {
                    openPanel.close()
                    Log.shared.error(error)
                    success(false)
                }
                openPanel.close()
            }
        }
    }

    public func exportKeymap() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Keymapping"
        savePanel.nameFieldLabel = "PlayMap Name:"
        savePanel.nameFieldStringValue = self.info.displayName
        savePanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playmap")]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        savePanel.begin { result in
            if result == .OK {
                do {
                    if let selectedPath = savePanel.url {
                        let encoder = PropertyListEncoder()
                        encoder.outputFormat = .xml
                        let data = try encoder.encode(self.keymap)
                        try data.write(to: selectedPath)
                        selectedPath.openInFinder()
                    }
                } catch {
                    savePanel.close()
                    Log.shared.error(error)
                }
                savePanel.close()
            }
        }
    }
}
