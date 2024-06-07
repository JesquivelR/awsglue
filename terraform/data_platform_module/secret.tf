resource "aws_secretsmanager_secret" "rds_secret" {
  name                    = "rds-secret"
  description             = "RDS Instance Secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.rds_password.result
    engine   = "mysql"
    host     = aws_db_instance.rds_instance.address
    port     = aws_db_instance.rds_instance.port
    dbname   = aws_db_instance.rds_instance.db_name
  })
}