#!/usr/bin/env bash
# Builds the ShopBondhu network and servers with the AWS CLI (Tasks 1-6).
# Run ONLY with your own AWS account configured (`aws configure`). The NAT gateway
# and Elastic IP cost money while they exist: run scripts/cleanup.sh when finished.
set -euo pipefail
REGION="${AWS_REGION:-ap-southeast-1}"
MYIP="$(curl -s https://checkip.amazonaws.com)/32"
tag() { echo "ResourceType=$1,Tags=[{Key=Name,Value=$2}]"; }

VPC=$(aws ec2 create-vpc --region $REGION --cidr-block 10.0.0.0/16 --tag-specifications "$(tag vpc shopbondhu-vpc)" --query Vpc.VpcId --output text)
PUB=$(aws ec2 create-subnet --region $REGION --vpc-id $VPC --cidr-block 10.0.1.0/24 --tag-specifications "$(tag subnet shopbondhu-public-subnet)" --query Subnet.SubnetId --output text)
PRV=$(aws ec2 create-subnet --region $REGION --vpc-id $VPC --cidr-block 10.0.2.0/24 --tag-specifications "$(tag subnet shopbondhu-private-subnet)" --query Subnet.SubnetId --output text)
aws ec2 modify-subnet-attribute --region $REGION --subnet-id $PUB --map-public-ip-on-launch

IGW=$(aws ec2 create-internet-gateway --region $REGION --tag-specifications "$(tag internet-gateway shopbondhu-igw)" --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --region $REGION --internet-gateway-id $IGW --vpc-id $VPC

EIP=$(aws ec2 allocate-address --region $REGION --domain vpc --query AllocationId --output text)
NAT=$(aws ec2 create-nat-gateway --region $REGION --subnet-id $PUB --allocation-id $EIP --tag-specifications "$(tag natgateway shopbondhu-nat)" --query NatGateway.NatGatewayId --output text)
aws ec2 wait nat-gateway-available --region $REGION --nat-gateway-ids $NAT

PUBRT=$(aws ec2 create-route-table --region $REGION --vpc-id $VPC --tag-specifications "$(tag route-table shopbondhu-public-rt)" --query RouteTable.RouteTableId --output text)
aws ec2 create-route --region $REGION --route-table-id $PUBRT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW >/dev/null
aws ec2 associate-route-table --region $REGION --route-table-id $PUBRT --subnet-id $PUB >/dev/null
PRVRT=$(aws ec2 create-route-table --region $REGION --vpc-id $VPC --tag-specifications "$(tag route-table shopbondhu-private-rt)" --query RouteTable.RouteTableId --output text)
aws ec2 create-route --region $REGION --route-table-id $PRVRT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT >/dev/null
aws ec2 associate-route-table --region $REGION --route-table-id $PRVRT --subnet-id $PRV >/dev/null

aws ec2 create-key-pair --region $REGION --key-name shopbondhu-key --query KeyMaterial --output text > shopbondhu-key.pem
chmod 400 shopbondhu-key.pem
WEBSG=$(aws ec2 create-security-group --region $REGION --group-name shopbondhu-web-sg --description "web" --vpc-id $VPC --query GroupId --output text)
aws ec2 authorize-security-group-ingress --region $REGION --group-id $WEBSG --protocol tcp --port 22 --cidr $MYIP >/dev/null
aws ec2 authorize-security-group-ingress --region $REGION --group-id $WEBSG --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null
BESG=$(aws ec2 create-security-group --region $REGION --group-name shopbondhu-backend-sg --description "backend" --vpc-id $VPC --query GroupId --output text)
aws ec2 authorize-security-group-ingress --region $REGION --group-id $BESG --protocol tcp --port 22 --source-group $WEBSG >/dev/null

AMI=$(aws ssm get-parameter --region $REGION --name /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query Parameter.Value --output text)
aws ec2 run-instances --region $REGION --image-id $AMI --instance-type t3.micro --key-name shopbondhu-key --subnet-id $PUB --security-group-ids $WEBSG --tag-specifications "$(tag instance shopbondhu-web)" >/dev/null
aws ec2 run-instances --region $REGION --image-id $AMI --instance-type t3.micro --key-name shopbondhu-key --subnet-id $PRV --security-group-ids $BESG --tag-specifications "$(tag instance shopbondhu-backend)" >/dev/null
echo "Done. VPC=$VPC NAT=$NAT. Next: SSH to shopbondhu-web and run scripts/web-setup.sh"
