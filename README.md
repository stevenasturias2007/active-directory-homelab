# Active Directory & Enterprise Endpoint Hardening Homelab

## Project Overview
This project demonstrates the deployment, configuration, and security hardening of a corporate-grade Active Directory (AD) environment. Built inside an isolated virtual network, this lab simulates real-world enterprise infrastructure; spanning network routing, automated identity management, centralized policy distribution, and defensive endpoint engineering. 
## Architectural Blueprint & Objectives
* **Isolated Core Infrastructure:** Configured an enterprise network topology utilizing VirtualBox internal networks bridged securely via a Windows Server NAT gateway.
* **Automated Identity Lifecycle:** Engineered and executed custom PowerShell scripts to securely ingest and provision a multi-departmental corporate user directory.
* **Centralized Domain Management:** Implemented consolidated Group Policy Objects (GPOs) leveraging Item-Level Targeting (ILT) for efficient departmental drive mapping.
* **Defensive Endpoint Hardening:** Implemented application control via AppLocker policies to prevent untrusted binary execution and malicious software installation.
### Software Used
* Oracle VirtualBox (Virtual Machine) 
   * Other VM Software options include: VMWare Workstation Pro, Microsoft Hyper-V, ProxMox Virtual Environment, etc.
* Windows Server 2022 Evaluation ISO
* Windows 11 Enterprise EValuation ISO
## Phase 0: Lab Environment Provisioning & Domain Bootstrap

### 1. What Was Built
A fully isolated virtualized lab environment built on Oracle VirtualBox, provisioned with a Windows Server 2022 Domain Controller and a Windows 11 Enterprise endpoint. This phase covers the foundational groundwork required before any network configuration, identity management, or policy enforcement can occur; from ISO acquisition through Active Directory installation and domain controller promotion.

| Deliverable | Details |
| :--- | :--- |
| **Hypervisor** | Oracle VirtualBox installed on physical host machine |
| **Server VM** | Windows Server 2022 Evaluation — provisioned and activated |
| **Client VM** | Windows 11 Enterprise Evaluation — provisioned and activated |
| **Active Directory** | AD DS role installed and configured on the Server VM |
| **Domain** | Server promoted to Domain Controller for `myhomelab.local` |

---

### 2. Objective (Why)
Before any enterprise security controls or network topology can be implemented, a stable virtualized foundation must exist. Active Directory Domain Services (AD DS) is the identity and authentication backbone of nearly every corporate Windows environment. Promoting a server to a Domain Controller establishes the authoritative root of the `myhomelab.local` domain, the single source of truth for all user accounts, group policies, and resource access enforced in subsequent phases.

---

### 3. Implementation (How)

