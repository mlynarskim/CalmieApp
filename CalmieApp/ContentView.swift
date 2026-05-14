//  ContentView.swift
//  Calmie

import AVFoundation
import SwiftUI
import CoreData
import UserNotifications

struct HoldButton: View {
    let systemImage: String
    let action: () -> Void
    @State private var repeatTimer: Timer?

    var body: some View {
        Image(systemName: systemImage)
            .foregroundColor(.white)
            .font(.system(size: 20, weight: .bold))
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
    @Environment(\.scenePhase) private var scenePhase

    @State private var isCountingDown = false
    @State private var isPaused = false
    @State private var progress: CGFloat = 0.0
    @State private var isButtonBlocked = false
    @State private var currentIndex = 0
    @State private var selectedTime = 1
    @State private var ripple = false
    @State private var sound: AVAudioPlayer?
    @State private var showStats = false
    @State private var showBreathing = false
    @State private var showReminder = false
    @State private var activeTimer: Timer?

    // Przechowujemy datę końca sesji — timer liczy od zegara, nie od tików
    @State private var sessionEndDate: Date?
    // Używane przy pauzie — ile czasu pozostało
    @State private var pausedRemaining: TimeInterval = 0

    private var countdownDuration: TimeInterval {
        TimeInterval(selectedTime * 60)
    }

    private let listWords: [String] = [
        "Calm down", "Relax", "Breathe", "Focus", "Find balance",
        "Feel safe", "Be happy", "Concentrate", "Smile", "Feel strength",
        "Rest", "Meditate", "Tranquility", "Harmony", "Peace",
        "Unwind", "Bliss", "Calmness", "Breath", "Stillness",
        "Zen", "Soothe", "Refresh", "Inner peace", "Quietude",
        "Gentle", "Ease", "Mindfulness", "Chill", "Serenity"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 65/255, green: 55/255, blue: 86/255),
                    Color(red: 185/255, green: 106/255, blue: 102/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            // Ripple + przycisk na środku ekranu
            ZStack {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .stroke(lineWidth: 4)
                        .frame(width: 200, height: 200)
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
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .trim(from: 0.0, to: progress)
                                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                    .foregroundColor(Color.green)
                                    .rotationEffect(.degrees(-90))
                            )
                            .animation(.easeInOut(duration: 2), value: progress)
                    } else {
                        Text("START")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 200)
                            .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                            .clipShape(Circle())
                    }
                }
                .disabled(isButtonBlocked)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
        }
        // Top bar
        .overlay(alignment: .top) {
            HStack {
                Button(action: { showStats = true }) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .bold))
                }
                Spacer()
                Button(action: { toggleSound() }) {
                    Image(systemName: sound?.isPlaying ?? false ? "speaker.slash" : "speaker")
                        .foregroundColor(.gray)
                        .font(.system(size: 20, weight: .bold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        // Dolne kontrolki
        .overlay(alignment: .bottom) {
            VStack(spacing: 20) {
                if isCountingDown {
                    HStack(spacing: 28) {
                        Button(action: { isPaused ? resumeCountdown() : pauseCountdown() }) {
                            HStack(spacing: 8) {
                                Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                Text(isPaused ? "Resume" : "Pause")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(22)
                        }
                        Button(action: { stopCountdown() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 44)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(22)
                        }
                    }
                } else {
                    HStack {
                        HoldButton(systemImage: "minus") {
                            if selectedTime > 1 { selectedTime -= 1 }
                        }
                        Text(String(format: "%02d:%02d", selectedTime, 0))
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                        HoldButton(systemImage: "plus") {
                            if selectedTime < 60 { selectedTime += 1 }
                        }
                    }
                    .padding(15)
                    .background(Color.gray.opacity(0.6))
                    .cornerRadius(15)

                    HStack(spacing: 24) {
                        Button(action: { showBreathing = true }) {
                            VStack(spacing: 6) {
                                Image(systemName: "wind")
                                    .font(.system(size: 22, weight: .medium))
                                Text("Breathe")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 90, height: 70)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(16)
                        }
                        Button(action: { showReminder = true }) {
                            VStack(spacing: 6) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 22, weight: .medium))
                                Text("Reminder")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 90, height: 70)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(16)
                        }
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .sheet(isPresented: $showBreathing) { BreathingView() }
        .sheet(isPresented: $showReminder) { ReminderView() }
        .sheet(isPresented: $showStats) {
            StatsView()
                .environment(\.managedObjectContext, viewContext)
        }
        // Powrót z tła — synchronizuj timer z zegarem
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                if isCountingDown && !isPaused {
                    runTimer()
                }
            } else if phase == .background {
                // Zatrzymaj UI-timer — nie potrzebny w tle
                activeTimer?.invalidate()
            }
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
                resetCountdown()
                return
            }
            progress = CGFloat(remaining / countdownDuration)
            let elapsed = countdownDuration - remaining
            let wordIndex = Int(elapsed) / 5
            if wordIndex != currentIndex {
                currentIndex = wordIndex % listWords.count
            }
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
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - Notifications

    private func scheduleEndNotification(after interval: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["session_end"])
        let content = UNMutableNotificationContent()
        content.title = "Session complete 🧘"
        content.body = "Great job! Your meditation session is done."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(interval, 1), repeats: false)
        let request = UNNotificationRequest(identifier: "session_end", content: content, trigger: trigger)
        center.add(request)
    }

    private func cancelEndNotification() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["session_end"])
    }

    // MARK: - Audio

    private func saveSession(duration: Int) {
        let session = MeditationSession(context: viewContext)
        session.date = Date()
        session.duration = Int32(duration)
        try? viewContext.save()
    }

    private func toggleSound() {
        if sound?.isPlaying == true {
            sound?.pause()
        } else {
            sound?.play()
        }
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
