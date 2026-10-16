variable "region"      { default = "ap-south-1" }
variable "team_names"  { type = list(string) }   # e.g. ["team-01","team-02"]; must be team-NN
variable "image_tag"   { type = string }         # git sha from pipeline
variable "domain_name" { default = "" }          # e.g. arena.example.com ("" = no DNS, test via ALB DNS)
variable "zone_id"     { default = "" }          # Route53 hosted zone id for the parent domain
variable "cpu"         { default = 256 }
variable "memory"      { default = 512 }
