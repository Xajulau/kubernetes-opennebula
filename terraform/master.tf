resource "opennebula_virtual_machine" "master" {

  template_id = var.opennebula_template_id

  name = "master"

  cpu    = 1
  memory = 2048
  group  = var.opennebula_group

  context = {
    SSH_PUBLIC_KEY = file("~/.ssh/id_rsa.pub")
  }

  nic {
    model      = "virtio"
    network_id = var.opennebula_network_id
  }

  disk {
    image_id = var.opennebula_image_id
    target   = "vda"
    size     = 8192
  }
}

resource "null_resource" "ansible_master" {
  depends_on = [
    opennebula_virtual_machine.master
  ]

  provisioner "local-exec" {
    command = <<EOT
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook -i "${join(",", [opennebula_virtual_machine.master.nic[0].computed_ip, lookup(var.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "")])}," /ansible/playbook.yml --extra-vars "UBUNTU_RELEASE=${var.ubuntu_release}"
    EOT
  }
}

output "master_ip" {
  value = join(",", [
    opennebula_virtual_machine.master.nic[0].computed_ip,
    lookup(var.ip_publica, opennebula_virtual_machine.master.nic[0].computed_ip, "")
  ])
}