//  StatsView.swift
//  CalmieApp

import SwiftUI
import CoreData

// MARK: - Badge model

struct MeditationBadge: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let sessions: Int       // 0 = zawsze odblokowana (welcome)
    let label: String       // opis pod odznaką np. "Welcome", "1 session"
}

private let allBadges: [MeditationBadge] = [
    MeditationBadge(emoji: "🌱", name: "First Breath",  sessions: 0,   label: "Welcome"),
    MeditationBadge(emoji: "🌿", name: "Seedling",      sessions: 1,   label: "1 session"),
    MeditationBadge(emoji: "🧘", name: "Meditator",     sessions: 3,   label: "3 sessions"),
    MeditationBadge(emoji: "🌸", name: "Blooming",      sessions: 5,   label: "5 sessions"),
    MeditationBadge(emoji: "💧", name: "Flow State",    sessions: 7,   label: "7 sessions"),
    MeditationBadge(emoji: "🌊", name: "Deep Water",    sessions: 10,  label: "10 sessions"),
    MeditationBadge(emoji: "🍃", name: "Leaf",          sessions: 15,  label: "15 sessions"),
    MeditationBadge(emoji: "☀️", name: "Sunrise",       sessions: 20,  label: "20 sessions"),
    MeditationBadge(emoji: "🔥", name: "On Fire",       sessions: 25,  label: "25 sessions"),
    MeditationBadge(emoji: "🌙", name: "Moonrise",      sessions: 30,  label: "30 sessions"),
    MeditationBadge(emoji: "🦋", name: "Butterfly",     sessions: 40,  label: "40 sessions"),
    MeditationBadge(emoji: "🌳", name: "Tree",          sessions: 50,  label: "50 sessions"),
    MeditationBadge(emoji: "✨", name: "Glow",          sessions: 60,  label: "60 sessions"),
    MeditationBadge(emoji: "🏔️", name: "Mountain",     sessions: 75,  label: "75 sessions"),
    MeditationBadge(emoji: "🌺", name: "Lotus",         sessions: 100, label: "100 sessions"),
    MeditationBadge(emoji: "🌌", name: "Galaxy",        sessions: 120, label: "120 sessions"),
    MeditationBadge(emoji: "🧠", name: "Mind Master",   sessions: 150, label: "150 sessions"),
    MeditationBadge(emoji: "💫", name: "Enlightened",   sessions: 200, label: "200 sessions"),
    MeditationBadge(emoji: "🕊️", name: "Inner Peace",  sessions: 300, label: "300 sessions"),
    MeditationBadge(emoji: "🌟", name: "Year of Zen",   sessions: 365, label: "365 sessions"),
]

