output "alb_dns" { value = aws_lb.arena.dns_name }
output "team_hosts" {
  value = { for k, m in module.team : k => m.host }
}
