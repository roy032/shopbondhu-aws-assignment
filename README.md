# ShopBondhu: Launch Day (Module 3 assignment)

> **DRAFT: not ready to submit.** The AWS resources have not been created yet, so there are no screenshots
> and `commands.md` is empty. The assignment requires real console and terminal screenshots with the AWS
> account name and region visible. Do not submit until those exist.

## Architecture

```
Internet
   |
[ shopbondhu-igw ]
   |
shopbondhu-vpc 10.0.0.0/16
 |- shopbondhu-public-subnet 10.0.1.0/24  -> shopbondhu-public-rt (0.0.0.0/0 -> IGW)
 |     |- shopbondhu-web (Ubuntu, Nginx, public IP)
 |     |- shopbondhu-nat (Elastic IP)
 |- shopbondhu-private-subnet 10.0.2.0/24 -> shopbondhu-private-rt (0.0.0.0/0 -> NAT)
       |- shopbondhu-backend (Ubuntu, no public IP)
```

## Tasks 1 to 8

Created with `scripts/provision.sh` (AWS CLI) and `scripts/web-setup.sh`; every command that is actually run
must be copied into `commands.md` in order, with its screenshot in `screenshots/`.

## Task 9: Why the backend cannot be reached from my laptop

The backend sits in a private subnet. Its route table sends internet-bound traffic out through the NAT Gateway,
but has **no route from the internet in**: there is no Internet Gateway route and the instance has no public IP.
A NAT Gateway only allows connections that start inside the VPC. Its security group also allows SSH only from
the web server's security group. So `ssh` or `ping` from my laptop times out, while the web server (the bastion)
can reach it by private IP, and the backend can still run `sudo apt update` and `curl -I https://google.com`
through the NAT.

## Task 10: Troubleshooting

### Problem A: "The website doesn't open in the browser, but SSH to the web server works"

1. **Security group has no HTTP rule.** SSH (22) works but port 80 is not open to `0.0.0.0/0`. Check: EC2 console, instance, Security tab, inbound rules; fix by adding HTTP 80 from `0.0.0.0/0`.
2. **Nginx is not running or not enabled.** Check: `sudo systemctl status nginx` and `sudo ss -tlnp | grep :80`; fix with `sudo systemctl enable --now nginx`.
3. **Files are in the wrong place or empty.** Nginx serves `/var/www/html`. Check: `ls -l /var/www/html` and `sudo nginx -t`; copy the frontend there and reload.
4. **Wrong public IP or `https://`.** The instance was stopped and restarted (new IP) or I opened `https://` instead of `http://`. Check the current public IP in the console.
5. **Subnet routing.** The public route table lacks `0.0.0.0/0 -> shopbondhu-igw`, or is not associated with the public subnet. (SSH working makes this unlikely, but I would check it.)

### Problem B: "On the backend, `sudo apt update` hangs and times out"

1. **NAT Gateway is in the wrong subnet.** It must be in the **public** subnet; one in the private subnet has no path to the Internet Gateway. Check the NAT gateway's subnet.
2. **Private route table has no `0.0.0.0/0 -> shopbondhu-nat` route**, or is not associated with the private subnet. Check Route tables, Routes and Subnet associations.
3. **NAT Gateway has no Elastic IP, or is not in the `available` state.** Check its status and allocated EIP.
4. **The public subnet's route table has no route to the Internet Gateway**, so the NAT cannot reach the internet. Check `shopbondhu-public-rt`.
5. **Backend security group or network ACL blocks outbound traffic.** Check the outbound rules (default allows all) and NACLs.

## Cleanup

The NAT Gateway and Elastic IP are billed hourly. Run `scripts/cleanup.sh` when the assignment is done.
