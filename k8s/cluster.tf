provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "ZODemo-Datacenter02"
}

data "vsphere_datastore" "datastore" {
  name          = "Tintri_ZODemo"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_datastore" "iso_datastore" {
  name          = "Tintri_ISO"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
data "vsphere_resource_pool" "pool" {
  name          = "nVidia-Demo"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
  name          = "Shawn"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
  name          = "GPUDriverTest"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
resource "vsphere_virtual_machine" "vm" {
  count = 3
  name             = "${var.prefix}-${var.vm_name[count.index]}"
  resource_pool_id = "${data.vsphere_resource_pool.pool.id}"
  datastore_id     = "${data.vsphere_datastore.datastore.id}"
  wait_for_guest_net_timeout = 10
  num_cpus = 4
  memory   = 8192
  memory_reservation = 8192
  firmware = "efi"
  guest_id = "ubuntu64Guest"

network_interface {
    network_id = "${data.vsphere_network.network.id}"
  }

  disk {
    label = "disk0"
    size  = 50
  }
  
  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.prefix}-${var.vm_name[count.index]}" 
        domain    = "zodemo.com"
      }
      network_interface {
        ipv4_address = "${var.vm_ips[count.index]}"
        ipv4_netmask = 24
      }
      ipv4_gateway = "10.66.200.254"
      dns_server_list = ["10.66.0.253"]
    }
  }
 # provisioner "local-exec" {
 #   working_dir = "/home/ubuntu/kubeadm-ansible"
 #   command = "ansible-playbook -i hosts.ini site.yaml"
 # }
}
