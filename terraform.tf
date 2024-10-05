
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
  key_name = aws_key_pair.cloud2.key_name

  tags = {
    Name = "CarlosJ"
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

