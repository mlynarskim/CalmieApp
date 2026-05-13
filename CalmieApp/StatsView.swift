//  StatsView.swift
//  CalmieApp

import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MeditationSession.date, ascending: false)],
        animation: .default
    ) private var sessions: FetchedResults<MeditationSession>

    private var totalSessions: Int {
        sessions.count
    }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + Int($1.duration) }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(sessions[index])
        }
        try? viewContext.save()
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let sessionDays = Set(sessions.compactMap { $0.date }.map { calendar.startOfDay(for: $0) })
        guard !sessionDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        var checkDate: Date
        if sessionDays.contains(today) {
            checkDate = today
        } else if sessionDays.contains(yesterday) {
            checkDate = yesterday
        } else {
            return 0
        }

        var streak = 0
        while sessionDays.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

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

            VStack(spacing: 24) {
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
                    // balans
                    Color.clear.frame(width: 18, height: 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Streak — główna karta
                VStack(spacing: 6) {
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
                .padding(.vertical, 28)
                .background(Color.white.opacity(0.12))
                .cornerRadius(20)
                .padding(.horizontal, 20)

                // Dwie karty obok siebie
                HStack(spacing: 16) {
                    StatCard(value: "\(totalSessions)", label: "sessions")
                    StatCard(value: "\(totalMinutes)", label: "minutes")
                }
                .padding(.horizontal, 20)

                // Historia sesji
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
                        .padding(.top, 10)
                }

                Spacer()
            }
        }
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
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
