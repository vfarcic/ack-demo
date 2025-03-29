#!/usr/bin/env nu

source  scripts/common.nu
source  scripts/kubernetes.nu
source  scripts/ack.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    main create kubernetes aws

    kubectl create namespace a-team

    # main apply ack

    main print source
    
}

def "main destroy" [] {

    main destroy kubernetes aws

}
