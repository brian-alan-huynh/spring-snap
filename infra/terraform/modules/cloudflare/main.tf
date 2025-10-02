resource "cloudflare_record" "apex_cname" {
  zone_id = var.zone_id
  name    = "@"
  value   = var.cloudfront_distribution_domain_name
  type    = "CNAME"
  proxied = false
  ttl     = 1
  comment = "Production apex domain CNAME Record for ${var.name_prefix}"
}

resource "cloudflare_record" "api_cname" {
  zone_id = var.zone_id
  name    = "api"
  value   = var.cloudfront_distribution_domain_name
  type    = "CNAME"
  proxied = false
  ttl     = 1
  comment = "Production API domain CNAME Record for ${var.name_prefix}"
}

resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in var.certificate_arn_dvo : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  value   = each.value.value
  proxied = false
  ttl     = 60
}

resource "cloudflare_page_rule" "auth_page_security_headers" {
  zone_id  = var.zone_id
  target   = "*.springsnap.org/api/v1/auth/*"
  priority = 1

  actions = {
    security_level = "high"
    ssl            = "strict"
    browser_check  = "on"
  }
}

resource "cloudflare_page_rule" "main_security_headers" {
  zone_id  = var.zone_id
  target   = "*.springsnap.org/*"
  priority = 2

  actions = {
    security_level = "medium"
    ssl            = "strict"
    browser_check  = "on"
  }
}