// MARK: - StatsView

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeditationSession.date, ascending: false)],
        animation: .default
    ) private var sessions: FetchedResults<MeditationSession>

    @AppStorage("breathingSessionCount") private var breathingSessionCount = 0
    @AppStorage("breathingTotalCycles")  private var breathingTotalCycles  = 0

    @State private var badgeIndex: Int = 0
    @GestureState private var dragOffset: CGFloat = 0

    // MARK: Computed

    private var totalSessions: Int { sessions.count }
    private var totalMinutes:  Int { sessions.reduce(0) { $0 + Int($1.duration) } }

    private var currentStreak: Int {
        let cal = Calendar.current
        let days = Set(sessions.compactMap(\.date).map { cal.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        guard let start = days.contains(today) ? today : days.contains(yesterday) ? yesterday : nil else { return 0 }
        var d = start; var streak = 0
        while days.contains(d) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return streak
    }

    /// Indeks najwyżej odblokowanej odznaki
    private var highestUnlockedIndex: Int {
        var best = 0
        for (i, b) in allBadges.enumerated() {
            if totalSessions >= b.sessions { best = i }
        }
        return best
    }

    /// Postęp do następnej odznaki (0…1) dla aktualnie wyświetlanej
    private func progressForBadge(at idx: Int) -> CGFloat {
        let badge = allBadges[idx]
        guard totalSessions >= badge.sessions else { return 0 }
        guard let next = allBadges.indices.dropFirst(idx + 1).first.map({ allBadges[$0] }) else { return 1 }
        let range = CGFloat(next.sessions - badge.sessions)
        let done  = CGFloat(totalSessions - badge.sessions)
        return min(done / range, 1)
    }

    private func isUnlocked(_ badge: MeditationBadge) -> Bool {
        totalSessions >= badge.sessions
    }

    private func deleteSessions(at offsets: IndexSet) {
        for i in offsets { viewContext.delete(sessions[i]) }
        try? viewContext.save()
    }

    // MARK: Body

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

            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                        Spacer()
                        Text("Your Progress")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Color.clear.frame(width: 18, height: 18)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // MARK: Badge carousel
                    badgeCarousel
                        .padding(.horizontal, 20)

                    // MARK: Meditation stats
                    statsCard(
                        title: "Meditation",
                        left: (value: "\(totalSessions)", label: "Sessions"),
                        right: (value: "\(totalMinutes)", label: "Minutes"),
                        footer: "🔥 \(currentStreak) day streak"
                    )

                    // MARK: Breathing stats
                    statsCard(
                        title: "Breathing",
                        left: (value: "\(breathingSessionCount)", label: "Sessions"),
                        right: (value: "\(breathingTotalCycles)", label: "Cycles"),
                        footer: nil
                    )

                    // MARK: Session history
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("History")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                Spacer()
                                Text("← swipe to delete")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 4)

                            List {
                                ForEach(sessions) { session in
                                    SessionRow(session: session)
                                        .listRowBackground(Color.clear)
                                        .listRowSeparatorTint(Color.white.opacity(0.15))
                                        .listRowInsets(EdgeInsets())
                                }
                                .onDelete(perform: deleteSessions)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .frame(maxHeight: 280)
                        }
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    } else {
                        Text("No sessions yet.\nComplete your first meditation!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.5))
                            .font(.system(size: 15))
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .onAppear {
            badgeIndex = highestUnlockedIndex
        }
    }

    // MARK: - Badge carousel view

    private var badgeCarousel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                // Strzałka lewo
                Button(action: { withAnimation(.spring()) { badgeIndex = max(0, badgeIndex - 1) } }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(badgeIndex > 0 ? 0.8 : 0.2))
                        .frame(width: 36, height: 36)
                }
                .disabled(badgeIndex == 0)

                Spacer()

                // Poprzednia odznaka (mała)
                if badgeIndex > 0 {
                    smallBadgeView(allBadges[badgeIndex - 1])
                        .transition(.opacity)
                } else {
                    Color.clear.frame(width: 64, height: 64)
                }

                Spacer()

                // Główna odznaka (duża z pierścieniem)
                largeBadgeView(allBadges[badgeIndex])

                Spacer()

                // Następna odznaka (mała)
                if badgeIndex < allBadges.count - 1 {
                    smallBadgeView(allBadges[badgeIndex + 1])
                        .transition(.opacity)
                } else {
                    Color.clear.frame(width: 64, height: 64)
                }

                Spacer()

                // Strzałka prawo
                Button(action: { withAnimation(.spring()) { badgeIndex = min(allBadges.count - 1, badgeIndex + 1) } }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(badgeIndex < allBadges.count - 1 ? 0.8 : 0.2))
                        .frame(width: 36, height: 36)
                }
                .disabled(badgeIndex == allBadges.count - 1)
            }
            // Swipe gesture
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { val in
                        withAnimation(.spring()) {
                            if val.translation.width < 0 {
                                badgeIndex = min(allBadges.count - 1, badgeIndex + 1)
                            } else {
                                badgeIndex = max(0, badgeIndex - 1)
                            }
                        }
                    }
            )

            // Nazwa odznaki
            Text(allBadges[badgeIndex].name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .animation(.none, value: badgeIndex)

            // Opis / next badge info
            let shown = allBadges[badgeIndex]
            if isUnlocked(shown) {
                // Pokaż info o następnej
                if let nextIdx = allBadges.indices.dropFirst(badgeIndex + 1).first {
                    let next = allBadges[nextIdx]
                    Text("NEXT BADGE: \(next.sessions) SESSIONS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1)
                } else {
                    Text("ALL BADGES UNLOCKED 🌟")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .tracking(1)
                }
            } else {
                Text("UNLOCK AT \(shown.sessions) SESSIONS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1)
            }

            // Dots indicator
            HStack(spacing: 5) {
                ForEach(allBadges.indices, id: \.self) { i in
                    Circle()
                        .fill(i == badgeIndex ? Color.white : Color.white.opacity(0.25))
                        .frame(width: i == badgeIndex ? 7 : 5, height: i == badgeIndex ? 7 : 5)
                        .animation(.spring(), value: badgeIndex)
                }
            }
            .padding(.bottom, 4)
        }
        .padding(.vertical, 24)
        .background(Color.white.opacity(0.12))
        .cornerRadius(20)
    }

    // MARK: Large badge (center)

    private func largeBadgeView(_ badge: MeditationBadge) -> some View {
        let unlocked = isUnlocked(badge)
        let progress = progressForBadge(at: allBadges.firstIndex(where: { $0.id == badge.id }) ?? 0)

        return ZStack {
            // Tło koła
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 6)
                .frame(width: 120, height: 120)

            // Pierścień postępu
            Circle()
                .trim(from: 0, to: unlocked ? progress : 0)
                .stroke(style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .foregroundColor(Color(red: 185/255, green: 106/255, blue: 102/255))
                .rotationEffect(.degrees(-90))
                .frame(width: 120, height: 120)
                .animation(.easeInOut(duration: 0.6), value: progress)

            // Wypełnienie koła
            Circle()
                .fill(unlocked ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                .frame(width: 104, height: 104)

            // Emoji
            Text(unlocked ? badge.emoji : "🔒")
                .font(.system(size: 48))
                .grayscale(unlocked ? 0 : 1)
                .opacity(unlocked ? 1 : 0.4)
        }
    }

    // MARK: Small badge (boki)

    private func smallBadgeView(_ badge: MeditationBadge) -> some View {
        let unlocked = isUnlocked(badge)
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color.white.opacity(0.14) : Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)
                Text(unlocked ? badge.emoji : "🔒")
                    .font(.system(size: 26))
                    .grayscale(unlocked ? 0 : 1)
                    .opacity(unlocked ? 0.85 : 0.3)
            }
            Text(badge.label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(unlocked ? 0.6 : 0.25))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 64)
        }
    }

    // MARK: Stats card helper

    private func statsCard(
        title: String,
        left: (value: String, label: String),
        right: (value: String, label: String),
        footer: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            HStack(spacing: 0) {
                StatCell(value: left.value, label: left.label)
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 50)
                StatCell(value: right.value, label: right.label)
            }

            if let footer {
                Text(footer)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                    .padding(.top, 4)
            } else {
                Spacer().frame(height: 16)
            }
        }
        .background(Color.white.opacity(0.12))
        .cornerRadius(20)
        .padding(.horizontal, 20)
    }
}

// MARK: - Helper views

struct StatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.12))
        .cornerRadius(20)
    }
}

struct SessionRow: View {
    let session: MeditationSession

    private var formattedDate: String {
        guard let date = session.date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    var body: some View {
        HStack {
            Image(systemName: "leaf.fill")
                .foregroundColor(Color(red: 0.255, green: 0.452, blue: 0.428))
                .font(.system(size: 14))
            Text(formattedDate)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 14))
            Spacer()
            Text("\(session.duration) min")
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
