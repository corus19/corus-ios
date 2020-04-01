//
//  LocalNotificationCenterService.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 31/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import UserNotifications

// DEBUG
class LocalNotificationCenterService {

    static let shared = LocalNotificationCenterService()
    let center = UNUserNotificationCenter.current()

    func scheduleNotification(title: String, body: String) {

        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                self.requestPermissions()
            } else {
                let content = UNMutableNotificationContent() 

                content.title = title
                content.body = body
                content.sound = UNNotificationSound.default
                content.badge = 1

                let identifier = "UYLLocalNotification"
                let date = Date(timeIntervalSinceNow: 1)
                let triggerDate = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute,.second,],
                  from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate,
                repeats: false)
                let request = UNNotificationRequest(identifier: identifier,
                  content: content, trigger: trigger)
                self.center.add(request, withCompletionHandler: { (error) in
                  if let error = error {
                    print(error)
                  }
                })
            }
        }
    }

    func requestPermissions() {
        center.requestAuthorization(options: [.alert, .sound]) {
          (granted, error) in
            if !granted {
              print("Something went wrong")
            }
        }
    }
}

