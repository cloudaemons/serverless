resource "aws_glue_catalog_database" "video_analytics" {
  name = "video-analytics-${var.environment}-${var.application}"
}

resource "aws_glue_catalog_table" "events" {
  database_name = aws_glue_catalog_database.video_analytics.name
  name          = "events-${var.environment}-${var.application}"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.events.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "s3-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "userId"
      type = "string"
    }

    columns {
      name = "format"
      type = "string"
    }
    
    columns {
      name = "timestamp"
      type = "timestamp"
    }

  }
}
