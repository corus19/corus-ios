//
//  AppBackgroundTasks.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import BackgroundTasks
import UIKit

class AppBackgroundTasks {

    let syncBluetoothId = "com.SO.syncBluetooth"
    let syncDataId = "com.SO.syncData"

    static let shared = AppBackgroundTasks()

    //MARK: Register BackGround Tasks

    func registerBackgroundTaks() {
        registerSyncBluetooth()
        registerSyncData()
    }

    func scheduleTasks() {
        scheduleSyncBluetoothTask()
        scheduleSyncDataTask()
    }

    //MARK: Sync Bluetooth

    func registerSyncBluetooth() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: syncBluetoothId, using: .global()) { task in
            self.handleSyncBluetooth(task: task)
        }
    }

    func scheduleSyncBluetoothTask() {

        let request = BGAppRefreshTaskRequest(identifier: syncBluetoothId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule syncBluetooth: \(error)")
        }
    }

    func handleSyncBluetooth(task: BGTask) {

        task.expirationHandler = {
          task.setTaskCompleted(success: false)
        }

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 30) {
            task.expirationHandler = {
                task.setTaskCompleted(success: true)
            }
        }

        BluetoothScannerService.shared.startScanning()

        scheduleSyncBluetoothTask()
    }

    //MARK: Sync Data

    func registerSyncData() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: syncDataId, using: nil) { task in
            self.handleSyncData(task: task)
        }
    }

    func scheduleSyncDataTask() {

        let request = BGProcessingTaskRequest(identifier: syncDataId)
        request.requiresNetworkConnectivity = true // Need to true if your task need to network process. Defaults to false.
        request.requiresExternalPower = false

        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule syncData: \(error)")
        }
    }

    func handleSyncData(task: BGTask) {

        task.expirationHandler = {
          task.setTaskCompleted(success: false)
        }

        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 5 * 60) {
            task.expirationHandler = {
                task.setTaskCompleted(success: true)
            }
        }

        SyncStorageManager.shared.sync()

        scheduleSyncDataTask()
    }
}

class AppFiniteBackgroundTasks {

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    static func registerBackgroundTask() {
        let bgTask = BackgroundExecutable { (f)
            in
            BluetoothScannerService.shared.startScanning()
            SyncStorageManager.shared.sync()
        }
        bgTask.execute()
    }
}


class BackgroundExecutable {
    var identifier: UIBackgroundTaskIdentifier
    let function: (() -> Void) -> Void

    init(function: @escaping (_ completion: () -> Void) -> Void) {
        self.function = function
        self.identifier = UIBackgroundTaskIdentifier.invalid
    }

    func execute() {
        let application = UIApplication.shared
        identifier = application.beginBackgroundTask {
            application.endBackgroundTask(self.identifier)
        }
        function(endBackgroundTask)
    }

    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(identifier)
    }
}
