#!/bin/bash

ssh-keygen -t rsa -b 4096 -C "k8s-auth-poc" -N "" \
    -f "test_secrets/ssh_host_id_rsa"

ssh-keygen -t ecdsa -C "k8s-auth-poc" -N "" \
    -f "test_secrets/ssh_host_id_ecdsa"

ssh-keygen -t ed25519 -C "k8s-auth-poc" -N "" \
    -f "test_secrets/ssh_host_id_ed25519"
