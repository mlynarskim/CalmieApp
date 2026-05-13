//  BreathingView.swift
//  CalmieApp

import SwiftUI

private enum BreathPhase {
    case inhale, holdIn, exhale, holdOut

    var label: String {
        switch self {
        case .inhale:  return "Inhale"
        case .holdIn:  return "Hold"
        case .exhale:  return "Exhale"
        case .holdOut: return "Hold"
        }
    }

    var duration: Double {
        switch self {
        case .inhale:  return 4
        case .holdIn:  return 4
        case .exhale:  return 4
        case .holdOut: return 4
        }
    }

    var next: BreathPhase {
        switch self {
        case .inhale:  return .holdIn
        case .holdIn:  return .exhale
        case .exhale:  return .holdOut
        case .holdOut: return .inhale
        }
    }

    var circleScale: CGFloat {
        switch self {
        case .inhale:  return 1.0
        case .holdIn:  return 1.0
        case .exhale:  return 0.5
        case .holdOut: return 0.5
        }
    }
}

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRunning = false
    @State private var phase: BreathPhase = .inhale
    @State private var countdown: Int = 4
    @State private var circleScale: CGFloat = 0.5
    @State private var activeTimer: Timer?
    @State private var cycleCount = 0

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

            VStack(spacing: 0) {
                // Nagłówek
                HStack {
                    Button(action: {
                        stopBreathing()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Spacer()
                    Text("Breathing")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Color.clear.frame(width: 18, height: 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                // Opis techniki
                Text("Box Breathing  ·  4–4–4–4")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)

                // Animowany okrąg
                ZStack {
                    Circle()
                        .fill(Color(red: 0.255, green: 0.452, blue: 0.428).opacity(0.3))
                        .frame(width: 240, height: 240)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: phase.duration), value: circleScale)

                    Circle()
                        .fill(Color(red: 0.255, green: 0.452, blue: 0.428))
                        .frame(width: 180, height: 180)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: phase.duration), value: circleScale)

                    VStack(spacing: 6) {
                        Text(isRunning ? phase.label : "Ready")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        if isRunning {
                            Text("\(countdown)")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                }

                Spacer()

                // Licznik cykli
                if cycleCount > 0 {
                    Text(cycleCount == 1 ? "1 cycle" : "\(cycleCount) cycles")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 12)
                }

                // Przycisk start/stop
                Button(action: {
                    if isRunning { stopBreathing() } else { startBreathing() }
                }) {
                    Text(isRunning ? "Stop" : "Start")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 140, height: 52)
                        .background(
                            isRunning
                                ? Color.white.opacity(0.15)
                                : Color(red: 0.255, green: 0.452, blue: 0.428)
                        )
                        .cornerRadius(26)
                }
                .padding(.bottom, 50)
            }
        }
    }

    private func startBreathing() {
        isRunning = true
        phase = .inhale
        countdown = Int(BreathPhase.inhale.duration)
        circleScale = 1.0
        runTick()
    }

    private func stopBreathing() {
        isRunning = false
        activeTimer?.invalidate()
        activeTimer = nil
        circleScale = 0.5
        countdown = 4
        cycleCount = 0
    }

    private func runTick() {
        activeTimer?.invalidate()
        var remaining = Int(phase.duration)
        countdown = remaining

        activeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            remaining -= 1
            countdown = remaining
            if remaining <= 0 {
                timer.invalidate()
                let next = phase.next
                if next == .inhale { cycleCount += 1 }
                phase = next
                circleScale = next.circleScale
                runTick()
            }
        }
    }
}
