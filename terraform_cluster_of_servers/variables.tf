variable "server_port" {
  description = "Port for the server to listen on"
  default     = 80
}

variable "instance_security_group_name" {
  description = "Security group name for instances"
  default     = "instance-sg"
}

variable "alb_security_group_name" {
  description = "Security group name for ALB"
  default     = "alb-sg"
}

variable "alb_name" {
  description = "Name for the ALB"
  default     = "example-alb"
}
