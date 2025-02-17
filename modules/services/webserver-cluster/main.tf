resource "aws_launch_configuration" "biome5" {
    image_id = "ami-0fb653ca2d3203ac1" # Ubuntu Server 
    instance_type = "t2.micro" # Instance Type Free Tier
    security_groups = [aws_security_group.biome5-sg.id]

  user_data = templatefile("user-data.sh", {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  })

   # Required when using launch configuration with an autoscaling group
   lifecycle {
    create_before_destroy = true
   } 
}

resource "aws_autoscaling_group" "biome5-asg" {
    launch_configuration = aws_launch_configuration.biome5.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    target_group_arns = [aws_lb_target_group.alb-tg.arn]
    health_check_type = "ELB"

    min_size = 2
    max_size = 10

    tag {
      key = "biome5-asg"
      value = "biome5-cluster"
      propagate_at_launch = true
    }
  
}
resource "aws_security_group" "biome5-sg" {
    name = "biome5-sg"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "aws_biome_lb" {
    name = "biome-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb-sg.id]
  
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.aws_biome_lb.arn
    port = 80
    protocol = "HTTP"

    # By default, return a simple 404 page
    default_action {
        type = "fixed-response"

        fixed_response {
          content_type = "text/plain"
          message_body = "404: page not found."
          status_code = 404
        }
    }

}

resource "aws_security_group" "alb-sg" {
    name = "biome5-alb-sg"

    # Allow inbound HTTP requests
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    # Allow all outbound requests
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
resource "aws_lb_target_group" "alb-tg" {
    name = "biome5-alb"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
  
}

resource "aws_lb_listener_rule" "biome-lb-listener" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.alb-tg.arn
    }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}