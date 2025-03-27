#!/usr/bin/env nu

source  scripts/common.nu
source  scripts/kubernetes.nu

def main [] {}

def "main setup" [] {

    rm --force .env

    main create kubernetes aws

    kubectl create namespace a-team

    main print source
    
}

def "main destroy" [] {

    main destroy kubernetes aws

}
