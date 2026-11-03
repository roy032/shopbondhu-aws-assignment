# commands.md

Commands actually run, in order, in AWS CloudShell (region ap-southeast-2). Output of the first command is in
`screenshots/01-cloudshell-identity-and-clone.jpg`.

```bash
git clone https://github.com/roy032/shopbondhu-aws-assignment.git && cd shopbondhu-aws-assignment && aws sts get-caller-identity && aws configure list | head -4
bash scripts/provision.sh 2>&1 | tee ~/provision.log     # Tasks 1-6: VPC, subnets, IGW, NAT, route tables, SGs, 2 EC2
aws ec2 describe-instances ...                              # looked up the web public IP and backend private IP
scp / ssh to shopbondhu-web to run scripts/web-setup.sh     # Tasks 7-8 attempted; result not verified
```

Cleanup afterwards (to stop charges):

```bash
aws ec2 terminate-instances ...; aws ec2 delete-nat-gateway ...; aws ec2 release-address ...
aws ec2 delete-security-group / delete-subnet / delete-route-table / delete-internet-gateway / delete-vpc ...
```
