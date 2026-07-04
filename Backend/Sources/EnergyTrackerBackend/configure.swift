import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import JWT

extension Application {
  /// Returns the database name for the current environment.
  ///
  /// In testing mode, a dedicated test database is always used.
  /// In other environments, the value comes from `DATABASE_NAME`
  /// with `energy_tracker` as fallback.
  var databaseName: String {
    if environment == .testing {
      return "energy_tracker_test"
    }
    return Environment.get("DATABASE_NAME") ?? "energy_tracker"
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
  
  init(app: Application, databaseName: String? = nil) {
    self.host = Environment.get("DATABASE_HOST") ?? "127.0.0.1"
    self.port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 5433
    self.username = Environment.get("DATABASE_USERNAME") ?? "postgres"
    self.password = Environment.get("DATABASE_PASSWORD") ?? "12345"
    self.name = databaseName ?? app.databaseName
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
public func configure(_ app: Application, databaseName: String? = nil) async throws {
  let databaseConfiguration = AppDatabaseConfiguration(app: app, databaseName: databaseName)

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
  app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

  app.avatarProcessor = try ImageMagickAvatarProcessor()
  // register routes
  try routes(app)

  switch app.environment {
  case .testing:
    app.jwt.signers.use(.hs256(key: "test-secret"))
  default:
    guard let jwtSecret = Environment.get("JWT_SECRET") else {
      fatalError("JWT_SECRET is missing")
    }
    app.jwt.signers.use(.hs256(key: jwtSecret))
  }

  if app.environment == .development {
    try await app.autoMigrate()
  }
}
