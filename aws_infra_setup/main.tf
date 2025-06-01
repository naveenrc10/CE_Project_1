resource "aws_key_pair" "backendMS_key" {
  key_name   = "backendMS"
  public_key = file(var.ssh_key_file_location))
}


resource "aws_iam_role" "backendMS_App_role" {
  name = "backendMS_App_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_instance_profile" "backendMS_App_Profile" {
  name = "backendMS_App_Profile"
  role = aws_iam_role.backendMS_App_role.name
}


resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.backendMS_App_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}



resource "aws_vpc" "backendMS_vpc" {
  cidr_block = "10.0.0.0/24"
  tags = {
    Name = "backendMS-vpc"
  }
}


resource "aws_subnet" "backendMS_subnet1" {
  vpc_id = aws_vpc.backendMS_vpc.id
  cidr_block = "10.0.0.0/25"
  tags = {
    appName = "backendMS"
  }
    availability_zone = "us-east-1a"

}

resource "aws_subnet" "backendMS_subnet2" {
  vpc_id = aws_vpc.backendMS_vpc.id
  cidr_block = "10.0.0.128/25"
  tags = {
    appName = "backendMS"
  }
    availability_zone = "us-east-1b"

}


resource "aws_internet_gateway" "backendMS_igw" {
  vpc_id = aws_vpc.backendMS_vpc.id

  tags = {
    Name = "backendMS-igw"
  }
}
resource "aws_route_table" "backendMS_route_table" {
  vpc_id = aws_vpc.backendMS_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.backendMS_igw.id
  }

  tags = {
    Name = "backendMS"
  }
}


resource "aws_route_table_association" "example_route_table_association" {
  subnet_id      = aws_subnet.backendMS_subnet1.id
  route_table_id = aws_route_table.backendMS_route_table.id
}

resource "aws_route_table_association" "example_route_table_association2" {
  subnet_id      = aws_subnet.backendMS_subnet2.id
  route_table_id = aws_route_table.backendMS_route_table.id
}
resource "aws_security_group" "backendMS_sg" { 
    name = "allow_ssh" 
    description = "Security group to allow SSH access" 
    # Replace with your VPC ID 
    vpc_id = aws_vpc.backendMS_vpc.id
    ingress { 
        from_port = 22 
        to_port = 22 
        protocol = "tcp" 
        cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere; use specific IPs or ranges for better security
    } 
    ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1" 
        # Allows all outbound traffic 
        cidr_blocks = ["0.0.0.0/0"] 
    } 
}

resource "aws_security_group" "backendMS_sg_lb" { 
    name = "allow_8080" 
    description = "Security group to allow SSH access" 
    # Replace with your VPC ID 
    vpc_id = aws_vpc.backendMS_vpc.id
    
    ingress {
    description = "Allow HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress { 
        from_port = 0
        to_port = 0
        protocol = "-1" 
        # Allows all outbound traffic 
        cidr_blocks = ["0.0.0.0/0"] 
    } 
}


resource "aws_launch_template" "backendMS_template" {
  name_prefix =  "BackebackendMS-"
  image_id  = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  key_name = aws_key_pair.backendMS_key.key_name
  user_data = base64encode(file("backendMS-init.sh"))
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.backendMS_sg.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.backendMS_App_Profile.name
  }
  tag_specifications {
    resource_type = "instance"
    tags = {
      appName = "backendMS-instance"
      name = "backendMS-Instance"
    }
  }
 
 
}

resource "aws_lb" "backendMS_lb" {
  name               = "backendMS-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backendMS_sg_lb.id]
  subnets            = [aws_subnet.backendMS_subnet1.id,aws_subnet.backendMS_subnet2.id]
}

resource "aws_lb_listener" "backendMS_listener" {
  load_balancer_arn = aws_lb.backendMS_lb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backendMS_tg.arn
  }
}

resource "aws_lb_target_group" "backendMS_tg" {
    name = "backendms"
    port = 8080
    protocol = "HTTP"
    vpc_id = aws_vpc.backendMS_vpc.id
    health_check {
        path                = "/api/hello"
        protocol            = "HTTP"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 2
    }

}


resource "aws_autoscaling_group" "backendMS_acg"{
  name = "backendMS_acg"
  desired_capacity     = var.instance_count
  max_size             = var.instance_count
  min_size             = 1
  target_group_arns    = [aws_lb_target_group.backendMS_tg.id]
  launch_template {
    id      = aws_launch_template.backendMS_template.id
    version = aws_launch_template.backendMS_template.latest_version
  }
  vpc_zone_identifier = [aws_subnet.backendMS_subnet1.id,aws_subnet.backendMS_subnet2.id]
  
}


/*
  
  vpc_zone_identifier = [aws_subnet.nginx_subnet.id]  # Replace with your subnet ID
}*/
/*
resource "aws_instance" nginx_server{
 ami = "ami-04b4f1a9cf54c11d0"
 instance_type = "t2.micro"
 key_name = aws_key_pair.nginx_key.key_name
 provisioner "remote-exec" {
    inline = ["echo Hello, World!"]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("mykey")
      host        = self.public_ip
    }
  }
  provisioner "local-exec" {
    command = <<EOT
    echo ${self.public_ip} > public_ip.txt
    EOT
  }
 security_groups = [aws_security_group.nginx_sg.name]
}
*/