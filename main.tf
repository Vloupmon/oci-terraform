provider "oci" {
  fingerprint      = var.fingerprint
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  private_key_path = var.private_key_path
}

data "oci_identity_availability_domain" "ad" {
  compartment_id = var.tenancy_ocid
  ad_number      = 1
}

// Networking
resource "oci_core_virtual_network" "vcn" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "VCN"
  dns_label      = "vcn"
}

resource "oci_core_subnet" "subnet" {
  cidr_block        = "10.1.20.0/24"
  display_name      = "Subnet"
  dns_label         = "subnet"
  security_list_ids = [oci_core_security_list.security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  route_table_id    = oci_core_route_table.route_table.id
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = "IG"
  vcn_id         = oci_core_virtual_network.vcn.id
}

resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "RouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

// Firewall rules
// See https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
// for protocol numbers
//
// TCP = 6
// UDP = 17
resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "SecurityList"

  egress_security_rules {
    protocol    = "6"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "SSH"

    tcp_options {
      min = "22"
      max = "22"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTP"

    tcp_options {
      min = "80"
      max = "80"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTPS"

    tcp_options {
      min = "443"
      max = "443"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "Caddy HTTP"

    tcp_options {
      min = "8080"
      max = "8080"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "Caddy HTTPS"

    tcp_options {
      min = "4443"
      max = "4443"
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    description = "Torrent DHT"

    udp_options {
      min = "6881"
      max = "6881"
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "Torrent TCP"

    tcp_options {
      min = "6890"
      max = "6999"
    }
  }
}

// Compute
resource "oci_core_instance" "free_instance" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  display_name        = "freeInstance"
  shape               = var.instance_shape

  shape_config {
    ocpus         = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = true
    hostname_label   = "freeinstance"
  }

  source_details {
    source_type = "image"
    source_id   = lookup(data.oci_core_images.images.images[0], "id")
  }

  metadata = {
    ssh_authorized_keys = (var.ssh_public_key != "") ? file(var.ssh_public_key) : tls_private_key.compute_ssh_key[0].public_key_openssh
  }
}

output "compute_instance_ip" {
  value = oci_core_instance.free_instance.public_ip
}

// Generate a pair for authentication if none is provided
resource "tls_private_key" "compute_ssh_key" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

output "generated_private_key_pem" {
  value     = (var.ssh_public_key != "") ? var.ssh_public_key : tls_private_key.compute_ssh_key[0].private_key_pem
  sensitive = true
}

// Pick up the last Oracle Linux image for provisioning
# See https://docs.oracle.com/iaas/images/
data "oci_core_images" "images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}
