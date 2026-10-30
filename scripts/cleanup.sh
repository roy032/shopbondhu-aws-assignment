#!/usr/bin/env bash
# Deletes billable resources. Pass the IDs as env vars: NAT, EIP, WEB_ID, BACKEND_ID, VPC.
set -euo pipefail
R="${AWS_REGION:-ap-southeast-2}"
aws ec2 terminate-instances --region $R --instance-ids $WEB_ID $BACKEND_ID
aws ec2 wait instance-terminated --region $R --instance-ids $WEB_ID $BACKEND_ID
aws ec2 delete-nat-gateway --region $R --nat-gateway-id $NAT
sleep 90
aws ec2 release-address --region $R --allocation-id $EIP
echo "Now delete the VPC ($VPC) in the console to remove subnets, route tables and the IGW."
