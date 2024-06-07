resource "aws_db_instance" "rds_instance" {
  identifier              = "handytec-rds-instance"
  db_name                 = "handytecDB"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0.35"
  instance_class          = "db.t3.micro"
  username                = "admin"
  password                = random_password.rds_password.result
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
}

resource "random_password" "rds_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
