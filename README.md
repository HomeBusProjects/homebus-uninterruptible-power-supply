# Homebus Uinterruptible Power Supply Publisher

This is a simple Homebus data source which queries a UPS using SNMP
and publishes its curent status.

## Usage

On its first run, `homebus-uninterruptible-power-supply` needs to know how to find the Homebus provisioning server.

```
bundle exec homebus-uninterruptible-power-supply -b homebus-server-IP-or-domain-name -P homebus-server-port
```

The port will usually be 80 (its default value).

Once it's provisioned it stores its provisioning information in `.env.provisioning`.

`homebus--uninterruptible-power-supply` also needs to know:

- the IP address or name of the router it's monitoring
- the interface name or IP address of the network interface it's monitoring
- the SNMP community string (default: 'public') for the router

```
homebus-uninterruptible-power-supply -a ups-IP-or-name -c community-string
```

## Configuration

Edit `.env` to include the following:
```
SNMP_AGENT_NAME=10.0.1.54
SNMP_COMMUNITY_STRING=public
```

`SNMP_AGENT_NAME` should be the IP address or name of the UPS
`SNMP_COMMUNITY_STRING` shoudl be the community string used to gain access to the UPS' data (often `public`).
