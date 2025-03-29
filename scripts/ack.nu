#!/usr/bin/env nu

def --env "main apply ack" [
] {

    print $"\nApplying (ansi yellow_bold)ACK Controllers(ansi reset)...\n"

    if AWS_ACCESS_KEY_ID not-in $env {
        $env.AWS_ACCESS_KEY_ID = input $"(ansi yellow_bold)Enter AWS Access Key ID: (ansi reset)"
    }
    $"export AWS_ACCESS_KEY_ID=($env.AWS_ACCESS_KEY_ID)\n"
        | save --append .env

    if AWS_SECRET_ACCESS_KEY not-in $env {
        $env.AWS_SECRET_ACCESS_KEY = input $"(ansi yellow_bold)Enter AWS Secret Access Key: (ansi reset)"
    }
    $"export AWS_SECRET_ACCESS_KEY=($env.AWS_SECRET_ACCESS_KEY)\n"
        | save --append .env

    let password = (
        aws ecr-public get-login-password --region us-east-1
    )

    (
        helm registry login --username AWS --password $password 
            public.ecr.aws
    )

    mut aws_account_id = ""
    if AWS_ACCOUNT_ID in $env {
        $aws_account_id = $env.AWS_ACCOUNT_ID
    } else {
        $aws_account_id = (
            aws sts get-caller-identity --query "Account"
                --output text
        )
    }

    mut oidc_provider = ""
    if OIDC_PROVIDER in $env {
        $oidc_provider = $env.OIDC_PROVIDER
    } else {
        $oidc_provider = (
            aws eks describe-cluster --name $name --region $region
                --query "cluster.identity.oidc.issuer"
                --output text | str replace "https://" ""
        )
    }

    let controllers = [
        {name: "ec2", version: "1.3.7"},
        {name: "rds", version: "1.4.14"},
    ]
    for controller in $controllers {

        (
            helm upgrade --install
                $"ack-($controller.name)-controller"
                oci://public.ecr.aws/aws-controllers-k8s/($controller.name)-chart
                $"--version=($controller.version)"
                --create-namespace --namespace ack-system
                --set aws.region=us-east-1
        )

        {
            Version: "2012-10-17",
            Statement: [
                {
                    Effect: "Allow",
                    Principal: {
                        Federated: $"arn:aws:iam::($aws_account_id):oidc-provider/($oidc_provider)"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            $"($oidc_provider):sub": $"system:serviceaccount:ack-system:ack-($controller.name)-controller"
                        }
                    }
                }
            ]
        } | to json | save trust.json --force

        (
            aws iam create-role
                --role-name $"ack-($controller.name)-controller"
                --assume-role-policy-document file://trust.json
                --description $"IRSA role for ACK ($controller.name) controller deployment on EKS cluster using Helm charts"
        )

    }

}
