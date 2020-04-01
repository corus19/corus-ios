//
//  SyncStorageManager.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 29/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation
import CoreData

class SyncStorageManager {

    static let shared = SyncStorageManager()

    let bulkSize = 300
    let repeatEverySeconds: TimeInterval = 15 * 60

    private let coreDataStorage = CoreDataStorage.shared
    private let peripheralCoreDataStorage = PeripheralCoreDataStorage()
    private var timer: Timer?

    var isSynchroning = false
    func sync() {
        timer = Timer.scheduledTimer(timeInterval: repeatEverySeconds, target: self, selector: #selector(syncPeripherals), userInfo: nil, repeats: true)
        syncPeripherals()
    }
    
    private func isUserMarkedAsPositive() -> Bool {
        return UserStorage.shared.shouldMarkedAsPositive
    }
    
    private func fetchSettings() {
        LoadingView.show()
        
        let requestDTO = SettingsPostRequestDTO(country: "string", keys: ["string"])
        let endpoint = APIEndpoints.postGetSettings(with: requestDTO)
        DIContainer.shared.apiDataTransferService.request(with: endpoint) { response in
            switch response {
            case .success(let responseDTO):
                print(responseDTO)
            case .failure(let error):
                print(error.localizedDescription)
            }
            LoadingView.hide()
        }
    }

    @objc private func syncPeripherals() {

        // I am not marked as positive
            // do not sync
        if  !isUserMarkedAsPositive() {
            return
        }
        
        // call settings endpoint

        guard !isSynchroning else { return }
        isSynchroning = true

        coreDataStorage.performBackgroundTask { context in
            do {
                let sync = try self.fetchOrInsertSync(inContext: context)

                let sortDescriptors = [NSSortDescriptor(key: #keyPath(PeripheralEntity.syncTimestamp), ascending: true)]
                var predicate: NSPredicate?
                if let peripheralsTimestamp = sync?.peripheralsTimestamp {
                    predicate = NSPredicate(format: "syncTimestamp > %@", peripheralsTimestamp as NSDate)
                }
                let peripherals = try self.peripheralCoreDataStorage.fetch(with: predicate, fetchLimit: self.bulkSize, sortDescriptors: sortDescriptors, inContext: context)

                guard !peripherals.isEmpty else { self.isSynchroning = false; return }
                let timestamp = peripherals.last!.syncTimestamp
                self.postPeripherals(peripherals: peripherals) { result in
                    defer { self.isSynchroning = false }
                    switch result {
                    case .success(_):
                        do {
                            sync?.peripheralsTimestamp = timestamp
                            try context.save()
                            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(10000), qos: .background) {
                                self.syncPeripherals()
                            }
                        } catch {
                            print("Sync Error: \(error.localizedDescription)")
                        }
                    case .failure(let error):
                        print("Sync Error: \(error.localizedDescription)")
                    }
                }

            } catch {
                self.isSynchroning = false
                print("Sync Error: \(error.localizedDescription)")
            }
        }

    }

    // Private
    private func fetchOrInsertSync(inContext context: NSManagedObjectContext) throws -> SyncEntity? {
        let request: NSFetchRequest<SyncEntity> = SyncEntity.fetchRequest()
        if let syncEntity = try context.fetch(request).first {
            return syncEntity
        } else {
            let syncEntity = SyncEntity.init(context: context)
            do { try context.save() } catch {
                print("Sync Error: \(error.localizedDescription)")
            }
            return syncEntity
        }
    }

    private func postPeripherals(peripherals: [PeripheralEntity], completion: @escaping (Result<PeripheralsPostResponseDTO, Error>) -> Void ) {
        let peripheralsDto = PeripheralsPostRequestDTO(peripheralEntities: peripherals)
        let endpoint = APIEndpoints.postBulkContactDetails(with: peripheralsDto)
        DIContainer.shared.apiDataTransferService.request(with: endpoint, completion: completion)
    }
}

private extension PeripheralsPostRequestDTO.PeripheralDTO {
    init(peripheralEntity: PeripheralEntity) {
        bluetoothSignature = peripheralEntity.bluetoothSignature!
        name = peripheralEntity.name
        rssi = Int(peripheralEntity.rssi)
        txPower = Int(peripheralEntity.txPower)
        lat = peripheralEntity.lat
        lng = peripheralEntity.lng
        timestamp = peripheralEntity.timestamp?.doubleValue ?? 0
    }
}

private extension PeripheralsPostRequestDTO {
    init(peripheralEntities: [PeripheralEntity]) {
        deviceRequests = peripheralEntities.map(PeripheralDTO.init)
    }
}
