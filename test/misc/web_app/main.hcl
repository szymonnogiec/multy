config {
  location = "us-east"
  clouds   = ["aws", "azure"]
}
multy "virtual_network" "example_vn" {
  name       = "example_vn"
  cidr_block = "10.0.0.0/16"
}
multy "subnet" "subnet1" {
  name              = "subnet1"
  cidr_block        = "10.0.1.0/24"
  virtual_network   = example_vn
  availability_zone = 1
}
multy "subnet" "subnet2" {
  name              = "subnet2"
  cidr_block        = "10.0.2.0/24"
  virtual_network   = example_vn
  availability_zone = 2
}
multy "subnet" "subnet3" {
  name            = "subnet3"
  cidr_block      = "10.0.3.0/24"
  virtual_network = example_vn
}
multy route_table "rt" {
  name            = "test-rt"
  virtual_network = example_vn
  routes          = [
    {
      cidr_block  = "0.0.0.0/0"
      destination = "internet"
    }
  ]
}
multy route_table_association rta {
  route_table_id = rt.id
  subnet_id      = subnet3.id
}
multy route_table_association rta2 {
  route_table_id = rt.id
  subnet_id      = subnet2.id
}
multy route_table_association rta3 {
  route_table_id = rt.id
  subnet_id      = subnet1.id
}
multy "database" "example_db" {
  name           = "example-db"
  size           = "nano"
  engine         = "mysql"
  engine_version = "5.7"
  storage        = 10
  db_username    = "multyadmin"
  db_password    = "multy$Admin123!"
  subnet_ids     = [
    subnet1.id,
    subnet2.id,
  ]
  clouds         = ["aws"]
}

# [if hosting db on azure]
# FIXME while this adds a dependency to example_db, this is not dependent on azurerm_mysql_virtual_network_rule and azure_mysq_server firewall rules are blocked by default
multy "virtual_machine" "vm" {
  name              = "test-vm"
  os                = "linux"
  size              = "micro"
  user_data         = "#!/bin/bash -xe\nsudo su; yum update -y; curl --silent --location https://rpm.nodesource.com/setup_14.x | bash -; yum -y install git nodejs mysql; git clone https://github.com/FaztTech/nodejs-mysql-links.git; cd nodejs-mysql-links; export DATABASE_HOST='${aws.example_db.host}'; export DATABASE_USER='${aws.example_db.username}'; export DATABASE_PASSWORD='${aws.example_db.password}'; mysql -h $DATABASE_HOST -P 3306 -u $DATABASE_USER --password=$DATABASE_PASSWORD -e 'source database/db.sql'; npm i; npm run build; npm start"
  subnet_id         = subnet3.id
  ssh_key_file_path = "./ssh_key.pub"
  public_ip         = true
}
multy "network_security_group" nsg2 {
  name            = "test-nsg2"
  virtual_network = example_vn
  rules           = [
    {
      protocol   = "tcp"
      priority   = "100"
      action     = "allow"
      from_port  = "80"
      to_port    = "80"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }, {
      protocol   = "tcp"
      priority   = "120"
      action     = "allow"
      from_port  = "22"
      to_port    = "22"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }, {
      protocol   = "tcp"
      priority   = "140"
      action     = "allow"
      from_port  = "443"
      to_port    = "443"
      cidr_block = "0.0.0.0/0"
      direction  = "both"
    }
  ]
}