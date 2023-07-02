
resource "google_compute_instance" "windows_vm" {
  name         = "my-windows-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "windows-2019"
    }
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-EOF
    <powershell>
    $secpasswd = ConvertTo-SecureString "Keppel@123" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("admin", $secpasswd)
    Set-LocalUser -Name "admin" -Password $cred.Password -Verbose
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -Verbose
    EOF

#   metadata {
#     windows-startup-script-ps1 = <<-EOF
#       $RdpPort = "3389"
#       Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "PortNumber" -Value $RdpPort
#       New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort $RdpPort -Action Allow
#     EOF
#   }

  tags = ["rdp"]
}

