//  BreathingView.swift
//  CalmieApp

import SwiftUI

// MARK: - Model

struct BreathPhaseStep {
    let label: String
    let duration: Double
    let expanding: Bool   // true = koło rośnie, false = maleje
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
        name: "Box",
        subtitle: "4 · 4 · 4 · 4",
        description: "Równomierne fale oddechu — redukuje stres i wycisza układ nerwowy.",
        accentColor: Color(red: 0.255, green: 0.452, blue: 0.428),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 4, expanding: true),
            BreathPhaseStep(label: "Hold",    duration: 4, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 4, expanding: false),
            BreathPhaseStep(label: "Hold",    duration: 4, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "4-7-8",
        subtitle: "4 · 7 · 8",
        description: "Technika Dr. Weila — uspokaja przed snem i przy stanach lękowych.",
        accentColor: Color(red: 0.25, green: 0.35, blue: 0.60),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 4, expanding: true),
            BreathPhaseStep(label: "Hold",    duration: 7, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 8, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "Coherent",
        subtitle: "5 · 5",
        description: "Spójny oddech — synchronizuje rytm serca i oddech, ideał na co dzień.",
        accentColor: Color(red: 0.55, green: 0.35, blue: 0.20),
        phases: [
            BreathPhaseStep(label: "Inhale",  duration: 5, expanding: true),
            BreathPhaseStep(label: "Exhale",  duration: 5, expanding: false),
        ]
    ),
    BreathingTechnique(
        name: "Triangle",
        subtitle: "4 · 4 · 4",
        description: "Trójkąt oddechu — zwiększa koncentrację i klarowność umysłu.",
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
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIndex = 0
    @State private var isRunning = false
    @State private var phaseIndex = 0
    @State private var countdown: Int = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var activeTimer: Timer?
    @State private var cycleCount = 0

    private var technique: BreathingTechnique { techniques[selectedIndex] }
    private var currentPhase: BreathPhaseStep { technique.phases[phaseIndex] }

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

                // MARK: Header
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

                // MARK: Technique picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(techniques.indices, id: \.self) { idx in
                            Button(action: {
                                guard !isRunning else { return }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIndex = idx
                                    circleScale = 0.5
                                    cycleCount = 0
                                }
                            }) {
                                VStack(spacing: 3) {
                                    Text(techniques[idx].name)
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(techniques[idx].subtitle)
                                        .font(.system(size: 11))
                                        .opacity(0.75)
                                }
                                .foregroundColor(selectedIndex == idx ? .white : .white.opacity(0.45))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    selectedIndex == idx
                                        ? technique.accentColor
                                        : Color.white.opacity(0.08)
                                )
                                .cornerRadius(14)
                            }
                            .disabled(isRunning)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 18)

                // MARK: Description
                Text(technique.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 14)
                    .padding(.bottom, 28)

                Spacer()

                // MARK: Animated circle
                ZStack {
                    Circle()
                        .fill(technique.accentColor.opacity(0.25))
                        .frame(width: 240, height: 240)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: currentPhase.duration), value: circleScale)

                    Circle()
                        .fill(technique.accentColor)
                        .frame(width: 180, height: 180)
                        .scaleEffect(circleScale)
                        .animation(.easeInOut(duration: currentPhase.duration), value: circleScale)

                    VStack(spacing: 6) {
                        Text(isRunning ? currentPhase.label : "Ready")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        if isRunning {
                            Text("\(countdown)")
                                .font(.system(size: 36, weight: .light))
                                .foregroundColor(.white.opacity(0.85))
                                .contentTransition(.numericText())
                                .animation(.default, value: countdown)
                        }
                    }
                }

                Spacer()

                // MARK: Cycle counter
                if cycleCount > 0 {
                    Text(cycleCount == 1 ? "1 cycle" : "\(cycleCount) cycles")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 12)
                }

                // MARK: Start / Stop
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
                                : technique.accentColor
                        )
                        .cornerRadius(26)
                }
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Logic

    private func startBreathing() {
        isRunning = true
        phaseIndex = 0
        cycleCount = 0
        applyPhase()
    }

    private func applyPhase() {
        let step = currentPhase
        countdown = Int(step.duration)
        circleScale = step.expanding ? 1.0 : 0.5
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
        isRunning = false
        activeTimer?.invalidate()
        activeTimer = nil
        phaseIndex = 0
        cycleCount = 0
        withAnimation(.easeInOut(duration: 0.4)) {
            circleScale = 0.5
        }
    }
}
