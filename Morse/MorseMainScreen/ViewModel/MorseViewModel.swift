//
//  MorseViewModel.swift
//  Morse
//
//  Created by Dmytro Ryshchuk on 11/26/24.
//

import Foundation
import AVFoundation

class MorseViewModel: ObservableObject {
    @Published var isRunning = false
    
    private let soundPlayer: MorseSoundPlayer
    private let morseModel: MorseModel
    
    init(soundPlayer: MorseSoundPlayer, morseModel: MorseModel) {
        self.soundPlayer = soundPlayer
        self.morseModel = morseModel
    }
    
    func playMorseCode(_ morseCode: String) {
        soundPlayer.playMorseCode(morseCode)
    }
    
    func textToMorseTransformation(from text: String, _ mode: Bool) -> String {
        var morseText = ""
        
        let cleanedText = normalizeInput(text)
        print(text, cleanedText)

        
        if mode {
            // Mode: text → morse
            morseText = cleanedText.uppercased().map { char in
                if char == " " {
                    return "/"
                } else {
                    return morseModel.getMorseSymbols()[String(char)] ?? "?"
                }
            }.joined(separator: " ")
        } else {
            // Mode: morse → text
            let morseComponents = cleanedText.split(separator: " ") // separate symbols by blank space
            print("m: ", morseComponents)
            for component in morseComponents {
                if component == "/" {
                    morseText += " " // add blank space between words
                } else {
                    morseText += morseModel.getInvertedMorseSymbols()[String(component)] ?? "?" // receive right character
                }
            }
        }
        
        return morseText
    }

    private func normalizeInput(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "…", with: "...") // replace 3 dots
            .replacingOccurrences(of: "-", with: "-")   // replace "-" to make "-"
            .replacingOccurrences(of: "—", with: "--")   // replace "–" to make "--"
            .replacingOccurrences(of: "—-", with: "---")   // replace "–-" to make "---"
            .replacingOccurrences(of: "——", with: "----")   // replace "––" to make "----"
            .replacingOccurrences(of: "——-", with: "-----")   // replace "––-" to make "-----"
    }
}

// MARK: - Work with light
extension MorseViewModel {
    func sendMorseCode(_ text: String) {
        isRunning = true
        let morseSequence = text.uppercased().compactMap { morseModel.getMorseSymbols()[String($0)] }.joined(separator: " ")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            for symbol in morseSequence {
                if !self.isRunning { break }
                switch symbol {
                case ".":
                    toggleFlashlight(on: true)
                    usleep(200_000) // Short signal (0.2 secunds)
                    toggleFlashlight(on: false)
                case "−":
                    toggleFlashlight(on: true)
                    usleep(600_000) // Long signal (0.6 secunds)
                    toggleFlashlight(on: false)
                case " ":
                    usleep(200_000) // Pause between symbols
                case "/":
                    usleep(600_000) // Pause between words
                default:
                    break
                }
                usleep(200_000) // Pause between dot and dash
            }
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
            }
        }
    }
    
    func stopMorseCode() {
        isRunning = false
        toggleFlashlight(on: false)
    }
    
    private func toggleFlashlight(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Could not change state of light: \(error))")
            }
        }
    }
}

/*
// MARK: - Work with light and sound
extension MorseViewModel {
    func sendMorseCodeWithLightAndSound(_ text: String) {
        isRunning = true
        let morseSequence = text.uppercased().compactMap { symbolsDict[String($0)] }.joined(separator: " ")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            for symbol in morseSequence {
                if !self.isRunning { break }
                let group = DispatchGroup()
                
                // Light
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.handleLight(symbol: symbol)
                    group.leave()
                }
                
                // Sound
                group.enter()
                DispatchQueue.global(qos: .userInitiated).async {
                    self.handleSound(symbol: symbol)
                    group.leave()
                }
                
                // Sync before next symbol
                group.wait()
                usleep(200_000) // Pause between signals
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
            }
        }
    }
    
    private func handleLight(symbol: Character) {
        switch symbol {
        case ".":
            toggleFlashlight(on: true)
            usleep(200_000) // Short signal (0.2 seconds)
            toggleFlashlight(on: false)
        case "-":
            toggleFlashlight(on: true)
            usleep(600_000) // Long signal (0.6 seconds)
            toggleFlashlight(on: false)
        case " ":
            usleep(200_000) // Pause between symbols
        case "/":
            usleep(600_000) // Pause between words
        default:
            break
        }
    }
    
    func handleSound(symbol: Character) {
        switch symbol {
        case ".":
            soundPlayer.playDot()
        case "−":
            soundPlayer.playDash()
        case " ":
            Thread.sleep(forTimeInterval: 0.2) // Pause between symbols
        case "/":
            Thread.sleep(forTimeInterval: 0.6) // Pause between symbols
        default:
            break
        }
    }
}
*/
