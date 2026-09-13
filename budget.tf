# Safety net against forgetting to `terraform destroy` — emails when actual
# spend for the current calendar month crosses 50% and 100% of the threshold.
resource "aws_budgets_budget" "cost_alert" {
  name         = "${var.project_name}-cost-alert"
  budget_type  = "COST"
  limit_amount = var.budget_alert_threshold_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
