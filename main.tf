provider "google" {
  credentials = file("optimum-tensor-382601-db1c680ef697.json")
  project     = "optimum-tensor-382601"
  region      = "us-central1"
  zone        = "us-central1-a"
}

resource "google_compute_network" "virtualnetwork" {
  name = "my-network"
}

# Create two subnets within the virtual network
resource "google_compute_subnetwork" "app_subnet" {
  name          = "app-subnet"
  region        = "us-central1"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.0.1.0/24"
}

resource "google_compute_subnetwork" "sql_subnet" {
  name          = "sql-subnet"
  region        = "us-central1"
  network       = google_compute_network.my_network.self_link
  ip_cidr_range = "10.0.2.0/24"
}

# Create Windows application server
resource "google_compute_instance" "app_server" {
  name         = "app-server"
  machine_type = "n1-standard-2"
  zone         = "us-central1-a"
  boot_disk {
    initialize_params {
      image = "windows-2019"
    }
  }
  network_interface {
    network    = google_compute_network.my_network.self_link
    subnetwork = google_compute_subnetwork.app_subnet.self_link
    access_config {
    }
  }
  metadata = {
    windows-startup-script-ps1 = <<-EOT
      # Set the username and password for the Windows VM
      $username = "admin"
      $password = "Password123"
      
      # Create a new local user
      net user $username $password /add
      
      # Add the user to the administrators group
      net localgroup administrators $username /add
    
     #Enable RDP
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    EOT
  }
}

# Create a virtual machine with SQL Server Database Engine 2019
resource "google_compute_instance" "sql_server" {
  name         = "sql-server"
  machine_type = "n1-standard-4"
  zone         = "us-central1-b"
  boot_disk {
    initialize_params {
      image = "windows-2019"
    }
  }
  network_interface {
    network    = google_compute_network.my_network.self_link
    subnetwork = google_compute_subnetwork.sql_subnet.self_link
    access_config {
    }
  }
  metadata = {
    windows-startup-script-ps1 = <<-EOT
      # Set the username and password for the Windows VM
      $username = "sqladmin"
      $password = "Password@123"
      
      # Create a new local user
      net user $username $password /add
      
      # Add the user to the administrators group
      net localgroup administrators $username /add
      
      # Download SQL Server installer
      $url = "https://go.microsoft.com/fwlink/?linkid=866658"
      $outfile = "C:\\SQLServerInstaller.exe"
      Invoke-WebRequest $url -OutFile $outfile
      
      # Install SQL Server Database Engine
      Start-Process -FilePath $outfile -ArgumentList "/QS", "/ACTION=Install", "/FEATURES=SQLEngine", "/INSTANCENAME=MSSQLSERVER", "/SECURITYMODE=SQL", "/SAPWD=Password123" -Wait
     
      #Enable RDP
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    
    
    EOT
  }
}

# Create a firewall rule to allow RDP access to the application server
resource "google_compute_firewall" "app_server_rdp" {
  name    = "app-server-rdp"
  network = google_compute_network.my_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
  //target_tags   = [google_compute_instance.app_server.tags]
}

# Create a firewall rule to allow RDP access to the SQL Server
resource "google_compute_firewall" "sql_server_rdp" {
  name    = "sql-server-rdp"
  network = google_compute_network.my_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"]
 // target_tags   = [google_compute_instance.sql_server.tags]
}
