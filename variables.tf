variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix applied to all resources; also used as the tag value"
  type        = string
  default     = "bitgo-infra"
}

variable "container_image" {
  description = "Docker image for the web service"
  type        = string
  default     = "ghcr.io/therealdwright/scalable-web-service:v1"
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "desired_count" {
  description = "Initial ECS task count before autoscaling takes over"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum ECS task count; 2 ensures one task per AZ at baseline"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum ECS task count autoscaling can scale out to"
  type        = number
  default     = 10
}
