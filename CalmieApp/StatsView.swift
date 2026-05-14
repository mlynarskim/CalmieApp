//  StatsView.swift
//  CalmieApp

import SwiftUI
import CoreData

// MARK: - Badge model

struct MeditationBadge: Identifiable {
    let id = UUID()
    let emoji: String
    let name: String
    let sessions: Int   // sessions needed to unlock
}

private let allBadges: [MeditationBadge] = [
    MeditationBadge(emoji: "🌱", name: "First Breath",    sessions: 1),
    MeditationBadge(emoji: "🌿", name: "Seedling",        sessions: 3),
    MeditationBadge(emoji: "🧘", name: "Meditator",       sessions: 5),
    MeditationBadge(emoji: "🌸", name: "Blooming",        sessions: 7),
    MeditationBadge(emoji: "💧", name: "Flow State",      sessions: 10),
    MeditationBadge(emoji: "🌊", name: "Deep Water",      sessions: 15),
    MeditationBadge(emoji: "🍃", name: "Leaf",            sessions: 20),
    MeditationBadge(emoji: "☀️", name: "Sunrise",         sessions: 25),
    MeditationBadge(emoji: "🔥", name: "On Fire",         sessions: 30),
    MeditationBadge(emoji: "🌙", name: "Moonrise",        sessions: 40),
    MeditationBadge(emoji: "🦋", name: "Butterfly",       sessions: 50),
    MeditationBadge(emoji: "🌳", name: "Tree",            sessions: 60),
    MeditationBadge(emoji: "✨", name: "Glow",            sessions: 75),
    MeditationBadge(emoji: "🏔️", name: "Mountain",       sessions: 100),
    MeditationBadge(emoji: "🌺", name: "Lotus",           sessions: 120),
    MeditationBadge(emoji: "🌌", name: "Galaxy",          sessions: 150),
    MeditationBadge(emoji: "🧠", name: "Mind Master",     sessions: 175),
    MeditationBadge(emoji: "💫", name: "Enlightened",     sessions: 200),
    MeditationBadge(emoji: "🕊️", name: "Inner Peace",    sessions: 300),
    MeditationBadge(emoji: "🌟", name: "Year of Zen",     sessions: 365),
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

    // MARK: Computed

    private var totalSessions: Int { sessions.count }
    private var totalMinutes:  Int { sessions.reduce(0) { $0 + Int($1.duration) } }

    private var currentStreak: Int {
        let cal = Calendar.current
        let days = Set(sessions.compactMap(\.date).map { cal.startOfDay(for: $0) })
        guard !days.isEmpty else { return 0 }
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        var check = days.contains(today) ? today : days.contains(yesterday) ? yesterday : nil
        guard var d = check else { return 0 }
        var streak = 0
        while days.contains(d) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
        }
        return streak
    }

    private var unlockedBadges: [MeditationBadge] {
        allBadges.filter { totalSessions >= $0.sessions }
    }

    private var currentBadge: MeditationBadge? { unlockedBadges.last }

    private var nextBadge: MeditationBadge? {
        allBadges.first { totalSessions < $0.sessions }
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

                    // MARK: Streak
                    VStack(spacing: 4) {
                        Text("🔥")
                            .font(.system(size: 44))
                        Text("\(currentStreak)")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)
                        Text(currentStreak == 1 ? "day streak" : "day streak")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // MARK: Badges
                    VStack(spacing: 14) {
                        // Current badge hero
                        if let badge = currentBadge {
                            VStack(spacing: 6) {
                                Text(badge.emoji)
                                    .font(.system(size: 64))
                                Text(badge.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                if let next = nextBadge {
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
                            }
                        } else {
                            VStack(spacing: 6) {
                                Text("🔒")
                                    .font(.system(size: 64))
                                Text("No badge yet")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("FIRST BADGE: 1 SESSION")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.45))
                                    .tracking(1)
                            }
                        }

                        // Grid wszystkich odznak
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5),
                            spacing: 12
                        ) {
                            ForEach(allBadges) { badge in
                                let unlocked = totalSessions >= badge.sessions
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(unlocked
                                                  ? Color.white.opacity(0.18)
                                                  : Color.white.opacity(0.06))
                                            .frame(width: 52, height: 52)
                                        Text(unlocked ? badge.emoji : "🔒")
                                            .font(.system(size: unlocked ? 26 : 20))
                                            .grayscale(unlocked ? 0 : 1)
                                            .opacity(unlocked ? 1 : 0.4)
                                    }
                                    Text("\(badge.sessions)")
                                        .font(.system(size: 10))
                                        .foregroundColor(unlocked
                                                         ? .white.opacity(0.7)
                                                         : .white.opacity(0.25))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // MARK: Meditation stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Meditation")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        HStack(spacing: 0) {
                            StatCell(value: "\(totalSessions)", label: "Sessions")
                            Divider().frame(width: 1).background(Color.white.opacity(0.15))
                            StatCell(value: "\(totalMinutes)", label: "Minutes")
                        }
                        .padding(.bottom, 16)
                    }
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // MARK: Breathing stats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Breathing")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.top, 16)

                        HStack(spacing: 0) {
                            StatCell(value: "\(breathingSessionCount)", label: "Sessions")
                            Divider().frame(width: 1).background(Color.white.opacity(0.15))
                            StatCell(value: "\(breathingTotalCycles)", label: "Cycles")
                        }
                        .padding(.bottom, 16)
                    }
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)

                    // MARK: History
                    if !sessions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Sessions")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                Text("← swipe to delete")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.35))
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
                            .padding(.top, 4)
                    }

                    Spacer(minLength: 30)
                }
            }
        }
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
