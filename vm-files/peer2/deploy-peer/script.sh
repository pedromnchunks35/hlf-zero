#!/bin/bash

docker run \
  --name peer2 \
  -p 7051:7051 \
  -e FABRIC_CFG_PATH=/tmp/hyperledger/org1/peer2/config\
  -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
  -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=guide_fabric-ca \
  -e FABRIC_LOGGING_SPEC=debug \
  -e CORE_PEER_GOSSIP_SKIPHANDSHAKE=true \
  -v /var/run:/host/var/run \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-peer:/tmp/hyperledger/org1/peer2 \
  -w /opt/gopath/src/github.com/hyperledger/fabric/org1/peer2 \
   hyperledger/fabric-peer

