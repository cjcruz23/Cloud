
# Creación de la VPC
resource "aws_vpc" "cloud_vpc" {
  cidr_block = "70.0.0.0/16"  # Rango de IP para la VPC
  enable_dns_support = true    # Habilitar soporte DNS
  enable_dns_hostnames = true   # Habilitar nombres de host DNS

  tags = {
    Name = "cloud_vpc"         # Etiqueta para la VPC
  }
}

# Subredes públicas

# Primera subred pública
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.cloud_vpc.id  # ID de la VPC donde se crea la subred
  cidr_block        = "70.0.1.0/24"           # Rango de IP para la subred pública 1
  availability_zone = "us-east-1a"            # Zona de disponibilidad

  

  tags = {
    Name = "public_subnet_1"  # Etiqueta para la subred pública 1
  }
}

# Segunda subred pública
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.cloud_vpc.id  # ID de la VPC donde se crea la subred
  cidr_block        = "70.0.2.0/24"           # Rango de IP para la subred pública 2
  availability_zone = "us-east-1b"            # Zona de disponibilidad

  

  tags = {
    Name = "public_subnet_2"  # Etiqueta para la subred pública 2
  }
}

# Subredes privadas

# Primera subred privada
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.cloud_vpc.id  # ID de la VPC donde se crea la subred
  cidr_block        = "70.0.3.0/24"           # Rango de IP para la subred privada 1
  availability_zone = "us-east-1a"            # Zona de disponibilidad

  
  tags = {
    Name = "private_subnet_1" # Etiqueta para la subred privada 1
  }
}

# Segunda subred privada
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.cloud_vpc.id  # ID de la VPC donde se crea la subred
  cidr_block        = "70.0.4.0/24"           # Rango de IP para la subred privada 2
  availability_zone = "us-east-1b"            # Zona de disponibilidad

  

  tags = {
    Name = "private_subnet_2" # Etiqueta para la subred privada 2
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cloud_vpc.id  # ID de la VPC a la que se asocia el gateway

  tags = {
    Name = "internet_gateway"    # Etiqueta para el Internet Gateway
  }
}

# Tabla de enrutamiento para subredes públicas
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.cloud_vpc.id  # ID de la VPC a la que pertenece la tabla de enrutamiento

  route {
    cidr_block = "0.0.0.0/0"        # Ruta para todo el tráfico saliente
    gateway_id = aws_internet_gateway.igw.id  # ID del Internet Gateway
  }

  tags = {
    Name = "public_route_table"    # Etiqueta para la tabla de enrutamiento pública
  }
}

# Asociación de la tabla de enrutamiento a la subred pública 1
resource "aws_route_table_association" "public_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id  # ID de la subred pública 1
  route_table_id = aws_route_table.public_rt.id    # ID de la tabla de enrutamiento pública
}

# Asociación de la tabla de enrutamiento a la subred pública 2
resource "aws_route_table_association" "public_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id  # ID de la subred pública 2
  route_table_id = aws_route_table.public_rt.id    # ID de la tabla de enrutamiento pública
}
# Creacion de EC2

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Crear una clave SSH
resource "aws_key_pair" "cloud2" {
  key_name   = "cloud2-key"
  public_key = file("~/.ssh/id_rsa.pub") # Ruta de tu clave pública SSH
}

# Crear una instancia EC2 asociada a la subred de la VPC
resource "aws_instance" "CarlosJ" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_1.id
  key_name      = aws_key_pair.cloud2.key_name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    echo "<html><h1>Carlos 1</h1></html>" > /var/www/html/index.html
  EOF

    tags = {
    Name = "CarlosJ"
  }
}

# Crear una instancia EC2 asociada a la subred de la VPC
resource "aws_instance" "CarlosJ2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet_2.id
  key_name = aws_key_pair.cloud2.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update -y
    sudo apt-get install -y nginx
    sudo systemctl start nginx
    echo "<html><h1>Carlos 2</h1></html>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "CarlosJ2"
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id      = aws_vpc.cloud_vpc.id
  name        = "allow_ssh"
  description = "Permitir SSH a EC2"

  # Permitir tráfico SSH (puerto 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acceso SSH desde cualquier lugar (puedes restringir)
  }

  # Permitir tráfico SSH (puerto 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permitir acceso SSH desde cualquier lugar (puedes restringir)
  }

  # Reglas de salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# Crear un Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.instance_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "app_lb"
  }
}

# Crear un target group para las instancias EC2
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloud_vpc.id

   health_check {
    path = "/"
    protocol = "HTTP"
    interval = 5      
    timeout  = 2
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app_tg"
  }
}

# Asignar las instancias EC2 al target group
resource "aws_lb_target_group_attachment" "ec2_attachment_1" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.CarlosJ.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_attachment_2" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.CarlosJ2.id
  port             = 80
}

# Crear un listener para el ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name = "app_listener"
  }
}

# Crear un grupo de subredes para RDS
resource "aws_db_subnet_group" "subredes" {
  name       = "cloudsubredes"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  tags = {
    Name = "cloudsubredes"
  }
}

# Crear una base de datos RDS MySQL
resource "aws_db_instance" "app_db" {
  identifier        = "app-db-instance"
  allocated_storage = 20
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  db_name              = "cloud2024"
  username          = "admin"
  password          = "Admin2024"
  db_subnet_group_name = aws_db_subnet_group.subredes.name
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  skip_final_snapshot = true

  tags = {
    Name = "app_db"
  }
}

output "alb_dns_name" {
  value = aws_lb.app_lb.dns_name
}


