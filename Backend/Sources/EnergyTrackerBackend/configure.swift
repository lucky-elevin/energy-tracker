import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

extension Application {
  /// Returns the database name for the current environment.
  ///
  /// In testing mode, a dedicated test database is always used.
  /// In other environments, the value comes from `DATABASE_NAME`
  /// with `energy_tracker` as fallback.
  var dataBaseName: String {
    let testableDataBase = "energy_tracker_test"
    let dataBase = Environment.get(EnvironmentKey.databaseName) ?? "energy_tracker"
    return environment == .testing ? testableDataBase : dataBase
  }
}


private enum EnvironmentKey {
  static let databaseHost = "DATABASE_HOST"
  static let databasePort = "DATABASE_PORT"
  static let databaseUsername = "DATABASE_USERNAME"
  static let databasePassword = "DATABASE_PASSWORD"
  static let databaseName = "DATABASE_NAME"
}

private struct AppDatabaseConfiguration {
  let host: String
  let port: Int
  let username: String
  let password: String
  let name: String
  
  init(app: Application) {
    self.host = Environment.get(EnvironmentKey.databaseHost) ?? "localhost"
    self.port = Environment.get(EnvironmentKey.databasePort).flatMap(Int.init(_:)) ?? 5432
    self.username = Environment.get(EnvironmentKey.databaseUsername) ?? "postgres"
    self.password = Environment.get(EnvironmentKey.databasePassword) ?? ""
    self.name = app.dataBaseName
  }
}

/// Configures the application's core services and runtime behavior.
///
/// This setup registers:
/// - PostgreSQL database connection settings.
/// - BCrypt as the password hashing provider.
/// - Database migrations.
/// - Leaf as the view renderer.
/// - HTTP routes.
///
/// Database values are read from these environment variables:
/// `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`,
/// `DATABASE_PASSWORD`, and `DATABASE_NAME`.
/// If missing, sensible local defaults are used.
///
/// - Parameter app: Vapor application instance to configure before startup.
public func configure(_ app: Application) async throws {  
  let databaseConfiguration = AppDatabaseConfiguration(app: app)
  
  app.databases.use(
    .postgres(
      hostname: databaseConfiguration.host,
      port: databaseConfiguration.port,
      username: databaseConfiguration.username,
      password: databaseConfiguration.password,
      database: databaseConfiguration.name
    ),
    as: .psql
  )
  
  app.passwords.use(.bcrypt)
  app.migrations.add(CreateUser())
  app.views.use(.leaf)
  
  // register routes
  try routes(app)
  
  if app.environment == .development {
    try await app.autoMigrate()
  }
}
