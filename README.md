# Active Directory & Enterprise Endpoint Hardening Homelab

## Project Overview
This project demonstrates the deployment, configuration, and security hardening of a corporate-grade Active Directory (AD) environment. Built inside an isolated virtual network, this lab simulates real-world enterprise infrastructure; spanning network routing, automated identity management, centralized policy distribution, and defensive endpoint engineering. 

---

## Architectural Blueprint & Objectives
* **Isolated Core Infrastructure:** Configured an enterprise network topology utilizing VirtualBox internal networks bridged securely via a Windows Server NAT gateway.
* **Automated Identity Lifecycle:** Engineered and executed a custom PowerShell script to securely ingest and provision a multi-departmental corporate user directory.
* **Centralized Domain Management:** Implemented consolidated Group Policy Objects (GPOs) leveraging Item-Level Targeting (ILT) for efficient departmental drive mapping.
* **Defensive Endpoint Hardening:** Implemented application control via AppLocker policies to prevent untrusted binary execution and malicious software installation.
## Phase 1: Core Network Infrastructure & Routing

### 1. What Was Built
An isolated enterprise network environment using a dual-homed Windows Server 2022 instance functioning as a network router and NAT gateway, servicing a Windows 11 workstation.

### 2. Objective (Why)
In a real enterprise environment, production servers and domain resources reside on isolated, secure internal networks. However, they still require occasional internet access for updates and external patches. Directly exposing a domain controller to a standard home router or bridged network fractures Active Directory's reliance on private DNS. By building a custom Routing and Remote Access (RRAS) NAT gateway, the lab gains controlled internet access while maintaining strict internal identity and DNS integrity.

### 3. Implementation (How)
Below is the validated proof of the network configuration, showcasing the VirtualBox adapter mappings, active DHCP lease routing, and client-side IP alignment:

* **VirtualBox Network Topology:** 
  ![VirtualBox Network Topology](assets/screenshots/vbox-topology.png)
* **NAT Gateway Routing (RRAS):** 
  ![NAT Gateway Routing](assets/screenshots/rras-routing.png)
* **Automated IP Allocation (DHCP):** 
  ![DHCP Scope Allocation](assets/screenshots/dhcp-scope.png)
* **Client-Side Validation (`ipconfig /all`):** 
  ![Windows 11 IP Configuration](assets/screenshots/win11-ipconfig.png)

### 4. Troubleshooting & Roadblocks
* **The Routing Gateway Gap:** 
  * *The Issue:* The Windows 11 client machine initially showed successful local domain authorization but had zero outbound internet connectivity.
  * *The Resolution:* Diagnosed the network stack on the client using `ipconfig /all`. Discovered the interface default gateway was pointing to the host machine's adapter instead of the Server's LAN IP. Forced the client's Default Gateway to route explicitly through the server's LAN IP interface, restoring full NAT translation.