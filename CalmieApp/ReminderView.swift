//  ReminderView.swift
//  CalmieApp

import SwiftUI
import UserNotifications

struct ReminderView: View {
    @Environment(\.dismiss)             private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderHour")    private var reminderHour    = 8
    @AppStorage("reminderMinute")  private var reminderMinute  = 0

    @State private var selectedTime: Date = Date()
    @State private var permissionDenied  = false
    @State private var showSavedConfirm  = false

    private var isPad: Bool { hSizeClass == .regular }
    private var hPadding: CGFloat      { isPad ? 48 : 20  }
    private var headerFont: CGFloat    { isPad ? 26 : 20  }
    private var bellSize: CGFloat      { isPad ? 72 : 52  }
    private var labelFont: CGFloat     { isPad ? 20 : 16  }
    private var toggleRowFont: CGFloat { isPad ? 18 : 16  }
    private var btnWidth: CGFloat      { isPad ? 260 : 200 }
    private var btnHeight: CGFloat     { isPad ? 64  : 52  }
    private var btnFont: CGFloat       { isPad ? 22  : 18  }
    private var pickerMax: CGFloat     { isPad ? 280 : 200 }

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

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: isPad ? 22 : 18, weight: .bold))
                    }
                    Spacer()
                    Text("Daily Reminder")
                        .foregroundColor(.white)
                        .font(.system(size: headerFont, weight: .bold))
                    Spacer()
                    Color.clear.frame(width: isPad ? 22 : 18, height: isPad ? 22 : 18)
                }
                .padding(.horizontal, hPadding)
                .padding(.top, isPad ? 32 : 20)

                Spacer()

                Image(systemName: "bell.fill")
                    .font(.system(size: bellSize))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, isPad ? 32 : 24)

                Text("Remind me to meditate at:")
                    .font(.system(size: labelFont))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, isPad ? 20 : 16)

                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .frame(maxWidth: pickerMax)
                    .padding(.bottom, isPad ? 40 : 32)

                HStack {
                    Text("Daily reminder")
                        .foregroundColor(.white)
                        .font(.system(size: toggleRowFont))
                    Spacer()
                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .onChange(of: reminderEnabled) { _, enabled in
                            enabled ? requestAndSchedule() : cancelReminder()
                        }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, isPad ? 20 : 16)
                .background(Color.white.opacity(0.12))
                .cornerRadius(isPad ? 20 : 16)
                .padding(.horizontal, hPadding)
                .padding(.bottom, isPad ? 20 : 16)

                if permissionDenied {
                    Text("Enable notifications in iOS Settings → CalmieApp")
                        .font(.system(size: isPad ? 15 : 13))
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, hPadding)
                        .padding(.bottom, 8)
                }

                Button(action: {
                    saveTime()
                    if reminderEnabled { requestAndSchedule() }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation { showSavedConfirm = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { showSavedConfirm = false }
                    }
                }) {
                    HStack(spacing: 8) {
                        if showSavedConfirm {
                            Image(systemName: "checkmark")
                                .font(.system(size: isPad ? 20 : 16, weight: .bold))
                            Text("Saved!")
                                .font(.system(size: btnFont, weight: .bold))
                        } else {
                            Text("Save time")
                                .font(.system(size: btnFont, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: btnWidth, height: btnHeight)
                    .background(
                        showSavedConfirm
                            ? Color.green.opacity(0.7)
                            : Color(red: 0.255, green: 0.452, blue: 0.428)
                    )
                    .cornerRadius(btnHeight / 2)
                    .animation(.easeInOut(duration: 0.25), value: showSavedConfirm)
                }
                .padding(.bottom, isPad ? 70 : 50)

                Spacer()
            }
            .frame(maxWidth: isPad ? 560 : .infinity)
        }
        .onAppear {
            var c = DateComponents()
            c.hour = reminderHour; c.minute = reminderMinute
            if let date = Calendar.current.date(from: c) { selectedTime = date }
        }
    }

    private func saveTime() {
        let cal = Calendar.current
        reminderHour   = cal.component(.hour,   from: selectedTime)
        reminderMinute = cal.component(.minute, from: selectedTime)
    }

    private func requestAndSchedule() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted { permissionDenied = false; scheduleNotification() }
                else       { reminderEnabled = false; permissionDenied = true }
            }
        }
    }

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_meditation"])
        let content = UNMutableNotificationContent()
        content.title = "Time to meditate 🧘"
        content.body  = "Take a moment for yourself. Even 5 minutes makes a difference."
        content.sound = .default
        var trigger = DateComponents()
        trigger.hour = reminderHour; trigger.minute = reminderMinute
        center.add(UNNotificationRequest(
            identifier: "daily_meditation",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        ))
    }

    private func cancelReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["daily_meditation"])
    }
}
