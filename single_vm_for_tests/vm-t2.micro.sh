#!/bin/bash -e
#########################################################################################################################
# 	Встановіть AWS CLI з http://aws.amazon.com/cli/	та зробіть відповідні ключі для ec2 перед виконанням скрипта		#
#########################################################################################################################
echo "Триває створення EC2 t2.micro та SecurityGroup  ..."
AMIID="$(aws ec2 describe-images --filters "Name=name,Values=amzn-ami-hvm-2017.09.1.*-x86_64-gp2" --query "Images[0].ImageId" --output text)"
VPCID="$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)"
SUBNETID="$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)"
SGID="$(aws ec2 create-security-group --group-name securitygroupforwp --description "TEST VM for wordpress" --vpc-id "$VPCID" --output text)"
aws ec2 authorize-security-group-ingress --group-id "$SGID" --protocol tcp --port 22 --cidr 0.0.0.0/0
INSTANCEID="$(aws ec2 run-instances --image-id "$AMIID" --key-name mykey --instance-type t2.micro --security-group-ids "$SGID" --subnet-id "$SUBNETID" --query "Instances[0].InstanceId" --output text)"
echo "--------------------------------------------------------"
echo "Чекаємо на ==>> $INSTANCEID ..."
aws ec2 wait instance-running --instance-ids "$INSTANCEID"
PUBLICNAME="$(aws ec2 describe-instances --instance-ids "$INSTANCEID" --query "Reservations[0].Instances[0].PublicDnsName" --output text)"
echo "$INSTANCEID <<== приймає SSH підключення на: $PUBLICNAME"
echo "ssh -i ./mykey.pem ec2-user@$PUBLICNAME"
echo "--------------------------------------------------------"
read -r -p "Натисніть [Enter] для видалення ресурсів EC2( $INSTANCEID ) та SecurityGroup ( $SGID ) ..."
aws ec2 terminate-instances --instance-ids "$INSTANCEID"
echo "Триває видалення створених Вами EC2( $INSTANCEID ) та SecurityGroup ( $SGID ) ..."
aws ec2 wait instance-terminated --instance-ids "$INSTANCEID"
aws ec2 delete-security-group --group-id "$SGID"
echo "Зроблено."
