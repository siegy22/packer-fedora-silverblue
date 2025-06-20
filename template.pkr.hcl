packer {
  required_plugins {
    qemu = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

source "qemu" "silverblue" {
  iso_url          = "https://download.fedoraproject.org/pub/fedora/linux/releases/42/Silverblue/x86_64/iso/Fedora-Silverblue-ostree-x86_64-42-1.1.iso"
  iso_checksum     = "sha256:099d6b580b557d5d86c2485b0404119d8e68f90de69ec02c1a2b25c4d4ad7dbc"
  output_directory = "artifacts"
  shutdown_command = "echo 'ansible' | sudo -S shutdown -P now"
  cd_content = {
    "ks.cfg" = templatefile("./ks.pkrtpl.cfg", {
      vm_guest_os_language = var.vm_guest_os_language
      vm_guest_os_keyboard = var.vm_guest_os_keyboard
      vm_guest_os_timezone = var.vm_guest_os_timezone
    })
  }
  ssh_username   = "ansible"
  ssh_password   = "ansible"
  ssh_timeout    = "20m"
  vm_name        = "fedora-silverblue"
  cpus           = 4
  memory         = 8192
  disk_interface = "virtio"
  disk_size      = "50G"
  format         = "qcow2"
  accelerator    = "kvm"
  efi_boot       = true
  boot_wait      = "10s"
  boot_command   = ["<up>e<down><down><end> inst.text inst.ks=cdrom:/ks.cfg<f10>"]
}

build {
  sources = ["source.qemu.silverblue"]

  provisioner "file" {
    source = "ansible-hide-gnome-login"
    destination = "/tmp/ansible-hide-gnome-login"
  }

  provisioner "shell" {
    inline = [
      "sudo cp /tmp/ansible-hide-gnome-login /var/lib/AccountsService/users/ansible",
      # Install cloud-init for VM customization
      "sudo rpm-ostree install cloud-init",
      # Enable third-party repos
      "sudo fedora-third-party enable",
      # Install base software systemwide
      "sudo flatpak install -y --system io.podman_desktop.PodmanDesktop",
      # Setup Gnome Remote Desktop
      "sudo mkdir -p /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop",
      "sudo podman run --rm -v /var/lib/gnome-remote-desktop:/var/lib/gnome-remote-desktop:z docker.io/alpine/openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj /C=CH/ST=Bern/L=Bern/O=IT/CN=gnome-remote-desktop -out /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt -keyout /var/lib/gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.key",
      "sudo chown -R gnome-remote-desktop:gnome-remote-desktop /var/lib/gnome-remote-desktop/",
      "sudo grdctl --system rdp set-tls-key ~gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.key",
      "sudo grdctl --system rdp set-tls-cert ~gnome-remote-desktop/.local/share/gnome-remote-desktop/tls.crt",
      "sudo grdctl --system rdp set-credentials fedora fedora",
      "sudo grdctl --system rdp enable",
    ]
  }

}
