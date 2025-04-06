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

    main apply ack

    main apply crossplane --preview true --provider aws

    (
        kubectl --namespace crossplane-system apply
        --filename crossplane-providers/
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
