#!/bin/bash
docker run \
  --name orderer \
  -e FABRIC_CFG_PATH=/tmp/hyperledger/deploy-orderer/config \
  -p 7050:7050 \
  -p 7053:7053 \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-orderer:/tmp/hyperledger/deploy-orderer/ \
  hyperledger/fabric-orderer
