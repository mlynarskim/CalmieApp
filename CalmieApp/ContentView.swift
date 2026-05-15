//  ContentView.swift
//  Calmie

import AVFoundation
import SwiftUI
import CoreData
import UserNotifications
import UIKit
import CoreHaptics
import AudioToolbox

struct HoldButton: View {
    let systemImage: String
    let action: () -> Void
    let size: CGFloat
    @State private var repeatTimer: Timer?

    init(systemImage: String, size: CGFloat = 20, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    var body: some View {
        Image(systemName: systemImage)
            .foregroundColor(.white)
            .font(.system(size: size, weight: .bold))
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 60) {
            } onPressingChanged: { isPressing in
                if isPressing {
                    action()
                    repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                        self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
                            DispatchQueue.main.async { action() }
                        }
                    }
                } else {
                    repeatTimer?.invalidate()
                    repeatTimer = nil
                }
            }
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase)          private var scenePhase
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass)   private var vSizeClass

    @AppStorage("onboardingDone") private var onboardingDone = false

    @State private var isCountingDown   = false
    @State private var isPaused         = false
    @State private var progress: CGFloat = 0.0
    @State private var isButtonBlocked  = false
    @State private var currentIndex     = 0
    @State private var selectedTime     = 1
    @State private var ripple           = false
    @State private var sound: AVAudioPlayer?
    @State private var showStats        = false
    @State private var showBreathing    = false
    @State private var showReminder     = false
    @State private var activeTimer: Timer?
    @State private var sessionEndDate: Date?
    @State private var pausedRemaining: TimeInterval = 0
    @State private var hapticEngine: CHHapticEngine?
    @State private var bellEngine:   AVAudioEngine?
    @State private var bellNode:     AVAudioPlayerNode?

    // MARK: Adaptive sizing
    private var isPad: Bool      { hSizeClass == .regular }
    private var isLandscape: Bool { vSizeClass == .compact }

    private var buttonDiameter: CGFloat   { isPad ? 300 : 200 }
    private var buttonFontSize: CGFloat   { isPad ? 36  : 28  }
    private var ringLineWidth: CGFloat    { isPad ? 14  : 10  }
    private var topBarFontSize: CGFloat   { isPad ? 26  : 20  }
    private var topBarIconSize: CGFloat   { isPad ? 26  : 20  }
    private var controlFontSize: CGFloat  { isPad ? 20  : 16  }
    private var controlHeight: CGFloat    { isPad ? 56  : 44  }
    private var timeFontSize: CGFloat     { isPad ? 28  : 20  }
    private var quickButtonW: CGFloat     { isPad ? 130 : 90  }
    private var quickButtonH: CGFloat     { isPad ? 100 : 70  }
    private var quickIconSize: CGFloat    { isPad ? 30  : 22  }
    private var quickFontSize: CGFloat    { isPad ? 16  : 12  }
    private var bottomPadding: CGFloat    { isPad ? 70  : 50  }
    private var hPadding: CGFloat         { isPad ? 40  : 20  }

    private var countdownDuration: TimeInterval { TimeInterval(selectedTime * 60) }

    private let listWords: [String] = [
        "Calm down", "Relax", "Breathe", "Focus", "Find balance",
        "Feel safe", "Be happy", "Concentrate", "Smile", "Feel strength",
        "Rest", "Meditate", "Tranquility", "Harmony", "Peace",
        "Unwind", "Bliss", "Calmness", "Breath", "Stillness",
        "Zen", "Soothe", "Refresh", "Inner peace", "Quietude",
        "Gentle", "Ease", "Mindfulness", "Chill", "Serenity"
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                gradient.edgesIgnoringSafeArea(.all)

                if isPad && geo.size.width > geo.size.height {
                    // iPad landscape — split layout
                    HStack(spacing: 0) {
                        timerCircle
                            .frame(maxWidth: .infinity)
                        Divider()
                            .background(Color.white.opacity(0.15))
                        controlsPanel
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // iPhone + iPad portrait
                    timerCircle
                }
            }
            // Top bar
            .overlay(alignment: .top) {
                HStack {
                    Button(action: { showStats = true }) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: topBarIconSize, weight: .bold))
                    }
                    Spacer()
                    Button(action: { toggleSound() }) {
                        Image(systemName: sound?.isPlaying ?? false ? "speaker.slash" : "speaker")
                            .foregroundColor(.gray)
                            .font(.system(size: topBarIconSize, weight: .bold))
                    }
                }
                .padding(.horizontal, hPadding)
                .padding(.top, isPad ? 28 : 20)
            }
            // Bottom controls — only in portrait / iPhone
            .overlay(alignment: .bottom) {
                if !(isPad && geo.size.width > geo.size.height) {
                    controlsPanel
                        .padding(.bottom, bottomPadding)
                }
            }
        }
        .sheet(isPresented: $showBreathing) { BreathingView() }
        .sheet(isPresented: $showReminder)  { ReminderView() }
        .sheet(isPresented: $showStats) {
            StatsView().environment(\.managedObjectContext, viewContext)
        }
        .overlay {
            if !onboardingDone {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(100)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingDone)
        .onAppear { prepareHaptics(); prepareBellEngine() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if isCountingDown && !isPaused { runTimer() }
            } else if phase == .background {
                activeTimer?.invalidate()
            }
        }
    }

    // MARK: - Subviews

    private var gradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 65/255,  green: 55/255,  blue: 86/255),
                Color(red: 185/255, green: 106/255, blue: 102/255)
            ]),
            startPoint: .top, endPoint: .bottom
        )
    }

    private var timerCircle: some View {
        ZStack {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .stroke(lineWidth: 4)
                    .frame(width: buttonDiameter, height: buttonDiameter)
                    .scaleEffect(ripple ? 2.5 : 0.001)
                    .opacity(ripple ? 0 : 0.15)
                    .animation(
                        .easeInOut(duration: 7)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.4),
                        value: ripple
                    )
            }
            Button(action: {
                guard !isButtonBlocked else { return }
                isButtonBlocked = true
                ripple = true
                playSound()
                startCountdown()
            }) {
                if isCountingDown {
                    Text(listWords[currentIndex])
                        .font(.system(size: buttonFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonDiameter, height: buttonDiameter)
                        .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .trim(from: 0.0, to: progress)
                                .stroke(style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                                .foregroundColor(Color.green)
                                .rotationEffect(.degrees(-90))
                        )
                        .animation(.easeInOut(duration: 2), value: progress)
                } else {
                    Text("START")
                        .font(.system(size: buttonFontSize, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: buttonDiameter, height: buttonDiameter)
                        .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                        .clipShape(Circle())
                }
            }
            .disabled(isButtonBlocked)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        }
    }

    private var controlsPanel: some View {
        VStack(spacing: isPad ? 28 : 20) {
            if isCountingDown {
                HStack(spacing: isPad ? 40 : 28) {
                    Button(action: { isPaused ? resumeCountdown() : pauseCountdown() }) {
                        HStack(spacing: 8) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            Text(isPaused ? "Resume" : "Pause")
                        }
                        .font(.system(size: controlFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: isPad ? 160 : 120, height: controlHeight)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(controlHeight / 2)
                    }
                    Button(action: { stopCountdown() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.system(size: controlFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: isPad ? 130 : 100, height: controlHeight)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(controlHeight / 2)
                    }
                }
            } else {
                HStack(spacing: isPad ? 24 : 16) {
                    HoldButton(systemImage: "minus", size: isPad ? 26 : 20) {
                        if selectedTime > 1 { selectedTime -= 1 }
                    }
                    Text(String(format: "%02d:%02d", selectedTime, 0))
                        .foregroundColor(.white)
                        .font(.system(size: timeFontSize, weight: .bold))
                        .frame(minWidth: isPad ? 100 : 70)
                    HoldButton(systemImage: "plus", size: isPad ? 26 : 20) {
                        if selectedTime < 60 { selectedTime += 1 }
                    }
                }
                .padding(isPad ? 20 : 15)
                .background(Color.gray.opacity(0.6))
                .cornerRadius(isPad ? 20 : 15)

                HStack(spacing: isPad ? 32 : 24) {
                    quickButton(
                        icon: "wind",
                        label: "Breathe",
                        action: { showBreathing = true }
                    )
                    quickButton(
                        icon: "bell.fill",
                        label: "Reminder",
                        action: { showReminder = true }
                    )
                }
            }
        }
        .padding(.horizontal, hPadding)
    }

    private func quickButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: isPad ? 8 : 6) {
                Image(systemName: icon)
                    .font(.system(size: quickIconSize, weight: .medium))
                Text(label)
                    .font(.system(size: quickFontSize, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            .frame(width: quickButtonW, height: quickButtonH)
            .background(Color.white.opacity(0.12))
            .cornerRadius(isPad ? 20 : 16)
        }
    }

    // MARK: - Timer

    private func startCountdown() {
        isCountingDown = true
        isPaused = false
        sessionEndDate = Date().addingTimeInterval(countdownDuration)
        scheduleEndNotification(after: countdownDuration)
        UIApplication.shared.isIdleTimerDisabled = true
        runTimer()
    }

    private func runTimer() {
        activeTimer?.invalidate()
        activeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            guard let endDate = sessionEndDate else { timer.invalidate(); return }
            let remaining = endDate.timeIntervalSinceNow
            guard remaining > 0 else {
                timer.invalidate()
                saveSession(duration: selectedTime)
                playEndSignal()
                // Krótkie opóźnienie — daj sygnałowi wybrzmieć przed resetem UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    resetCountdown()
                }
                return
            }
            progress = CGFloat(remaining / countdownDuration)
            let wordIndex = Int((countdownDuration - remaining) / 5)
            if wordIndex != currentIndex { currentIndex = wordIndex % listWords.count }
        }
    }

    private func pauseCountdown() {
        isPaused = true
        activeTimer?.invalidate()
        pausedRemaining = sessionEndDate?.timeIntervalSinceNow ?? 0
        sessionEndDate = nil
        sound?.pause()
        cancelEndNotification()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func resumeCountdown() {
        isPaused = false
        sessionEndDate = Date().addingTimeInterval(pausedRemaining)
        scheduleEndNotification(after: pausedRemaining)
        sound?.play()
        UIApplication.shared.isIdleTimerDisabled = true
        runTimer()
    }

    private func stopCountdown() {
        activeTimer?.invalidate()
        cancelEndNotification()
        resetCountdown()
    }

    private func resetCountdown() {
        isCountingDown = false
        isPaused = false
        isButtonBlocked = false
        progress = 0.0
        currentIndex = 0
        sessionEndDate = nil
        pausedRemaining = 0
        ripple = false
        sound?.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - Notifications

    private func scheduleEndNotification(after interval: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["session_end"])
        let content = UNMutableNotificationContent()
        content.title = "Session complete 🧘"
        content.body  = "Great job! Your meditation session is done."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        center.add(UNNotificationRequest(identifier: "session_end", content: content, trigger: trigger))
    }

    private func cancelEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["session_end"])
    }

    // MARK: - End signal (dzwon medytacyjny)

    /// Trzy malejące uderzenia dzwonu — haptyka + dźwięk
    private func playEndSignal() {
        playBellSound()
        playEndHaptics()
    }

    // MARK: - Bell engine

    private func prepareBellEngine() {
        // Mix with any playing background music — don't interrupt it
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default,
                                                         options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        let engine = AVAudioEngine()
        let node   = AVAudioPlayerNode()
        engine.attach(node)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(node, to: engine.mainMixerNode, format: format)
        try? engine.start()
        bellEngine = engine
        bellNode   = node
    }

    /// Three synthesized bell strikes with exponential decay — plays over any music.
    private func playBellSound() {
        let strikes: [Double] = [0.0, 0.75, 1.4]
        for delay in strikes {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.strikeBell()
            }
        }
    }

    /// Single bell strike: 528 Hz sine wave with natural exponential decay (~1.5 s).
    private func strikeBell() {
        guard let node = bellNode, let engine = bellEngine, engine.isRunning else { return }

        let sampleRate = 44100.0
        let duration   = 1.5           // seconds — long decay like a real bowl
        let frequency  = 528.0         // Hz — "love frequency", warm and calming
        let frames     = Int(sampleRate * duration)

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(frames)) else { return }
        buffer.frameLength = AVAudioFrameCount(frames)

        let data = buffer.floatChannelData![0]
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            // Fast attack (8 ms), long exponential decay
            let attack  = min(1.0, t / 0.008)
            let decay   = exp(-t * 3.2)          // decay rate — adjust for longer/shorter ring
            let envelope = attack * decay
            data[i] = Float(sin(2.0 * .pi * frequency * t) * 0.75 * envelope)
        }

        node.scheduleBuffer(buffer)
        if !node.isPlaying { node.play() }
    }

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
        hapticEngine?.resetHandler = { [self] in try? self.hapticEngine?.start() }
    }

    private func playEndHaptics() {
        guard let engine = hapticEngine,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Prosty fallback — trzy tapnięcia
            let gen = UINotificationFeedbackGenerator()
            gen.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { gen.notificationOccurred(.success) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { gen.notificationOccurred(.success) }
            return
        }
        do {
            // Trzy impulsy: mocny (dzwon), średni (echo), cichy (wybrzmiewa)
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                    ],
                    relativeTime: 0.7
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                    ],
                    relativeTime: 1.3
                ),
            ]
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player  = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Audio

    private func saveSession(duration: Int) {
        let session = MeditationSession(context: viewContext)
        session.date     = Date()
        session.duration = Int32(duration)
        try? viewContext.save()
    }

    private func toggleSound() {
        if sound?.isPlaying == true { sound?.pause() } else { sound?.play() }
    }

    private func playSound() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        guard let url = Bundle.main.url(forResource: "Yoga Style - Chris Haugen", withExtension: "mp3") else { return }
        sound = try? AVAudioPlayer(contentsOf: url)
        sound?.numberOfLoops = -1
        sound?.play()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
