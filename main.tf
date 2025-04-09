# Create 4 S3 Buckets with No Public Access
resource "aws_s3_bucket" "private_buckets" {
  count  = var.bucket_count
  bucket = "${var.bucket_prefix}-${var.student_id}-${count.index}"  
}

# Block Public Access for all Buckets
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  count  = var.bucket_count
  bucket = aws_s3_bucket.private_buckets[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload file to the s3 buckets with loop
resource "aws_s3_object" "upload_files" {
  for_each = {
    for pair in setproduct(range(var.bucket_count), fileset(var.file_path, "**")) :
    "${pair[0]}-${pair[1]}" => {
      bucket_index = pair[0]
      file_name    = pair[1]
    }
  }

  bucket = "${var.bucket_prefix}-${var.student_id}-${each.value.bucket_index}"
  key    = each.value.file_name
  source = "${var.file_path}/${each.value.file_name}"
  etag   = filemd5("${var.file_path}/${each.value.file_name}")

  depends_on = [aws_s3_bucket.private_buckets]
}