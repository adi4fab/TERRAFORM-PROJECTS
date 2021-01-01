## defining the AWS provider block ##


provider "aws" {
  region = var.region
}

## Defining remote state backend ##

terraform {
  backend "s3" {}
}

## This is to take the values of the outputs defined in the previous layer "Infrastructure" ##

data "terraform_remote_state" "layer1_infrastructure" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = var.remote_state_key
    region = var.region
  }
}

## creating Security groups for ec2 instance ##

resource "aws_security_group" "ec2_public_SG" {
  name        = "ec2-public-SG"
  description = "Allow instance in public subnet to access internet "
  vpc_id      = data.terraform_remote_state.layer1_infrastructure.outputs.vpc_id //taking data from layer1 remote state

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["157.45.172.71/32"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_private_SG" {
  name        = "ec2-private-SG"
  description = "this is SG for instance in private subnet"
  vpc_id      = data.terraform_remote_state.layer1_infrastructure.outputs.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    security_groups = [aws_security_group.ec2_public_SG.id] //the instances in the public sg can access the instance in private subnet
  }


  ingress {
    from_port   = 80 // port 80 for health checking of the instance.
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"] // because its only fo health check
    description = "allow health checking for instances using this SG"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## elastic load balancer SG ##

resource "aws_security_group" "elb_SG" {
  name        = "load balancer sg"
  description = "security group for elb"
  vpc_id      = data.terraform_remote_state.layer1_infrastructure.outputs.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "allow web traffic to load balancer"
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


## creating an IAM role ##
## so that we dont need to provide access and secret keys individually ##

resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2-iam-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":
  [
    {
      "Effect": "Allow",
      "Principal" : {
        "Service" : ["ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


## IAM role policy ##

resource "aws_iam_role_policy" "ec2_Role_policy_iam" {
  name   = "ec2-iam-policy"
  role   = aws_iam_role.ec2_iam_role.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:Describe*",
          "elasticloadbalancing:*",
          "cloudwatch:*",
          "logs:*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
  EOF
}




## IAM instance profile ##
## we will be attaching these to instances ##
## this will attach roles and policy to the instances ##


resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-IAM-Instance-profile"
  role = aws_iam_role.ec2_iam_role.id // here is the mistake its name
}


## dynamically using the AWS AMI ##

data "aws_ami" "ami_launchconfig" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm*"]
  }
}


## Launch config for private ec2 instance##
## with help of this config the instance will be launched ##

resource "aws_launch_configuration" "ec2_private_launch_config" {
  image_id                    = data.aws_ami.ami_launchconfig.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = [aws_security_group.ec2_private_SG.id]

  user_data = <<EOF
    #!/bin/bash
    yum update -y
    yum install httpd2 -y
    service httpd start
    chkconfig httpd on
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1> hello from production backend instance(private) <b>"INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html

  EOF
}

## Launch config for public ec2 instance##

resource "aws_launch_configuration" "ec2_public_launch_config" {
  image_id                    = data.aws_ami.ami_launchconfig.id
  instance_type               = var.instance_type
  key_name                    = var.key_pair
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = [aws_security_group.ec2_public_SG.id]

  user_data = <<EOF
    #!/bin/bash
    yum update -y
    yum install httpd2 -y
    service httpd start
    chkconfig httpd on
    export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
    echo "<html><body><h1> hello from production webapp instance(public) <b>"INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html

  EOF
}


## Public web application load balancer ##

resource "aws_elb" "Public_elb" {
  name            = "Public-ELB"
  internal        = false
  security_groups = [aws_security_group.elb_SG.id]
  subnets = [
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_1_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_2_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_3_id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 3
    interval            = 10
    target              = "HTTP:80/index.html"
    timeout             = 2
    unhealthy_threshold = 5
  }
}


## private backend load balancer ##

resource "aws_elb" "backend_Private_elb" {
  name            = "Backend-Private-ELB"
  internal        = true
  security_groups = [aws_security_group.elb_SG.id]
  subnets = [
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_1_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_2_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_3_id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 3
    interval            = 10
    target              = "HTTP:80/index.html"
    timeout             = 2
    unhealthy_threshold = 5
  }
}


## creating auto scaling groups for private ec2 instances ##

resource "aws_autoscaling_group" "ec2_private_autoscaling_group" {
  name = "Production-backend-autoscaling-group"
  vpc_zone_identifier = [
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_1_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_2_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.private_subnet_3_id
  ]
  max_size = var.max_size
  min_size = var.min_size

  launch_configuration = aws_launch_configuration.ec2_private_launch_config.name
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.backend_Private_elb.name]

  tag {
    key                 = "Name"
    propagate_at_launch = false // this means that these tags will be attached to ec2 instance when they launch
    value               = "Backend-ec2-instances"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "Production-backend"
  }
}


## creating auto scaling groups for public ec2 instances ##


resource "aws_autoscaling_group" "ec2_public_autoscaling_group" {
  name = "Production-webapp-autoscaling-group"
  vpc_zone_identifier = [
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_1_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_2_id,
    data.terraform_remote_state.layer1_infrastructure.outputs.public_subnet_3_id
  ]
  max_size = var.max_size
  min_size = var.min_size

  launch_configuration = aws_launch_configuration.ec2_public_launch_config.name
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.Public_elb.name]

  tag {
    key                 = "Name"
    propagate_at_launch = false // this means that these tags will be attached to ec2 instance when they launch
    value               = "webapp-ec2-instance"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "webapp"
  }
}


## creating auto scaling policy for public instance ##

resource "aws_autoscaling_policy" "webapp-autoscaling-policy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_public_autoscaling_group.name
  name                   = "public-webapp-autoscaling-policy"

  policy_type              = "TargetTrackingScaling"
  min_adjustment_magnitude = 1 // increase or decrease instance count by 1 in tune with autoscaling

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80 //cpu usage
  }
}



## creating auto scaling policy for private instance ##

resource "aws_autoscaling_policy" "backend-autoscaling-policy" {
  autoscaling_group_name = aws_autoscaling_group.ec2_private_autoscaling_group.name
  name                   = "backend-autoscaling-policy"

  policy_type              = "TargetTrackingScaling"
  min_adjustment_magnitude = 1 // increase or decrease instance count by 1 in tune with autoscaling

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80 //cpu usage
  }
}

## SNS topic for autoscaling ##

resource "aws_sns_topic" "webapp_production_autoscaling" {
  name         = "webapp-production-autoscaling"
  display_name = "webapp-production-autoscaling"

}


## SNS subscription ##

resource "aws_sns_topic_subscription" "webapp_production_autoscaling_sms_subscription" {
  topic_arn = aws_sns_topic.webapp_production_autoscaling.arn
  protocol  = "sms"
  endpoint  = var.sns_number
}


## defining auto scaling notifications ##

resource "aws_autoscaling_notification" "notification" {
  group_names = [aws_autoscaling_group.ec2_public_autoscaling_group.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE"
  ]
  topic_arn = aws_sns_topic.webapp_production_autoscaling.arn
}





