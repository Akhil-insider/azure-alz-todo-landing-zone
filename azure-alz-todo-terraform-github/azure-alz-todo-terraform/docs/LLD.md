# Low-Level Design (LLD)

## 1. Naming and resource grouping

| Item | Name |
|---|---|
| Resource group | `Hub-Spoke-Lab-RG` |
| Hub | `HubVnet` |
| Frontend spoke | `Spoke-FE-Vnet` |
| Backend spoke | `Spoke-BE-VNet` |
| Database spoke | `Spoke-DB-VNet` |
| Firewall | `Hub-AzureFirewall` |
| Frontend VM | `Todofevm` |
| Backend VM | `Todobevm` |
| SQL server/database | `tododbsrv` / `TodoDB` |
| SQL private endpoint | `pe-todo-sql` |
| SQL private DNS zone | `privatelink.database.windows.net` |
| Application Gateway | `agw-todo-prod` |
| Domain | `todo.akhillabs.in` |

## 2. Management groups and policy

- Tenant Root Group
  - Landing Zones (`mg-landing-zones`) → `Azure subscription 1`
  - Platform (`mg-platform`)
    - Connectivity
    - Identity
    - Management
  - Sandbox (`mg_Sandbox`)
- Built-in policy `Audit VMs that do not use managed disks`, assignment `audit-vm-managed-disks-landing-zones`, assigned to Landing Zones.
- Reported compliance at one point: 3/3 compliant. This is time-specific evidence, not a guarantee of current compliance.

Management-group creation and subscription move are privileged tenant/subscription operations. Terraform support is available but should be applied by a suitably privileged identity and separated from workload deployment.

## 3. Subnets

| VNet | Subnet | CIDR | Association |
|---|---|---|---|
| HubVnet | AzureBastionSubnet | `10.0.1.0/26` | Reserved; Bastion not deployed |
| HubVnet | AzureFirewallSubnet | `10.0.2.0/26` | Azure Firewall |
| HubVnet | ApplicationGWSubnet | `10.0.3.0/24` | Application Gateway |
| HubVnet | SharedSubnet | `10.0.4.0/24` | Shared |
| Spoke-FE-Vnet | Subnet-FE | `10.1.1.0/24` | Frontend VM, FE NSG, NAT (verify current association) |
| Spoke-BE-VNet | Subnet-BE | `10.2.1.0/24` | Backend VM, BE NSG, NAT, `rt-spoke-be` |
| Spoke-DB-VNet | Subnet-DB | `10.3.1.0/24` | SQL Private Endpoint, DB NSG, `rt-spoke-db` |

## 4. Network security groups

| NSG | Rule | Priority | Source | Protocol/port | Intended use |
|---|---|---:|---|---|---|
| `nsg-spoke-fe` | `Allow-HTTP-From-AppGW` | 200 | `10.0.3.0/24` | TCP/80 | Gateway to Nginx |
| `nsg-spoke-fe` | `Allow-My-IP-HTTP-Test` | 190 reported | `42.104.224.12/32` | TCP/80 | Temporary direct test; remove |
| `nsg-spoke-be` | `Allow-FE-to-BE-8000` | 200 | `10.1.1.0/24` | TCP/8000 | FE reverse proxy to API |
| `nsg-spoke-db` | No custom inbound rule recorded | — | — | — | Verify current effective rules |

A screenshot also showed a broad priority-100 rule named `rule`, source `Any`, port 80. Remove it if it remains. Keep only the Application Gateway subnet source for inbound FE HTTP.

## 5. Firewall and UDRs

- Firewall: `Hub-AzureFirewall`, Premium, private IP `10.0.2.4`.
- Network rule collection: `Allow-BE-to-SQL`, priority 200, action Allow.
- Rule: `BE-to-SQL-1433`, source `10.2.1.0/24`, protocol TCP, destination `10.3.1.4`, port 1433.
- `rt-spoke-be`: destination `10.3.1.0/24`, next hop `Virtual appliance`, address `10.0.2.4`, associated to `Subnet-BE`.
- `rt-spoke-db`: destination `10.2.1.0/24`, next hop `Virtual appliance`, address `10.0.2.4`, associated to `Subnet-DB`.
- A frontend route `10.2.1.0/24 -> 10.0.2.4` was shown during the lab; verify if still needed and whether the route/return path is correct.

Validation evidence: backend DNS lookup resolved `tododbsrv.database.windows.net` to `10.3.1.4`; TCP 1433 connected; SQL login succeeded. Verify effective routes and actual traffic path before making a strong claim that all flows are inspected.

## 6. SQL private connectivity

- SQL FQDN: `tododbsrv.database.windows.net`
- Database: `TodoDB`; logical server region Central US
- Private Endpoint: `pe-todo-sql`, private IP `10.3.1.4`, subnet `Subnet-DB`
- Private DNS Zone: `privatelink.database.windows.net`
- VNet links: `Spoke-DB-VNet` and `Spoke-BE-VNet`
- Backend uses the normal SQL FQDN, not the private IP directly.
- ODBC Driver 18 installed on Ubuntu 24.04; Python `pyodbc` used by FastAPI.

## 7. Application layer

### Frontend
- VM `Todofevm`, Ubuntu 24.04, `10.1.1.4`
- Nginx 1.24 serves React build from `/var/www/todo-app`
- SPA fallback: `try_files $uri $uri/ /index.html`
- `/api/` is reverse-proxied to `http://10.2.1.4:8000`

### Backend
- VM `Todobevm`, Ubuntu 24.04, `10.2.1.4`
- Repository `https://github.com/devopsinsiders/PyTodoBackendMonolith.git`
- App directory `/opt/todo-backend/repo`
- Virtual environment `/opt/todo-backend/repo/.venv`
- Uvicorn listens on `0.0.0.0:8000`
- Log file `/var/log/todo-backend.log`
- `.env` contains `CONNECTION_STRING` with mode 600; no secret belongs in Git.
- Routes tested: `/api`, `/api/tasks`, `/api/tasks/{task_id}`, POST/PUT/DELETE task operations.

### Application Gateway and DNS
- Gateway `agw-todo-prod`, Standard_v2, subnet `ApplicationGWSubnet`
- Public IP `20.81.66.210`
- Backend pool `pool-todo-frontend`
- Listener `listener-todo-http`, HTTP/80
- Rule `rule-todo-http`, priority 100
- Backend setting `http-backend-80`, port 80
- GoDaddy A record host `todo` → `20.81.66.210`
- `curl.exe -I http://todo.akhillabs.in` returned HTTP 200; React UI rendered.
- HTTPS certificate/listener and redirect are pending.

## 8. Validation matrix

| Test | Expected / observed |
|---|---|
| Policy compliance | 3/3 compliant at time of test |
| Hub-spoke peering | Connected/synchronized |
| SQL DNS from BE | `10.3.1.4` |
| TCP SQL | `TCP_CONNECTED` on 1433 |
| SQL login | `SQL_LOGIN_SUCCESS`, `TodoDB` |
| Backend `/api/tasks` | HTTP 200 |
| Nginx `/api/tasks` | HTTP 200 |
| Create and list task | Persisted in SQL and displayed in UI |
| Domain HTTP | `todo.akhillabs.in` → `20.81.66.210`, HTTP 200 |
| HTTPS | Not configured/tested |
