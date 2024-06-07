resource "aws_cognito_user_pool" "pool" {
    name = "handytec_user_pool"
    username_attributes = ["email"]
    username_configuration {
        case_sensitive = false
    }
    password_policy {
        minimum_length = 8
        require_lowercase = true
        require_uppercase = true
        require_numbers = true
        require_symbols = true
    }

    mfa_configuration = "OFF"

    account_recovery_setting {
        recovery_mechanism {
            name     = "verified_email"
            priority = 1
        }
        recovery_mechanism {
            name     = "verified_phone_number"
            priority = 2
        }
    }

    schema {
        attribute_data_type = "String"
        mutable = true
        name = "email"
        required = true
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

    schema {
        attribute_data_type = "String"
        mutable = true
        name = "name"
        required = true
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

    schema {
        attribute_data_type = "String"
        mutable = true
        name = "preferred_username"
        required = true
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

    schema {
        attribute_data_type = "String"
        mutable = true
        name = "phone_number"
        required = true
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

    schema {
        attribute_data_type      = "String"
        developer_only_attribute = false
        mutable                  = true
        name                     = "InformacionPersonal"
        required                 = false
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

    schema {
        attribute_data_type      = "String"
        developer_only_attribute = false
        mutable                  = true
        name                     = "Rol"
        required                 = false
        string_attribute_constraints {
            min_length = 1
            max_length = 2048
        }
    }

}

resource "aws_cognito_user_pool_client" "client" {
    name         = "handytec_app_client"
    user_pool_id = aws_cognito_user_pool.pool.id

    allowed_oauth_flows       = ["code", "implicit"]
    allowed_oauth_scopes      = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
    allowed_oauth_flows_user_pool_client = true
    generate_secret           = false

    callback_urls = ["https://handytec-data-platform.com/callback"]
    logout_urls   = ["https://handytec-data-platform.com/logout"]

    explicit_auth_flows = [
        "ALLOW_USER_SRP_AUTH",
        "ALLOW_REFRESH_TOKEN_AUTH",
        "ALLOW_CUSTOM_AUTH",
        "ALLOW_USER_PASSWORD_AUTH",
        "ALLOW_ADMIN_USER_PASSWORD_AUTH"
    ]
}

resource "aws_cognito_user_pool_domain" "domain" {
    domain      = "handytec-user-pool-domain"
    user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_identity_pool" "identity_pool" {
    identity_pool_name = "handytec_identity_pool"
    allow_unauthenticated_identities = false
    cognito_identity_providers {
        client_id = aws_cognito_user_pool_client.client.id
        provider_name = aws_cognito_user_pool.pool.endpoint
    }
}

resource "aws_iam_role" "authenticated_role" {
    name = "Cognito_handytec_authenticated"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role" "unauthenticated_role" {
    name = "Cognito_handytec_unauthenticated"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "authenticated_role_policy" {
    role       = aws_iam_role.authenticated_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}

resource "aws_iam_role_policy_attachment" "unauthenticated_role_policy" {
    role       = aws_iam_role.unauthenticated_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoReadOnly"
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_pool_roles" {
    identity_pool_id = aws_cognito_identity_pool.identity_pool.id
    roles = {
        "authenticated"   = aws_iam_role.authenticated_role.arn
        "unauthenticated" = aws_iam_role.unauthenticated_role.arn
    }
}
