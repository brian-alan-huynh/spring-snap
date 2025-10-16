output "record_cert_validation" {
  description = "Cloudflare record for ACM cert validation"
  value       = cloudflare_dns_record.cert_validation
}
