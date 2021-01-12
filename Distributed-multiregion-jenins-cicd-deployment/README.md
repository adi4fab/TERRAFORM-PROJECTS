TERRAFORM, ANSIBLE, JENKINS, CI/CD deployment.

Consider the instance which you are using below is a development instance in DEV env.



Steps to be followed.

- Launch an EC2 instance.
- Install terraform by downloading it and moving it to a executable path.
- Now install python3-pip
- Install awscli using pip3 install awscli --user
- Install ansible using pip3 install ansible --user.
- Make a new folder and go inside it
- downlaod the ansible.cfg using wget 
// https://raw.githubusercontent.com/linuxacademy/content-deploying-to-aws-ansible-terraform/master/aws_la_cloudplayground_version/ansible.cfg
  
- Now configure awscli with aws cli.

- Now give access to terraform to provision resources on AWS.
- This can be done in 2 ways
1. Giving a user privilages and using the same cred in aws cli.
2. Create a policy and create a role and attach it to the instance.

The policy is below.

{
"Version": "2012-10-17",
"Statement": [
{
"Sid": "CustomPolicyForACGAWSTFCourse",
"Action": [
"ec2:Describe*",
"ec2:Get*",
"ec2:AcceptVpcPeeringConnection",
"ec2:AttachInternetGateway",
"ec2:AssociateRouteTable",
"ec2:AuthorizeSecurityGroupEgress",
"ec2:AuthorizeSecurityGroupIngress",
"ec2:CreateInternetGateway",
"ec2:CreateNetworkAcl",
"ec2:CreateNetworkAclEntry",
"ec2:CreateRoute",
"ec2:CreateRouteTable",
"ec2:CreateSecurityGroup",
"ec2:CreateSubnet",
"ec2:CreateTags",
"ec2:CreateVpc",
"ec2:CreateVpcPeeringConnection",
"ec2:DeleteNetworkAcl",
"ec2:DeleteNetworkAclEntry",
"ec2:DeleteRoute",
"ec2:DeleteRouteTable",
"ec2:DeleteSecurityGroup",
"ec2:DeleteSubnet",
"ec2:DeleteTags",
"ec2:DeleteVpc",
"ec2:DeleteVpcPeeringConnection",
"ec2:DetachInternetGateway",
"ec2:DisassociateRouteTable",
"ec2:DisassociateSubnetCidrBlock",
"ec2:CreateKeyPair",
"ec2:DeleteKeyPair",
"ec2:DeleteInternetGateway",
"ec2:ImportKeyPair",
"ec2:ModifySubnetAttribute",
"ec2:ModifyVpcAttribute",
"ec2:ModifyVpcPeeringConnectionOptions",
"ec2:RejectVpcPeeringConnection",
"ec2:ReplaceNetworkAclAssociation",
"ec2:ReplaceNetworkAclEntry",
"ec2:ReplaceRoute",
"ec2:ReplaceRouteTableAssociation",
"ec2:RevokeSecurityGroupEgress",
"ec2:RevokeSecurityGroupIngress",
"ec2:RunInstances",
"ec2:TerminateInstances",
"ec2:UpdateSecurityGroupRuleDescriptionsEgress",
"ec2:UpdateSecurityGroupRuleDescriptionsIngress",
"acm:*",
"elasticloadbalancing:AddListenerCertificates",
"elasticloadbalancing:AddTags",
"elasticloadbalancing:CreateListener",
"elasticloadbalancing:CreateLoadBalancer",
"elasticloadbalancing:CreateRule",
"elasticloadbalancing:CreateTargetGroup",
"elasticloadbalancing:DeleteListener",
"elasticloadbalancing:DeleteLoadBalancer",
"elasticloadbalancing:DeleteRule",
"elasticloadbalancing:DeleteTargetGroup",
"elasticloadbalancing:DeregisterTargets",
"elasticloadbalancing:DescribeListenerCertificates",
"elasticloadbalancing:DescribeListeners",
"elasticloadbalancing:DescribeLoadBalancerAttributes",
"elasticloadbalancing:DescribeLoadBalancers",
"elasticloadbalancing:DescribeRules",
"elasticloadbalancing:DescribeSSLPolicies",
"elasticloadbalancing:DescribeTags",
"elasticloadbalancing:DescribeTargetGroupAttributes",
"elasticloadbalancing:DescribeTargetGroups",
"elasticloadbalancing:DescribeTargetHealth",
"elasticloadbalancing:ModifyListener",
"elasticloadbalancing:ModifyLoadBalancerAttributes",
"elasticloadbalancing:ModifyRule",
"elasticloadbalancing:ModifyTargetGroup",
"elasticloadbalancing:ModifyTargetGroupAttributes",
"elasticloadbalancing:RegisterTargets",
"elasticloadbalancing:RemoveListenerCertificates",
"elasticloadbalancing:RemoveTags",
"elasticloadbalancing:SetSecurityGroups",
"elasticloadbalancing:SetSubnets",
"route53:Get*",
"route53:List*",
"route53:ChangeResourceRecordSets",
"ssm:Describe*",
"ssm:GetParameter",
"ssm:GetParameters",
"ssm:GetParametersByPath",
"s3:CreateBucket",
"s3:DeleteBucket",
"s3:DeleteObject",
"s3:GetBucketLocation",
"s3:GetObject",
"s3:HeadBucket",
"s3:ListBucket",
"s3:PutObject"
],
"Effect": "Allow",
"Resource": "*"
}
]
}