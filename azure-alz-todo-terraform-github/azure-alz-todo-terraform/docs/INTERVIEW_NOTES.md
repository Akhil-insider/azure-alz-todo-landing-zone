# Interview Notes

## 90-second walkthrough

“I built a small three-tier ToDo application in Azure. I started with a management-group hierarchy and an audit policy, then created a hub VNet and separate frontend, backend and database spokes. Hub-to-spoke peering provides the topology, while UDRs direct selected traffic through Azure Firewall because VNet peering is not transitive. The frontend VM runs Nginx and serves a React build; `/api` requests are reverse-proxied to FastAPI on a private backend VM. FastAPI connects to Azure SQL through a Private Endpoint, and Private DNS resolves the SQL FQDN to `10.3.1.4`. I validated DNS, TCP 1433, SQL authentication, API CRUD, Nginx proxying and the public custom domain through Application Gateway. HTTP worked; HTTPS configuration remained pending when the Free Trial expired.”

## Questions to prepare

**Why hub-and-spoke?**  
Separates shared connectivity/security from workloads, supports segmentation and centralized inspection.

**Why isn't peering transitive?**  
VNet peering only connects the directly peered VNets; a hub does not automatically route between spokes. Use explicit routing/NVA or another supported connectivity design.

**NAT Gateway vs Application Gateway?**  
NAT Gateway is outbound SNAT for private subnet workloads. Application Gateway is inbound Layer 7 HTTP(S) routing.

**Why Private Endpoint and Private DNS?**  
Private Endpoint provides a private IP path to the Azure service; Private DNS makes the normal FQDN resolve to that private IP from linked networks.

**What does a UDR do?**  
Adds/overrides a route, such as a spoke destination prefix using the firewall private IP as next hop.

**What would you improve?**  
HTTPS and redirect, Key Vault/managed identity, secret rotation, least-privilege NSGs, private admin access, monitoring, cost alerts, Terraform CI checks and remote state.

**What did you actually prove?**  
SQL DNS resolved to `10.3.1.4`; TCP 1433 and SQL login succeeded; API returned HTTP 200; a task persisted; custom domain returned HTTP 200 through the public gateway. HTTPS was not proved.
