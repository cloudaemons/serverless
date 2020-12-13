resource "aws_kinesis_firehose_delivery_stream" "events" {
  name        = "events-stream-${var.environment}-${var.application}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.events.arn
    buffer_interval = 60
    buffer_size     = 64

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.events.database_name
        role_arn      = aws_iam_role.firehose_role.arn
        table_name    = aws_glue_catalog_table.events.name
      }
    }
  }
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose-role-${var.environment}-${var.application}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "firehose_policy_document" {
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]

    effect = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.events.arn,
      "${aws_s3_bucket.events.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "firehose_policy" {
  name   = "firehose-${var.environment}-${var.application}"
  policy = data.aws_iam_policy_document.firehose_policy_document.json
}

resource "aws_iam_role_policy_attachment" "firehose_role_attachement" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

