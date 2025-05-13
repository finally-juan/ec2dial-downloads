# ec2dial

A command-line utility to connect to AWS EC2 instances via SSM using hostname or instance ID.

## Quick Install

Install ec2dial with a single command:

```bash
curl --proto '=https' --tlsv1.2 -LsSf https://raw.githubusercontent.com/finally-juan/ec2dial/main/install.sh | sh
```

The installer will automatically detect your system, download the appropriate binary, verify the checksum, and install it to `/usr/local/bin`.

## Manual Installation

1. Download the appropriate binary for your system from the [releases page](https://github.com/finally-juan/ec2dial/releases/latest)
2. Verify the checksum (SHA256 files are included with each release)
3. Make the binary executable: `chmod +x ec2dial.*`
4. Move to a location in your PATH: `sudo mv ec2dial.* /usr/local/bin/ec2dial`

## Usage

```
ec2dial [options] <hostname|instance-id>

Options:
  -r, --region      AWS region (default: us-east-2)
  -l, --list        List available instances and exit
  -h, --help        This help
  -v, --version     Show version information
```

### Examples

```bash
# Connect to an instance by partial name
ec2dial webserver

# Connect to a specific instance ID
ec2dial i-0123456789abcdef0

# List all available instances
ec2dial --list

# Use a different AWS region
ec2dial --region us-west-2 api-server
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- AWS Session Manager Plugin installed
- Instances configured with SSM Agent
- IAM permissions to use SSM