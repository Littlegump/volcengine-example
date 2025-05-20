# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }



variable "ak" { }
variable "sk" { }
provider "volcengine" {
  access_key = var.ak
  secret_key = var.sk
  region = var.volc_region
}

# 查询region中的azs
data "volcengine_zones" "foo" {
}

resource "volcengine_vpc" "foo" {
  vpc_name = "ykx-test-vpc"
  cidr_block = var.vpc_cidr_block
}

resource "volcengine_subnet" "web" {
  subnet_name = "sn-web-A"
  cidr_block  = "10.16.0.0/20"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "app" {
  subnet_name = "sn-app-A"
  cidr_block  = "10.16.16.0/20"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "db" {
  subnet_name = "sn-db-A"
  cidr_block  = "10.16.32.0/20"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "spare" {
  subnet_name = "sn-spare-A"
  cidr_block  = "10.16.48.0/20"
  zone_id     = data.volcengine_zones.foo.zones[0].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "web-B" {
  subnet_name = "sn-web-B"
  cidr_block  = "10.16.64.0/20"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "app-B" {
  subnet_name = "sn-app-B"
  cidr_block  = "10.16.80.0/20"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "db-B" {
  subnet_name = "sn-db-B"
  cidr_block  = "10.16.96.0/20"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_subnet" "spare-B" {
  subnet_name = "sn-spare-B"
  cidr_block  = "10.16.112.0/20"
  zone_id     = data.volcengine_zones.foo.zones[1].id
  vpc_id      = volcengine_vpc.foo.id
}

resource "volcengine_security_group" "foo" {
  security_group_name = "sg-web-A"
  vpc_id              = volcengine_vpc.foo.id
}

# resource "volcengine_security_group_rule" "allowssh" {
#   direction         = "ingress"
#   security_group_id = volcengine_security_group.foo.id
#   protocol          = "tcp"
#   port_start        = 22
#   port_end          = 22
#   cidr_ip           = "0.0.0.0/0"
#   priority          = 1
#   policy            = "accept"
#   description       = "allow ssh login"
# }


# 请求 匹配指定实例类型的 image_id， 
data "volcengine_images" "foo" {
  os_type          = "Linux"
  visibility       = "public"
  instance_type_id = "ecs.g1ie.large"
}

// create ecs instance
resource "volcengine_ecs_instance" "foo" {
  instance_name        = "ykx-test-ecs"
  # description          = "ykx-test"
  # host_name            = "ykx-test" # 可选
  image_id             = data.volcengine_images.foo.images[0].image_id
  instance_type        = data.volcengine_images.foo.instance_type_id
  # password             = "93f0cb0614Aab12"
  key_pair_name        = "key-for-ykx" 
  instance_charge_type = "PostPaid"
  system_volume_type   = "ESSD_PL0"
  system_volume_size   = 40
  subnet_id            = volcengine_subnet.web.id
  security_group_ids   = [volcengine_security_group.foo.id]
  project_name         = "default"
  tags {
    key   = "env"
    value = "test"
  }
}

resource "volcengine_eip_address" "foo" {
  billing_type = "PostPaidByBandwidth"  # | PostPaidByTraffic  (按带宽上限，按实际流量)
  bandwidth    = 1    # metric is Mbps
  # the value can be BGP or ChinaMobile or ChinaUnicom or ChinaTelecom or SingleLine_BGP or Static_BGP or Fusion_BGP.
  isp          = "BGP"
  name         = "ykx-test-eip1"
  description  = "acc-test"
  project_name = "default"
  tags {
    key = "env"
    value = "test"
  }
}
resource "volcengine_eip_associate" "foo" {
  allocation_id = volcengine_eip_address.foo.id
  instance_id   = volcengine_ecs_instance.foo.id
  instance_type = "EcsInstance"  # 可以是Nat, NetworkInterface or ClbInstance or EcsInstance or HaVip
}