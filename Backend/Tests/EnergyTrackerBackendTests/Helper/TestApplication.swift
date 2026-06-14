//
//  File.swift
//  EnergyTrackerBackend
//
//  Created by Yauheni Levin on 14/06/2026.
//

import Vapor
import SQLKit
@testable import EnergyTrackerBackend

/// Manages temporary PostgreSQL databases used by integration tests.
///
/// Each test application receives its own database so migrations and writes can
/// run without leaking state into other tests.
enum TestDatabaseManager {
  /// Builds a unique database name for a test run.
  ///
  /// PostgreSQL identifiers cannot use hyphens safely in raw identifier
  /// interpolation, so the UUID is normalized with underscores before it is
  /// appended to the project-specific test database prefix.
  static func makeDatabaseName() -> String {
    let id = UUID()
      .uuidString
      .replacingOccurrences(of: "-", with: "_")
      .lowercased()
    return "energy_tracker_test_\(id)"
  }
  
  /// Creates a new PostgreSQL database with the provided name.
  ///
  /// The operation runs against the administrative `postgres` database because
  /// the target test database does not exist yet.
  static func createDatabase(named name: String) async throws {
    try await withAdminDatabase { sql in
      try await sql.raw("CREATE DATABASE \(ident: name)").run()
    }
  }

  /// Drops a PostgreSQL database created for a test run.
  ///
  /// `IF EXISTS` keeps cleanup tolerant of partially failed setup, while
  /// `WITH (FORCE)` disconnects active sessions before dropping the database.
  static func dropDatabase(named name: String) async throws {
    try await withAdminDatabase { sql in
      try await sql.raw("DROP DATABASE IF EXISTS \(ident: name) WITH (FORCE)").run()
    }
  }
  
  /// Opens an administrative SQL connection and performs the supplied operation.
  ///
  /// A lightweight Vapor application is configured with a connection to the
  /// default `postgres` database. The application is always shut down after the
  /// operation succeeds or fails so connection resources are released.
  private static func withAdminDatabase(_ operation: (any SQLDatabase) async throws -> Void) async throws {
    let app = try await Application.make(.testing)
    do {
        app.databases.use(
          .postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "127.0.0.1",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5433,
            username: Environment.get("DATABASE_USERNAME") ?? "postgres",
            password: Environment.get("DATABASE_PASSWORD") ?? "12345",
            database: "postgres"
          ),
          as: .psql
        )
        guard let sql = app.db as? any SQLDatabase else {
          throw Abort(.internalServerError, reason: "Database does not support raw SQL")
        }
        try await operation(sql)
        try await app.asyncShutdown()
      } catch {
        try await app.asyncShutdown()
        throw error
      }
  }
}

func withTestApp(_ body: (Application) async throws -> Void) async throws {
  let testDatabaseName = TestDatabaseManager.makeDatabaseName()
  try await TestDatabaseManager.createDatabase(named: testDatabaseName)
  let app = try await Application.make(.testing)
  do {
    try await configure(app, databaseName: testDatabaseName)
    try await app.autoMigrate()
    try await body(app)
    try await app.asyncShutdown()
    try await TestDatabaseManager.dropDatabase(named: testDatabaseName)
  } catch {
    try? await app.asyncShutdown()
    try? await TestDatabaseManager.dropDatabase(named: testDatabaseName)
    throw error
  }
}
