output "cloud_sql_connection_name" {
  value = google_sql_database_instance.mysql.connection_name
}

output "cloud_sql_instance_name" {
  value = "mysql-private-${random_string.db_name_suffix.result}"
}