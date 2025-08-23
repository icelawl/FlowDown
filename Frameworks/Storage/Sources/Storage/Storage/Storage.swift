//
//  Storage.swift
//  Conversation
//
//  Created by 秋星桥 on 1/21/25.
//

import Foundation
import WCDBSwift

public class Storage {
    let db: Database

    public let databaseDir: URL
    public let databaseLocation: URL

    init() throws {
        databaseDir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("Objects.db")
        databaseLocation = databaseDir
            .appendingPathComponent("database")
            .appendingPathExtension("db")
        db = Database(at: databaseLocation.path)

        db.setAutoBackup(enable: true)
        db.setAutoMigration(enable: true)
        db.enableAutoCompression(true)

        print("[*] database location: \(databaseLocation)")

        try setup(db: db)
    }

    func setup(db: Database) throws {
        try db.create(table: CloudModel.table, of: CloudModel.self)
        try db.create(table: Attachment.table, of: Attachment.self)
        try db.create(table: Message.table, of: Message.self)
        try db.create(table: Conversation.table, of: Conversation.self)
        try db.create(table: ModelContextServer.table, of: ModelContextServer.self)
        try db.create(table: Memory.table, of: Memory.self)
    }

    public func reset() {
        try? db.run { handler in
            try handler.drop(table: CloudModel.table)
            try handler.drop(table: Attachment.table)
            try handler.drop(table: Message.table)
            try handler.drop(table: Conversation.table)
            try handler.drop(table: ModelContextServer.table)
            try handler.drop(table: Memory.table)
            return ()
        }
        db.blockade()
        db.close()
        try? FileManager.default.removeItem(at: databaseDir)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}

public extension Storage {
    func exportDatabase() -> Result<URL, Error> {
        let exportDir = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(
            at: exportDir,
            withIntermediateDirectories: true
        )
        let exportFile = exportDir.appendingPathComponent("database.db")
        let exportDatabase = Database(at: exportFile.path)

        do {
            try setup(db: exportDatabase)

            var getError: Error?
            try exportDatabase.run { [self] expdb in
                do {
                    let mods: [CloudModel] = try db.getObjects(fromTable: CloudModel.table)
                    try expdb.insert(mods, intoTable: CloudModel.table)
                    let cons: [Conversation] = try db.getObjects(fromTable: Conversation.table)
                    try expdb.insert(cons, intoTable: Conversation.table)
                    let msgs: [Message] = try db.getObjects(fromTable: Message.table)
                    try expdb.insert(msgs, intoTable: Message.table)
                    let atts: [Attachment] = try db.getObjects(fromTable: Attachment.table)
                    try expdb.insert(atts, intoTable: Attachment.table)
                    let mems: [Memory] = try db.getObjects(fromTable: Memory.table)
                    try expdb.insert(mems, intoTable: Memory.table)
                    return true
                } catch {
                    getError = error
                    return false
                }
            }
            if let error = getError { throw error }

            let sem = DispatchSemaphore(value: 0)
            try exportDatabase.close {
                sem.signal()
            }
            sem.wait()
        } catch {
            try? FileManager.default.removeItem(at: exportDir)
            return .failure(error)
        }

        return .success(exportDir)
    }
}
