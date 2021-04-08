provider "vsphere" {
  user = "administrator@crdant.net"
  password  = var.vcenter_password
  vsphere_server = "vcenter.${local.subdomain}"
}
