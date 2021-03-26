#!/bin/bash

kubectl create secret generic k8s-auth-poc-sftp-secrets \
    --from-file=ssh_host_id_rsa=test_secrets/ssh_host_id_rsa \
    --from-file=ssh_host_id_rsa.pub=test_secrets/ssh_host_id_rsa.pub \
    --from-file=ssh_host_id_ecdsa=test_secrets/ssh_host_id_ecdsa \
    --from-file=ssh_host_id_ecdsa.pub=test_secrets/ssh_host_id_ecdsa.pub \
    --from-file=ssh_host_id_ed25519=test_secrets/ssh_host_id_ed25519 \
    --from-file=ssh_host_id_ed25519.pub=test_secrets/ssh_host_id_ed25519.pub
