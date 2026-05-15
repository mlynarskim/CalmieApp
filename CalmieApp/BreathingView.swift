//  BreathingView.swift
//  CalmieApp

import SwiftUI

// MARK: - Model

struct BreathPhaseStep {
    let label: String
    let duration: Double
    let expanding: Bool
}

struct BreathingTechnique: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let description: String
    let accentColor: Color
    let phases: [BreathPhaseStep]
}

private let techniques: [BreathingTechnique] = [
    BreathingTechnique(
        name: "Box", subtitle: "4 · 4 · 4 · 4",
        description: "Equal waves of breath — reduces stress and calms the nervous system.",
        accentColor: Color(red: 0.255, green: 0.452, blue: 0.428),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 4, expanding: true),
            BreathPhaseStep(label: "Hold",    duration: 4, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 4, expanding: false),
            BreathPhaseStep(label: "Hold",    duration: 4, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "4-7-8", subtitle: "4 · 7 · 8",
        description: "Dr. Weil's technique — calms anxiety and helps you fall asleep faster.",
        accentColor: Color(red: 0.25, green: 0.35, blue: 0.60),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 4, expanding: true),
            BreathPhaseStep(label: "Hold",    duration: 7, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 8, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "Coherent", subtitle: "5 · 5",
        description: "Syncs your heart rate and breath — great for everyday use and balance.",
        accentColor: Color(red: 0.55, green: 0.35, blue: 0.20),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 5, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 5, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "Triangle", subtitle: "4 · 4 · 4",
        description: "Triangle breath — boosts focus and brings mental clarity.",
        accentColor: Color(red: 0.50, green: 0.25, blue: 0.45),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 4, expanding: true),
            BreathPhaseStep(label: "Hold",    duration: 4, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 4, expanding: false),
        ]
    ),
]

// MARK: - View

