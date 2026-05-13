//  ReminderView.swift
//  CalmieApp

import SwiftUI
import UserNotifications

struct ReminderView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour") private var reminderHour = 8
    @AppStorage("reminderMinute") private var reminderMinute = 0

    @State private var selectedTime: Date = Date()
    @State private var permissionDenied = false
    @State private var showSavedConfirm = false

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
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    Spacer()
                    Text("Daily Reminder")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                    Color.clear.frame(width: 18, height: 18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()

                Image(systemName: "bell.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 24)

                Text("Remind me to meditate at:")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 16)

                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: 200)
                    .padding(.bottom, 32)

                HStack {
                    Text("Daily reminder")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                requestAndSchedule()
                            } else {
                                cancelReminder()
                            }
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.12))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                if permissionDenied {
                    Text("Enable notifications in iOS Settings → CalmieApp")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                // Przycisk zapisu z potwierdzeniem
                Button(action: {
                    saveTime()
                    if reminderEnabled { requestAndSchedule() }

                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)

                    withAnimation { showSavedConfirm = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { showSavedConfirm = false }
                    }
                }) {
                    HStack(spacing: 8) {
                        if showSavedConfirm {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                            Text("Saved!")
                                .font(.system(size: 18, weight: .bold))
                        } else {
                            Text("Save time")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 200, height: 52)
                    .background(
                        showSavedConfirm
                            ? Color.green.opacity(0.7)
                            : Color(red: 0.255, green: 0.452, blue: 0.428)
                    )
                    .cornerRadius(26)
                    .animation(.easeInOut(duration: 0.25), value: showSavedConfirm)
                }
                .padding(.bottom, 50)

                Spacer()
            }
        }
        .onAppear {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            if let date = Calendar.current.date(from: components) {
                selectedTime = date
            }
        }
    }

    private func saveTime() {
        let cal = Calendar.current
        reminderHour = cal.component(.hour, from: selectedTime)
        reminderMinute = cal.component(.minute, from: selectedTime)
    }

    private func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    permissionDenied = false
                    scheduleNotification()
                } else {
                    reminderEnabled = false
                    permissionDenied = true
                }
            }
        }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_meditation"])

        let content = UNMutableNotificationContent()
        content.title = "Time to meditate 🧘"
        content.body = "Take a moment for yourself. Even 5 minutes makes a difference."
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour = reminderHour
        trigger.minute = reminderMinute

        let request = UNNotificationRequest(
            identifier: "daily_meditation",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        center.add(request)
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_meditation"])
    }
}
