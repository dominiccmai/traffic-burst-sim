output "endpoint_url" {
  description = "Public HTTPS endpoint — hand this to the graders"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}
