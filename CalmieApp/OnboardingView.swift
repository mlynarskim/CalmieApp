//  OnboardingView.swift
//  CalmieApp

import SwiftUI

// MARK: - Model

private struct OnboardingPage {
    let emoji: String
    let title: String
    let body: String
    let tip: String?           // highlighted tip box, optional
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        emoji: "🧘",
        title: "Welcome to Calmie",
        body: "A calm, distraction-free space to meditate and breathe. No accounts, no noise — just you and your practice.",
        tip: nil
    ),
    OnboardingPage(
        emoji: "🔔",
        title: "Close your eyes",
        body: "Set a timer and tap Start. When your session ends, a gentle bell and three soft haptic pulses will bring you back — no need to watch the screen.",
        tip: nil
    ),
    OnboardingPage(
        emoji: "🫁",
        title: "Feel every breath",
        body: "During breathing exercises, follow the expanding circle. On each count you'll feel a pulse in your hand.",
        tip: "Tip: rest your phone face-up on your knee — the haptic feedback becomes even more noticeable and guides each breath naturally."
    ),
]

// MARK: - View

struct OnboardingView: View {
    @AppStorage("onboardingDone")   private var onboardingDone = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    private var isPad: Bool { hSizeClass == .regular }
    private var cardWidth: CGFloat { isPad ? 480 : 320 }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.55)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture { } // absorbs taps, prevents dismissal by tapping outside

            // Card
            VStack(spacing: 0) {
                // Paged content
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(pages.indices, id: \.self) { i in
                            pageView(pages[i])
                                .frame(width: geo.size.width)
                        }
                    }
                    .offset(x: -CGFloat(currentPage) * geo.size.width + dragOffset)
                    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: currentPage)
                    .animation(.interactiveSpring(), value: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { v in dragOffset = v.translation.width }
                            .onEnded { v in
                                dragOffset = 0
                                let threshold = geo.size.width * 0.28
                                if v.translation.width < -threshold, currentPage < pages.count - 1 {
                                    currentPage += 1
                                } else if v.translation.width > threshold, currentPage > 0 {
                                    currentPage -= 1
                                }
                            }
                    )
                }
                .frame(height: isPad ? 320 : 290)
                .clipped()

                // Dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Capsule()
                            .fill(currentPage == i ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == i ? 18 : 7, height: 7)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, isPad ? 28 : 22)

                // Button
                Button(action: advance) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: isPad ? 20 : 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: isPad ? 56 : 50)
                        .background(Color(red: 0.255, green: 0.452, blue: 0.428))
                        .cornerRadius(isPad ? 28 : 25)
                }
                .padding(.horizontal, isPad ? 32 : 24)
                .padding(.bottom, isPad ? 32 : 26)
            }
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: isPad ? 32 : 26)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 72/255, green: 58/255, blue: 95/255),
                                Color(red: 110/255, green: 68/255, blue: 85/255)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.45), radius: 32, y: 10)
        }
    }

    // MARK: - Page

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            Text(page.emoji)
                .font(.system(size: isPad ? 72 : 58))
                .padding(.top, isPad ? 36 : 28)
                .padding(.bottom, isPad ? 14 : 10)

            Text(page.title)
                .font(.system(size: isPad ? 24 : 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, isPad ? 32 : 24)
                .padding(.bottom, isPad ? 12 : 8)

            Text(page.body)
                .font(.system(size: isPad ? 16 : 14))
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, isPad ? 32 : 24)
                .fixedSize(horizontal: false, vertical: true)

            if let tip = page.tip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: isPad ? 13 : 11))
                        .foregroundColor(.yellow.opacity(0.85))
                        .padding(.top, 1)
                    Text(tip)
                        .font(.system(size: isPad ? 13 : 11))
                        .foregroundColor(.white.opacity(0.65))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(isPad ? 14 : 11)
                .background(Color.white.opacity(0.09))
                .cornerRadius(12)
                .padding(.horizontal, isPad ? 28 : 20)
                .padding(.top, isPad ? 14 : 10)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Actions

    private func advance() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                currentPage += 1
            }
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                onboardingDone = true
            }
        }
    }
}
