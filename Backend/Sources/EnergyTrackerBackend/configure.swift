import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
  // uncomment to serve files from /Public folder
  // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
  
  app.databases.use(
    .postgres(
      hostname: Environment.get("DATABASE_HOST") ?? "localhost",
      port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432,
      username: Environment.get("DATABASE_USERNAME") ?? "yauheni",
      password: Environment.get("DATABASE_PASSWORD") ?? "",
      database: Environment.get("DATABASE_NAME") ?? "energy_tracker"
    ),
    as: .psql
  )
  
  app.migrations.add(CreateUser())
  app.views.use(.leaf)
  
  // register routes
  try app.register(collection: AuthController())
}
