data "vsphere_distributed_virtual_switch" "homelab" {
  name          = "homelab"
  datacenter_id = data.vsphere_datacenter.garage.id
}

data "vsphere_host" "bourbon" {
  name = "bourbon.${local.subdomain}"
  datacenter_id = data.vsphere_datacenter.garage.id
}

data "vsphere_host" "rye" {
  name = "rye.${local.subdomain}"
  datacenter_id = data.vsphere_datacenter.garage.id
}

locals {
  host_ids = [ data.vsphere_host.bourbon.id, data.vsphere_host.rye.id ]
}

resource "vsphere_distributed_port_group" "tanzu" {
  name                            = "tanzu-pg"
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.homelab.id

  vlan_id = 201
}

resource "vsphere_vnic" "tanzu" {
  count = length(local.host_ids)

  host                    = local.host_ids[count.index]
  distributed_switch_port = data.vsphere_distributed_virtual_switch.homelab.id
  distributed_port_group  = vsphere_distributed_port_group.tanzu.id

  ipv4 {
    dhcp = true
  }

  ipv6 {
    addresses  = []
    autoconfig = false
    dhcp       = false
  }

  netstack = "defaultTcpipStack"
}

