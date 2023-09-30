//
//  DatabaseManager.swift
//  InvoiceScreenshots
//
//  Created by Joe Shakely on 9/30/23.
//

import Foundation
import SQLite3

class DatabaseManager {
    
    var db: OpaquePointer?
    
    static let shared = DatabaseManager()
    
    private init() {
        // Create database
//        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//            .appendingPathComponent("ScreenshotDatabase.sqlite")
        
        let fileURL = "file:///Users/joeshakely/Projects/InvoiceScreenshots/ScreenshotDatabase.sqlite"
        
        print(fileURL)
        
        if sqlite3_open(fileURL, &db) != SQLITE_OK {
            print("Error opening database")
        }
        
        // Drop existing table (for development)
        if sqlite3_exec(db, "DROP TABLE IF EXISTS ScreenshotLogs", nil, nil, nil) != SQLITE_OK {
            print("Error dropping table")
        }
        
        // Create table
        if sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS ScreenshotLogs (id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT, timestamp TEXT)", nil, nil, nil) != SQLITE_OK {
            print("Error creating table")
        }
    }
    
    func insertScreenshot(path: String, timestamp: String) {
        var stmt: OpaquePointer?
        
        let queryString = "INSERT INTO ScreenshotLogs (path, timestamp) VALUES (?,?)"
        
        if sqlite3_prepare(db, queryString, -1, &stmt, nil) != SQLITE_OK {
            print("Error binding query")
        }
        
        if sqlite3_bind_text(stmt, 1, path, -1, nil) != SQLITE_OK {
            print("Error binding path")
        }
        
        if sqlite3_bind_text(stmt, 2, timestamp, -1, nil) != SQLITE_OK {
            print("Error binding timestamp")
        }
        
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("Error inserting row")
        }
        print("Query String:")
        print(queryString)
    }
}
