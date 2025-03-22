import SwiftUI
import AVFoundation
import UIKit

struct CountdownView: View {
    let initialSeconds: Int
    @State private var remainingSeconds: Int
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var soundPlayer: AVAudioPlayer?
    @State private var impactFeedback: UIImpactFeedbackGenerator?
    @Environment(\.presentationMode) var presentationMode
    
    init(seconds: Int) {
        self.initialSeconds = seconds
        _remainingSeconds = State(initialValue: seconds)
        print("CountdownView initialized with \(seconds) seconds")
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        stopTimer()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                            .padding()
                    }
                    Spacer()
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 15)
                        .frame(width: 300, height: 300)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(remainingSeconds) / CGFloat(initialSeconds))
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text(timeString(remainingSeconds))
                            .font(.system(size: 80, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 50)
                
                VStack(spacing: 10) {
                    Button(action: {
                        if isRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isRunning ? Color.orange : Color.green)
                                .frame(width: 128, height: 128)
                            
                            Image(systemName: "camera.shutter.button")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 96, height: 96)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Text(isRunning ? NSLocalizedString("Pause", comment: "Pause button text") : NSLocalizedString("Start", comment: "Start button text"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
        }
        .onAppear(perform: setup)
        .onDisappear(perform: cleanUp)
    }
    
    func setup() {
        setupAudio()
        setupHaptics()
    }
    
    func startTimer() {
        print("Starting timer")
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                print("Countdown: \(remainingSeconds) seconds remaining")
                
                if remainingSeconds == 11 {
                    print("11 seconds remaining, attempting to play sound")
                    playSound()
                }
            } else {
                print("Countdown finished")
                stopTimer()
                generateHapticFeedback()
            }
        }
    }
    
    func pauseTimer() {
        print("Pausing timer")
        isRunning = false
        timer?.invalidate()
        soundPlayer?.pause()
    }
    
    func stopTimer() {
        print("Stopping timer")
        isRunning = false
        timer?.invalidate()
        timer = nil
        soundPlayer?.stop()
    }
    
    func timeString(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: NSLocalizedString("%02d:%02d", comment: "Time format"), minutes, remainingSeconds)
    }
    
    func setupAudio() {
        print("Setting up audio")
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session set up successfully")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
        
        guard let soundURL = Bundle.main.url(forResource: "countdown_finish", withExtension: "mp3") else {
            print("Sound file not found")
            return
        }
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundPlayer?.prepareToPlay()
            print("Audio player set up successfully")
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    func setupHaptics() {
        impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback?.prepare()
    }
    
    func playSound() {
        guard let player = soundPlayer else {
            print("Sound player not available")
            return
        }
        
        if player.isPlaying {
            player.stop()
            player.currentTime = 0
        }
        
        print("Attempting to play sound")
        if player.play() {
            print("Sound started playing successfully")
        } else {
            print("Failed to start playing sound")
        }
    }
    
    func generateHapticFeedback() {
        print("Generating haptic feedback")
        impactFeedback?.impactOccurred()
        // Optionally, you can create a sequence of haptic feedbacks for a more noticeable effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            impactFeedback?.impactOccurred()
        }
    }
    
    func cleanUp() {
        print("Cleaning up")
        stopTimer()
        soundPlayer?.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
            print("Audio session deactivated")
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        impactFeedback = nil
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(seconds: 120)
    }
}