struct BreathingView: View {
    @Environment(\.dismiss)             private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.verticalSizeClass)   private var vSizeClass

    @AppStorage("breathingSessionCount") private var breathingSessionCount = 0
    @AppStorage("breathingTotalCycles")  private var breathingTotalCycles  = 0

    @State private var selectedIndex  = 0
    @State private var isRunning      = false
    @State private var phaseIndex     = 0
    @State private var countdown: Int = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var activeTimer: Timer?
    @State private var cycleCount     = 0

    private var technique:    BreathingTechnique { techniques[selectedIndex] }
    private var currentPhase: BreathPhaseStep    { technique.phases[phaseIndex] }

    // Adaptive sizing
    private var isPad: Bool         { hSizeClass == .regular }
    private var isLandscape: Bool   { vSizeClass == .compact }
    private var outerCircle: CGFloat { isPad ? 340 : 240 }
    private var innerCircle: CGFloat { isPad ? 260 : 180 }
    private var phaseFontSize: CGFloat   { isPad ? 32 : 24 }
    private var countFontSize: CGFloat   { isPad ? 52 : 36 }
    private var descFontSize: CGFloat    { isPad ? 16 : 13 }
    private var techNameSize: CGFloat    { isPad ? 17 : 14 }
    private var techSubSize: CGFloat     { isPad ? 13 : 11 }
    private var btnWidth: CGFloat        { isPad ? 200 : 140 }
    private var btnHeight: CGFloat       { isPad ? 64  : 52  }
    private var btnFontSize: CGFloat     { isPad ? 24  : 20  }
    private var headerFontSize: CGFloat  { isPad ? 26  : 20  }
    private var hPadding: CGFloat        { isPad ? 40  : 20  }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 65/255,  green: 55/255,  blue: 86/255),
                    Color(red: 185/255, green: 106/255, blue: 102/255)
                ]),
                startPoint: .top, endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            if isPad && !isLandscape {
                // iPad portrait — more breathing room, wider content
                padPortraitLayout
            } else if isPad && isLandscape {
                // iPad landscape — circle left, controls right
                padLandscapeLayout
            } else {
                // iPhone
                phoneLayout
            }
        }
    }

    // MARK: - Layouts

    private var phoneLayout: some View {
        VStack(spacing: 0) {
            header
            techniqueScroll
            descriptionText
            Spacer()
            breathCircle
            Spacer()
            cycleLabel
            startStopButton.padding(.bottom, 50)
        }
    }

    private var padPortraitLayout: some View {
        VStack(spacing: 0) {
            header
            techniqueScroll
            descriptionText.padding(.bottom, 8)
            Spacer()
            breathCircle
            Spacer()
            cycleLabel
            startStopButton.padding(.bottom, 60)
        }
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
    }

    private var padLandscapeLayout: some View {
        HStack(spacing: 0) {
            // Lewa — circle
            VStack {
                Spacer()
                breathCircle
                cycleLabel
                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Prawa — kontrolki
            VStack(spacing: 0) {
                header
                techniqueScroll
                descriptionText
                Spacer()
                startStopButton.padding(.bottom, 50)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Button(action: { stopBreathing(); dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: isPad ? 22 : 18, weight: .bold))
            }
            Spacer()
            Text("Breathing")
                .foregroundColor(.white)
                .font(.system(size: headerFontSize, weight: .bold))
            Spacer()
            Color.clear.frame(width: isPad ? 22 : 18, height: isPad ? 22 : 18)
        }
        .padding(.horizontal, hPadding)
        .padding(.top, isPad ? 28 : 20)
    }

    private var techniqueScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isPad ? 14 : 10) {
                ForEach(techniques.indices, id: \.self) { idx in
                    Button(action: {
                        guard !isRunning else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = idx
                            circleScale = 0.5
                            cycleCount = 0
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(techniques[idx].name)
                                .font(.system(size: techNameSize, weight: .semibold))
                            Text(techniques[idx].subtitle)
                                .font(.system(size: techSubSize))
                                .opacity(0.75)
                        }
                        .foregroundColor(selectedIndex == idx ? .white : .white.opacity(0.45))
                        .padding(.horizontal, isPad ? 20 : 14)
                        .padding(.vertical, isPad ? 14 : 10)
                        .background(
                            selectedIndex == idx
                                ? technique.accentColor
                                : Color.white.opacity(0.08)
                        )
                        .cornerRadius(isPad ? 18 : 14)
                    }
                    .disabled(isRunning)
                }
            }
            .padding(.horizontal, hPadding)
        }
        .padding(.top, isPad ? 24 : 18)
    }

    private var descriptionText: some View {
        Text(technique.description)
            .font(.system(size: descFontSize))
            .foregroundColor(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, hPadding + 12)
            .padding(.top, isPad ? 18 : 14)
            .padding(.bottom, isPad ? 32 : 28)
    }

    private var breathCircle: some View {
        ZStack {
            Circle()
                .fill(technique.accentColor.opacity(0.25))
                .frame(width: outerCircle, height: outerCircle)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: currentPhase.duration), value: circleScale)

            Circle()
                .fill(technique.accentColor)
                .frame(width: innerCircle, height: innerCircle)
                .scaleEffect(circleScale)
                .animation(.easeInOut(duration: currentPhase.duration), value: circleScale)

            VStack(spacing: isPad ? 10 : 6) {
                Text(isRunning ? currentPhase.label : "Ready")
                    .font(.system(size: phaseFontSize, weight: .bold))
                    .foregroundColor(.white)
                if isRunning {
                    Text("\(countdown)")
                        .font(.system(size: countFontSize, weight: .light))
                        .foregroundColor(.white.opacity(0.85))
                        .contentTransition(.numericText())
                        .animation(.default, value: countdown)
                }
            }
        }
    }

    private var cycleLabel: some View {
        Group {
            if cycleCount > 0 {
                Text(cycleCount == 1 ? "1 cycle" : "\(cycleCount) cycles")
                    .font(.system(size: isPad ? 17 : 14))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            } else {
                Color.clear.frame(height: isPad ? 17 : 14)
            }
        }
    }

    private var startStopButton: some View {
        Button(action: { if isRunning { stopBreathing() } else { startBreathing() } }) {
            Text(isRunning ? "Stop" : "Start")
                .font(.system(size: btnFontSize, weight: .bold))
                .foregroundColor(.white)
                .frame(width: btnWidth, height: btnHeight)
                .background(isRunning ? Color.white.opacity(0.15) : technique.accentColor)
                .cornerRadius(btnHeight / 2)
        }
    }

    // MARK: - Logic

    private func startBreathing() {
        isRunning = true; phaseIndex = 0; cycleCount = 0
        applyPhase()
    }

    private func applyPhase() {
        countdown = Int(currentPhase.duration)
        circleScale = currentPhase.expanding ? 1.0 : 0.5
        runTick()
    }

    private func runTick() {
        activeTimer?.invalidate()
        var remaining = Int(currentPhase.duration)
        countdown = remaining
        activeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            remaining -= 1
            countdown = remaining
            guard remaining <= 0 else { return }
            timer.invalidate()
            let nextIndex = (phaseIndex + 1) % technique.phases.count
            if nextIndex == 0 { cycleCount += 1 }
            phaseIndex = nextIndex
            applyPhase()
        }
    }

    private func stopBreathing() {
        if cycleCount > 0 {
            breathingSessionCount += 1
            breathingTotalCycles  += cycleCount
        }
        isRunning = false
        activeTimer?.invalidate()
        activeTimer = nil
        phaseIndex = 0; cycleCount = 0
        withAnimation(.easeInOut(duration: 0.4)) { circleScale = 0.5 }
    }
}
