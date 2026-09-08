# inventory file Ansible

resource "local_file" "inventory" {
  filename = "${path.module}/ansible/inventory.ini"

  content = <<-EOF
[web]
${yandex_compute_instance.vm[0].network_interface[0].nat_ip_address}
${yandex_compute_instance.vm[1].network_interface[0].nat_ip_address}

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/root/.ssh/id_ed25519_nopass
ansible_python_interpreter=/usr/bin/python3
EOF
}
