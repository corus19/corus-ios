//
//  PeriferalCoreDataStorage.swift
//  CoronaTracer
//
//  Created by Oleh Kudinov on 28/03/2020.
//  Copyright © 2020 CoronaTracer. All rights reserved.
//

import Foundation

import CoreData

enum CoreDataMoviesQueriesStorageError: Error {
    case readError(Error)
    case writeError(Error)
    case deleteError(Error)
}

final class PeripheralCoreDataStorage {

    private let coreDataStorage: CoreDataStorage

    init(coreDataStorage: CoreDataStorage = CoreDataStorage.shared) {
        self.coreDataStorage = coreDataStorage
    }

    func save(peripherals: [Peripheral], completion: @escaping (Result<[Peripheral], Error>) -> Void) {

        coreDataStorage.performBackgroundTask { context in
            do {
                let entities = peripherals.map { PeripheralEntity(peripheral: $0, insertInto: context) }

                try context.save()
                let peripherals = entities.map (Peripheral.init)
                completion(.success(peripherals))
            } catch {
                completion(.failure(CoreDataMoviesQueriesStorageError.writeError(error)))
                print(error)
            }
        }
    }

    func fetch(with predicate: NSPredicate?, fetchLimit: Int = 0, sortDescriptors: [NSSortDescriptor] = [], inContext context: NSManagedObjectContext) throws -> [PeripheralEntity] {
        let request: NSFetchRequest<PeripheralEntity> = PeripheralEntity.fetchRequest()
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        request.fetchLimit = fetchLimit
        return try context.fetch(request)
    }
}

private extension PeripheralEntity {
    convenience init(peripheral: Peripheral, insertInto context: NSManagedObjectContext) {
        self.init(context: context)
        bluetoothSignature = peripheral.bluetoothSignature
        name = peripheral.name
        rssi = Int32(peripheral.rssi)
        syncTimestamp = Date()
        timestamp = NSDecimalNumber(decimal: Decimal(peripheral.timestamp))
    }
}

private extension Peripheral {
    init(peripheralEntity: PeripheralEntity) {
        bluetoothSignature = peripheralEntity.bluetoothSignature!
        name = peripheralEntity.name
        rssi = Int(peripheralEntity.rssi)
        txPower = Int(peripheralEntity.txPower)
        timestamp = peripheralEntity.timestamp?.doubleValue ?? 0
    }
}