#### 📂 Step A: Hypervisor Installation
1. Download and install **Oracle VirtualBox** from [virtualbox.org](https://www.virtualbox.org). Accept all default settings during installation.
2. Optionally install the **VirtualBox Extension Pack** for enhanced VM compatibility and USB support.

#### 📂 Step B: ISO Acquisition
1. Download the **Windows Server 2022 Evaluation ISO** from Microsoft's Evaluation Center (180-day free license, no product key required).
2. Download the **Windows 11 Enterprise Evaluation ISO** from Microsoft's Evaluation Center.
3. Store both ISOs in an accessible local directory for VM attachment.

#### 📂 Step C: Windows Server 2022 VM Provisioning
1. In VirtualBox, click **New** and configure the VM with the following recommended baseline specs:

| Setting | Recommended Value |
| :--- | :--- |
| Name | `DomainControllerWIN` |
| Type / Version | Microsoft Windows / Windows 2022 (64-bit) |
| RAM | 2048 MB (2 GB) minimum |
| CPU Cores | 2 |
| Storage | 50 GB dynamically allocated VDI |

2. Under **Storage**, attach the **Windows Server 2022 ISO** to the optical drive controller.
3. Boot the VM and proceed through the Windows Server installation wizard. Select **Windows Server 2022 Standard Evaluation (Desktop Experience)** for a GUI-based environment.
4. Set a strong local Administrator password when prompted.

#### 📂 Step D: Windows 11 Enterprise VM Provisioning
1. In VirtualBox, click **New** and configure the client VM:

| Setting | Recommended Value |
| :--- | :--- |
| Name | `Client01PC` |
| Type / Version | Microsoft Windows / Windows 11 (64-bit) |
| RAM | 4096 MB (4 GB) minimum |
| CPU Cores | 2 |
| Storage | 60 GB dynamically allocated VDI |

2. Attach the **Windows 11 Enterprise ISO** to the optical drive and complete the installation. When prompted for a product key, select **I don't have a product key**.
3. Complete OOBE (Out-of-Box Experience) setup. If the installer requires an internet connection, press `Shift + F10` to open a command prompt and run `OOBE\BYPASSNRO` to bypass the requirement.

#### 📂 Step E: Active Directory Domain Services (AD DS) Installation
1. On the **Windows Server 2022** VM, open **Server Manager**.
2. Click **Add Roles and Features** and proceed through the wizard.
3. Under **Server Roles**, select **Active Directory Domain Services**. Accept any additional feature dependencies when prompted.
4. Complete the wizard and allow the installation to finish.

#### 📂 Step F: Domain Controller Promotion
1. In **Server Manager**, click the notification flag and select **Promote this server to a domain controller**.
2. Select **Add a new forest** and set the Root domain name to `myhomelab.local`.
3. Set the **Forest Functional Level** and **Domain Functional Level** to **Windows Server 2016** or higher.
4. Set a **DSRM (Directory Services Restore Mode)** password and store it securely.
5. Proceed through the wizard, accepting default paths for the NTDS database, SYSVOL, and log files.
6. Allow the prerequisite check to complete, then click **Install**. The server will automatically reboot upon completion.
7. After reboot, log in as `MYHOMELAB\Administrator`. The presence of the domain prefix confirms successful DC promotion.

---

### 4. Verification
To confirm the domain environment is operational before proceeding:
1. Open **Active Directory Users and Computers** (`dsa.msc`) on the Domain Controller and verify the `myhomelab.local` domain tree is present.
2. Open **DNS Manager** and confirm that a forward lookup zone for `myhomelab.local` was automatically created during promotion.
3. Run the following in an elevated PowerShell terminal to validate AD DS health:
```powershell
Get-ADDomain
```
A successful response returns the domain name, domain SID, and infrastructure details, confirming the directory is live and authoritative.

| Component | Software/OS | Purpose |
| :--- | :--- | :--- |
| Hypervisor | Oracle VirtualBox | Lab Abstraction |
| Server OS | Windows Server 2022 | DC & Identity Provider |
| Client OS | Windows 11 | Endpoint Simulation |
| Domain | myhomelab.local | Identity Namespace |

---

## Phase 1: Core Network Infrastructure & Routing

### 1. What Was Built
An isolated enterprise network environment utilizing a dual-homed Windows Server 2022 instance functioning as a core network router and NAT gateway, servicing a downstream Windows 11 enterprise workstation. 

| Asset | Hostname | Operating System | Network Interface 1 (WAN) | Network Interface 2 (LAN) | Primary Roles / Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Domain Controller** | `DomainControllerWIN` | Windows Server 2022 | DHCP (VirtualBox NAT) | Static: `172.16.0.1/24` | AD DS, DNS, DHCP, RRAS (NAT Router) |
| **Workstation** | `Client01PC` | Windows 11 Enterprise | *N/A (Isolated)* | Dynamic (DHCP Leased) | Endpoint Simulation & Policy Enforcement |

---

### 2. Objective (Why)
In a production enterprise environment, domain controllers and internal infrastructure nodes do not directly face the public internet due to threat exposure and the risk of unvetted external packet interaction. Furthermore, exposing a domain controller directly to a standard home router or bridged network fractures Active Directory's strict reliance on isolated private DNS. 

By building a custom **Routing and Remote Access Services (RRAS)** NAT gateway, the lab achieves a secure, modular topology. The internal Windows 11 workstation can safely fetch external resources (such as Windows Updates and administration tools) via address translation, while keeping internal corporate identity traffic and core DNS architecture entirely segmented from the physical home network.

---

### 3. Implementation (How)

To achieve strict isolation while preserving outbound translation, the core infrastructure was built using the following structural stages:

#### 📂 Step A: VirtualBox Virtual Network Architecture
1. Open Oracle VM VirtualBox and navigate to the settings pane for the **Windows Server 2022** VM.
2. Select **Network** and configure **Adapter 1**: Set the attachment type to `NAT` (or `Bridged`) to serve as the external Wide Area Network (WAN) interface.
3. Enable **Adapter 2**: Set the attachment type to `Internal Network` and name the software-defined switch `labnet` to serve as the private Local Area Network (LAN) backbone.
4. Navigate to the **Windows 11 Client** VM settings, select **Network**, and configure **Adapter 1** as `Internal Network` attached to the exact same `labnet` switch. Ensure no other adapters are enabled on the client to guarantee complete network isolation.

![alt text](assets/screenshots/vbox-topology.png)

#### 📂 Step B: Server Interface Structuring & RRAS Virtual Router Installation
1. Log into the Windows Server 2022 instance, open `ncpa.cpl` via the run dialog, and rename the network adapters to `WAN` and `LAN` respectively to prevent operational confusion.
2. Right-click the `LAN` adapter, select **Properties -> IPv4**, and assign a static identity footprint: IP `172.16.0.1`, Subnet Mask `255.255.255.0`, and leave the Default Gateway blank (as this interface *is* the gateway).
3. Open **Server Manager**, click **Add Roles and Features**, and select **Remote Access**. Proceed through the wizard to install the **Routing** role service (which automatically includes DirectAccess and VPN/RRAS dependencies).
4. Once installed, open the **Routing and Remote Access** console. Right-click the server node and select **Configure and Enable Routing and Remote Access**.
5. Select **Network Address Translation (NAT)**, bind the external routing mechanism explicitly to the `WAN` interface, and click Finish to initialize packet forwarding.

![alt text](assets/screenshots/rras-routing.png)

#### 📂 Step C: Enterprise DHCP Scope Provisioning
1. Inside **Server Manager**, open the **DHCP** console tool.
2. Right-click **IPv4**, select **New Scope**, and define the administrative leasing parameters: Name the scope `Internal-Production-LAN` or any other appropriate name and configure the address pool allocation from `172.16.0.50` through `172.16.0.150`.
3. Configure the mandatory **Scope Options** required for automated corporate client domain alignment:
   * **Scope Option 003 (Router):** Set strictly to `172.16.0.1` (the Server's internal LAN IP).
   * **Scope Option 006 (DNS Servers):** Set strictly to `172.16.0.1` (or your domain controller's authoritative DNS identity node).
4. Right-click the newly authored scope and select **Activate**.

![alt text](assets/screenshots/dhcp-scope.png)
![alt text](assets/screenshots/dhcp-scope-range.png)

#### 📂 Step D: Downstream Client Stack Realignment
1. Boot up the Windows 11 workstation endpoint. Ensure its network interface adapter is verified to dynamically grab network configurations (`Obtain an IP address automatically`).
2. Open an elevated PowerShell or Command Prompt terminal window on the client machine.
3. Run `ipconfig /release` followed by `ipconfig /renew` to force a network stack flush and trigger an address allocation request across the internal switch.
4. Run `ipconfig /all` to verify that the workstation successfully leased an address from the server's scope, pulled `172.16.0.1` as its default gateway, and pointed back to the domain controller for its preferred DNS.

![alt text](assets/screenshots/win11-ipconfig.png)

---

### 4. Troubleshooting & Roadblocks

#### The Routing Gateway Gap
* **The Issue:** Following the initial local domain authorization and internal switch configuration, the Windows 11 client workstation could authenticate internally but suffered a total outbound connectivity blackout, preventing connection to external web nodes or updates.
* **The Diagnosis:** Initiated a client-side network review via `ipconfig /all`. Discovered that while the client machine was picking up an internal IP address space, the interface default gateway was completely missing or misconfigured; pulling tracking metrics bound to the host computer's virtualization layer instead of routing through the Server's designated internal interface. 
* **The Resolution:** Remedied the data path inside the Windows Server DHCP console by verifying that **Scope Option 003 (Router)** was explicitly hardcoded and actively broadcasting `172.16.0.1`. Executed an elevated `gpupdate /force` and `ipconfig /renew` on the Windows 11 endpoint to clear out cached lease parameters. The endpoint successfully ingested the updated routing map, establishing stable, transparent Network Address Translation across the custom virtual gateway.

## Phase 2: Automated Identity Lifecycle & Directory Engineering

### 1. What Was Built
A three-stage automated Identity and Access Management (IAM) lifecycle pipeline within the `myhomelab.local` root domain. The infrastructure leverages modular PowerShell engineering to generate mock corporate data, programmatically provision departmental user identities, and dynamically synchronize Role-Based Access Controls (RBAC) across corresponding directory security groups.

| Engineering Stage / Script | Scope / Core Functional Utility | Input Source | Target Output / Action |
| :--- | :--- | :--- | :--- |
| **`generate-users.ps1`** | Data Pipeline Bootstrapping | Synthetic Header Maps | Generates `lab_users_100.csv` |
| **`import-users.ps1`** | Automated Directory Provisioning | `lab_users_100.csv` | Instantiates 100 AD User Objects across OUs |
| **`user-securitygroup-sync.ps1`** | RBAC Group Membership Sync | Active Directory Database | Enforces dynamic security group nesting |

---

### 2. Objective (Why)
Manual creation of user objects, directory containers, and permission assignments within an enterprise environment is inefficient, prone to human error, and completely unscalable. In a real-world enterprise, Identity Lifecycle Management must be programmatic, handling everything from hiring rushes to compliance-driven auditing.

The goal of this phase was to architect a production-grade identity pipeline using **PowerShell**. By creating a multi-tiered Organizational Unit (OU) taxonomy, automating user provisioning, and scripting security group synchronization, the lab simulates real-world enterprise operations. This ensures that 100 distinct identities conform strictly to naming conventions, land in the correct business units, and automatically receive proper group permissions without manual IT intervention.

---

### 3. Implementation (How)

#### 📂 Step A: Organizational Unit (OU) & Security Group Architecture Deployment
1. Log into your Domain Controller (`DomainControllerWIN`), open **Server Manager**, click **Tools**, and select **Active Directory Users and Computers (ADUC)**.
2. Click **View** in the top menu bar and ensure **Advanced Features** is enabled to expose hidden system containers.
3. Right-click the root domain node (`myhomelab.local`), select **New -> Organizational Unit**, and name it `Departments`or whatever name of your choice.
4. Right-click the `Departments` container, and sequentially create individual sub-OUs for each corporate business unit: ,`Finance`, `HR`, `IT`, `Marketing`, `Sales`and any other appropriate business unit.
5. Right-click any individual sub-OU that was created, select **New -> Group**, keep the following selections as is; Group Scope: **Global** and Group Type: **Security**, name the group something such as `GG-Finance-Users` or `GG-Marketing-Users` or whichever way you prefer.

![Active Directory Organizational Departments](assets/screenshots/organizational-units.png)

#### 📂 Step B: Environment & Source Directory Setup
1. All automation components are maintained within the system directory path: `C:\Users\Administrator\Documents\`. (You can choose to save the automation components wherever you want.)
2. Open **Windows PowerShell ISE** as an Administrator on the Domain Controller to manage and run the script pipeline.
![Script Files Organization](assets/screenshots/powershell-workspace.png)

#### 📂 Step C: Executing the 3-Stage Automation Pipeline

##### Stage 1: Dataset Generation (`generate-users.ps1`)
This script bootstraps the process by programmatically generating your 100 random corporate identities, creating standard headers, assigning random departmental tags, and exporting the results into a flat file.

1. On the top left of **Windows PowerShell ISE** click **Open Script** and select the file `generate-users.ps1`
2. Once the script has been opened navigate to the green arrow near the top center and click **Run Script**

```powershell
# Executing this script outputs your local corporate data file:
C:\Users\Administrator\Documents\lab_users_100.csv
```
##### Stage 2: Identity Account Provisioning (`import-users.ps1`)
This script parses the generated CSV, normalizes user attributes, builds standardized lowercase `samAccountNames` (e.g., `first.last`), applies a secure baseline password, and handles OU routing.

1. Open the `import-users.ps1` script and execute it in **Windows PowerShell ISE**
```powershell
# Run the deployment script to ingest data and build Active Directory objects
.\import-users.ps1
```
##### Stage 3: Role-Based Security Group Sync (`user-securitygroup-sync.ps1`)
To ensure compliance with the Principle of Least Privilege, this script audits users across the newly populated OUs and automatically synchronizes them into corresponding Security Groups (e.g., `GG-IT-Users`, `GG-Sales-Users`) for resource access control.

1. Open the `users-securitygroup-sync` to run the synchronization script to bind memberships dynamically:

```powershell
# Run the RBAC syncing tool to automatically update security group memberships
.\user-securitygroup-sync.ps1
```


## Phase 3: Group Policy Management & Endpoint Security Hardening

### 1. What Was Built
A centralized policy management framework using **Group Policy Objects (GPO)** to enforce security standards, dynamic network drive mapping, software whitelisting, and administrative restrictions across the `myhomelab.local` domain.

| Policy Category | Focus Area | Key Configuration Settings |
| :--- | :--- | :--- |
| **Security Baseline** | Password & Account | 10-char complexity, 30-min lockout after 3 failed attempts |
| **Storage Policy** | Dynamic Mapping | Item-Level Targeting (ILT) based on security groups |
| **AppLocker** | Software Whitelisting | Blocked executables in `\Downloads` and `\Temp` |
| **Admin Restrictions**| System Access | Control Panel/Settings lockout for non-IT users |

---

### 2. Objective (Why)
The goal of this phase was to transition from manual workstation configuration to **"Configuration as Code"** at the directory level. By leveraging GPOs, we ensure consistent security posture and environment settings for all users, automatically applied based on their departmental role and group membership.

---

### 3. Implementation (How)

#### 📂 Step A: Domain Security Hardening
Configured domain-wide account policies to enforce strict password complexity (minimum 10 characters) and lockout thresholds. This ensures a consistent security baseline across the entire domain.

![Configured Default Domain Policies](assets/screenshots/default-domain-policies.png)

#### 📂 Step B: Dynamic Network Storage Drive Mapping
1. Architected a centralized `DriveMap-Departments` GPO to deliver unique storage nodes to departmental users.
2. Created individual drive mappings (M, F, S, I, H) corresponding to the Finance, HR, IT, Marketing, and Sales departments.
3. Utilized **Item-Level Targeting (ILT)** for each drive map to ensure security group membership (e.g., `GG-Finance Users`) is validated at login, ensuring users only receive access to their relevant departmental shares.

![Drive Mapping Implementation](assets/screenshots/drive-maps.png)
![Item Level Targeting](assets/screenshots/item-level-targeting.png)

#### 📂 Step C: Endpoint Protection & Control
1. **AppLocker:** Deployed a whitelist policy to block untrusted binaries from vulnerable directories like `\Downloads` or `\Temp`, while allowing core UWP behaviors.
2. **Control Panel Lockout:** Applied an administrative restriction to the standard corporate OUs, preventing access to System Settings, while using security filtering to keep these capabilities available for the `IT Department`.

#### *AppLocker Photo Documentation*
![AppLocker Enforcement](assets/screenshots/applocker-enforcement.png)
![Command Prompt Verification](<assets/screenshots/app-locker-policy in cmdprompt.png>)
![Client Side Verification](assets/screenshots/applocker-blocking.png)
#### *Control Panel Photo Documentation*
![Control Panel Prohibition](assets/screenshots/control-panel-prohibition.png)
![Control Panel Access](assets/screenshots/control-panel-access.png)
![Blocked Control Panel](<assets/screenshots/blocked-control panel.png>)


---

### 4. Verification & Testing
To confirm the policies are active:
1. Open the command prompt on the client workstation and run `gpupdate /force`.
2. Execute `gpresult /r` to generate a report confirming the target GPOs have been successfully applied to the user or machine.

---

### 5. Troubleshooting & Challenges
During the implementation of Group Policy, the following challenges were encountered and resolved:

*   **Policy Propagation Delay:** Policies were not immediately reflecting on the client workstation after creation. 
    *   **Resolution:** Forced a synchronization refresh by running `gpupdate /force` on the endpoint and ensuring the domain controller had successfully replicated the SYSVOL folder changes.
*   **AppLocker Compatibility:** Initial enforcement of AppLocker rules inadvertently blocked critical UWP components, resulting in a non-functional Start Menu.
    *   **Resolution:** Injected "Packaged App Rules" into the default policy database to whitelist essential Windows system binaries while maintaining the restriction on external downloads.
*   **Item-Level Targeting (ILT) Failures:** Network drives were failing to map for specific users despite correct group membership.
    *   **Resolution:** Diagnosed the issue using the GPO 'Settings' report to confirm that the security group was correctly scoped; ensured that 'Authenticated Users' had at least 'Read' access to the GPO to allow processing.

## Conclusion

This homelab project demonstrates the end-to-end engineering of a production-grade enterprise Windows environment, built entirely from scratch inside an isolated virtual network. Across three phases, the lab progressed from bare-metal hypervisor provisioning through network routing, automated identity lifecycle management, and centralized policy enforcement; mirroring the core infrastructure pillars found in real corporate IT environments.

The skills exercised throughout this build include:

| Domain | Demonstrated Competency |
| :--- | :--- |
| **Virtualization** | Oracle VirtualBox network topology, multi-VM orchestration |
| **Networking** | RRAS NAT routing, DHCP scope engineering, DNS architecture |
| **Identity Management** | AD DS, OU taxonomy, PowerShell-automated user provisioning |
| **Security & Compliance** | GPO hardening, AppLocker whitelisting, RBAC group synchronization |
| **Scripting** | Multi-stage PowerShell automation pipeline |

Rather than simply following a tutorial, each phase was deliberately designed to simulate real-world enterprise decision-making; including troubleshooting network routing failures, resolving AppLocker compatibility conflicts, and engineering Item-Level Targeting logic for dynamic drive mapping.

This environment serves as a living foundation, with future phases planned to incorporate SIEM log forwarding, attack simulation, defensive monitoring, and a hybrid identity architecture via Microsoft Entra Connect to bridge the on-premises Active Directory domain with Azure AD.