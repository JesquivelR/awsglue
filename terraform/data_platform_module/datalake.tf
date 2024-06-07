resource "aws_s3_bucket" "datalake" {
  bucket = "handytec-bucket"

  tags = {
    Name        = "handytec-bucket"
    Environment = "${var.environment}"
  }
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    id = "log"
    status = "Enabled"

    expiration {
      days = 5
    }

    transition {
      days          = 4
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_logging" "s3_logging" {
  bucket        = aws_s3_bucket.datalake.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "handytec-log-bucket"

  tags = {
    Name        = "handytec-log-bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "allow_requests" {
  statement {
    sid       = "AllowSSLRequestsOnly"
    effect    = "Deny"
    resources = [aws_s3_bucket.datalake.arn,"${aws_s3_bucket.datalake.arn}/*",]
    actions   = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "datalake_policy" {
  bucket = aws_s3_bucket.datalake.id
  policy = data.aws_iam_policy_document.allow_requests.json
}
