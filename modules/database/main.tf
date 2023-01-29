resource "random_string" "db_name_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "google_sql_database_instance" "mysql" {
  name             = "mysql-private-${random_string.db_name_suffix.result}"
  region           = var.region
  project          = var.project
  database_version = var.mysql_database_version
  # とりあえず
  deletion_protection = false

  settings {
    availability_type = var.mysql_availability_type
    location_preference {
      zone = var.mysql_location_preference
    }
    tier      = var.mysql_machine_type
    disk_size = var.mysql_default_disk_size

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.private_network_id
    }

    # Backups
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
      start_time         = "06:00"
    }
  }
  depends_on = [
    var.private_vpc_connection
  ]
}

resource "google_sql_database" "mysql" {
  name     = "app"
  project  = var.project
  instance = google_sql_database_instance.mysql.name
}

resource "google_sql_user" "mysql" {
  name     = "app"
  project  = var.project
  instance = google_sql_database_instance.mysql.name
  password = google_secret_manager_secret_version.password_version.secret_data
}

resource "google_secret_manager_secret" "password" {
  secret_id = "app-admin-user-password"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "password_version" {
  secret      = google_secret_manager_secret.password.id
  secret_data = "changeme"
}