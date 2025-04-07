#!/usr/bin/env nu

source  scripts/common.nu
source  scripts/kubernetes.nu
source  scripts/ack.nu
source  scripts/crossplane.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    main create kubernetes aws

    kubectl create namespace a-team

    kubectl --namespace a-team apply --filename rds-password.yaml

    main apply ack

    main apply crossplane --preview true --provider aws

    (
        kubectl --namespace crossplane-system apply
        --filename crossplane-providers/
    )

    main wait crossplane

    (
        kubectl --namespace crossplane-system apply
        --filename crossplane-configs/
    )

    (
        kubectl --namespace crossplane-system apply
            --filename crossplane-package/
    )

    main print source
    
}

def "main destroy" [] {

    main destroy kubernetes aws

    main delete ack

}
