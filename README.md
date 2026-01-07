# inventoryctl

`inventoryctl` is a CLI tool for safely and consistently managing inventory YAML files, designed to bridge the gap between human-edited configurations and automated processes. It ensures valid syntax, consistent formatting, and facilitates bulk operations and format conversions (e.g., to Ansible inventory or SSH config).

## Installation

### From PyPI

```bash
pipx install inventoryctl
```

### Using uv

```bash
uv tool install inventoryctl
```

## Features

- **CRUD Operations**: Add, update, delete, and get hosts/groups safely.
- **Bulk Sync**: Sync hosts from external JSON/YAML sources (e.g., Terraform outputs, cloud APIs) into your inventory.
- **Validation**: Ensure your inventory follows the required structure.
- **Rendering**: Convert your inventory into Ansible-compatible files or SSH configurations.
- **Formatting**: Canonicalize your YAML files.
- **Metadata Support**: Track source ownership of resources using `_meta` tags to safely mix manual and automated entries.

## Usage

### 1. Resources Management

**Add a Host**
```bash
inventoryctl add host <NAME> <INVENTORY_FILE> --group <GROUP> --ansible-host <IP> [OPTIONS]
```
*Options:*
- `--var key=value`: Set host variables (can be used multiple times).
- `--source <ID>`: Mark this host as managed by a specific source (e.g., `aws`, `terraform`).
- `--force`: Overwrite if exists.
- `--upsert`: Update if exists, create if not.

**Add a Group**
```bash
inventoryctl add group <NAME> <INVENTORY_FILE> [--var key=value]
```

**Update a Host**
```bash
inventoryctl update host <NAME> <INVENTORY_FILE> [OPTIONS]
```
*Options:*
- `--group <GROUP>`: Specify group (required if hostname is ambiguous).
- `--ansible-host <IP>`: Update IP/Hostname.
- `--var key=value`: Update or add variables.
- `--unset-var <KEY>`: Remove variables.

**Delete a Host**
```bash
inventoryctl delete host <NAME> <INVENTORY_FILE> [--group <GROUP>] [--source <ID>]
```

**Get a Host**
```bash
inventoryctl get host <NAME> <INVENTORY_FILE>
```

**List Hosts**
```bash
inventoryctl list hosts <INVENTORY_FILE> [--group <GROUP>] [--source <ID>]
```

### 2. Bulk Operations (Sync)

Sync hosts from an external source (JSON/YAML) into a specific group. This is useful for pipelines filling the inventory.

```bash
inventoryctl sync hosts <INVENTORY_FILE> --group <GROUP> --source <SOURCE_ID> --input <INPUT_FILE> [--prune]
```
- `--input`: Path to a JSON/YAML file containing a list of host objects.
- `--prune`: Remove hosts in the target group/source that are NOT in the input.

**Input Format Example:**
```json
[
  {
    "name": "web-01",
    "ansible_host": "10.0.0.1",
    "vars": { "region": "us-east-1" }
  }
]
```

### 3. Validation & Formatting

**Validate Inventory**
Checks structure and integrity.
```bash
inventoryctl validate <INVENTORY_FILE>
```

**Format Inventory**
Canonicalizes the YAML file (sorting, indentation).
```bash
inventoryctl format <INVENTORY_FILE>
```

### 4. Rendering

**Render for Ansible**
Outputs a clean YAML inventory file compatible with Ansible (strips internal metadata).
```bash
inventoryctl render ansible <INVENTORY_FILE>
```

**Render SSH Config**
Generates an SSH config file based on inventory data (`ansible_host`, `ansible_user`, `ProxyJump`, etc.).
```bash
inventoryctl render ssh <INVENTORY_FILE> > ~/.ssh/config.d/inventory_config
```

## Inventory File Structure

`inventoryctl` manages a YAML file with the following structure:

```yaml
inventory_groups:
  my-group:
    vars:
      ansible_user: ubuntu
    hosts:
      web-01:
        ansible_host: 192.168.1.10
        _meta:
          source: manual
```