check "website_check" {
  data "http" "website" {
    url = "https://www.google.com"
  }

  assert {
    condition     = data.http.website.status_code == 200
    error_message = "Website is down."
  }
}
