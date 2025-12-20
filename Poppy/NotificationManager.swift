//
//  NotificationManager.swift
//  Poppy
//
//  Manages daily reminder notifications
//

import Foundation
import UserNotifications
import Combine

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    private let userDefaultsKey = "poppy.dailyReminder.enabled"
    private let reminderHourKey = "poppy.dailyReminder.hour"
    private let reminderMinuteKey = "poppy.dailyReminder.minute"
    private let notificationIdentifier = "poppy.daily.reminder"

    @Published var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: userDefaultsKey)
            if dailyReminderEnabled {
                scheduleDailyReminder()
            } else {
                cancelDailyReminder()
            }
        }
    }

    // Default reminder time: 9:00 AM
    @Published var reminderHour: Int {
        didSet {
            UserDefaults.standard.set(reminderHour, forKey: reminderHourKey)
            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }

    @Published var reminderMinute: Int {
        didSet {
            UserDefaults.standard.set(reminderMinute, forKey: reminderMinuteKey)
            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }

    private init() {
        self.dailyReminderEnabled = UserDefaults.standard.bool(forKey: userDefaultsKey)
        self.reminderHour = UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? 9
        self.reminderMinute = UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? 0
    }

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                print(granted ? "✅ Notification permission granted" : "⚠️ Notification permission denied")
                completion(granted)
            }
        }
    }

    func checkPermissionStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Scheduling

    func scheduleDailyReminder() {
        // Cancel existing reminder first
        cancelDailyReminder()

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "The Daily Poppy"
        content.body = "Today's puzzle is ready! Come see how you compare."
        content.sound = .default

        // Create trigger for daily at specified time
        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: notificationIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily reminder: \(error.localizedDescription)")
            } else {
                print("✅ Daily reminder scheduled for \(self.reminderHour):\(String(format: "%02d", self.reminderMinute))")
            }
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [notificationIdentifier]
        )
        print("🗑️ Daily reminder cancelled")
    }

    // MARK: - Helpers

    var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute

        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(reminderHour):\(String(format: "%02d", reminderMinute))"
    }
}
