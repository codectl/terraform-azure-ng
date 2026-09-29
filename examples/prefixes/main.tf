module "naming" {
  source  = "codectl/naming/azure"
  version = "~> 0.1"

  suffix = ["demo", "dev"]
}

module "regions" {
  source  = "codectl/locations/azure"
  version = "~> 1.0"

  location = {
    primary = "germanywestcentral"
  }
}

module "rg" {
  source  = "codectl/rg/azure"
  version = "~> 1.0"

  groups = {
    demo = {
      name     = module.naming.resource_group.name_unique
      location = module.regions.location.primary.name
    }
  }
}

module "network" {
  source  = "codectl/vnet/azure"
  version = "~> 1.0"


  vnet = {
    name                = module.naming.virtual_network.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    address_space       = ["10.0.0.0/16"]
    dns_servers         = ["8.8.8.8", "7.7.7.7"]

    subnets = {
      sn1 = {
        address_prefixes = ["10.0.1.0/24"]
      }
    }
  }
}

module "prefixes" {
  source  = "codectl/pip/azure//modules/prefixes"
  version = "~> 1.0"

  resource_group_name = module.rg.groups.demo.name
  location            = module.rg.groups.demo.location

  public_ip_prefixes = {
    prefix1 = {
      name          = "${module.naming.public_ip_prefix.name}1"
      prefix_length = 31
      zones         = ["1", "2", "3"]
    }
    prefix2 = {
      name          = "${module.naming.public_ip_prefix.name}2"
      prefix_length = 31
      zones         = ["1", "2", "3"]
    }
  }
}

module "natgw" {
  source  = "codectl/ng/azure"
  version = "~> 1.0"

  nat_gateway = {
    name                = module.naming.nat_gateway.name
    location            = module.rg.groups.demo.location
    resource_group_name = module.rg.groups.demo.name
    associations = {
      subnets = {
        sn1 = {
          subnet_id = module.network.subnets.sn1.id
        }
      }
      public_ip_prefixes = {
        prefix1 = {
          public_ip_prefix_id = module.prefixes.public_ip_prefixes.prefix1.id
        }
        prefix2 = {
          public_ip_prefix_id = module.prefixes.public_ip_prefixes.prefix2.id
        }
      }
    }
  }
}