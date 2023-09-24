# Deploy a peer
## 1. Create the needed directories
Inside of the root folder where you will deploy the peer, you need to have the following folder structures: 

(This is personal configuration for using a client ca to get the needed certificates)
```
├── config
├── data-vault
├── snapshots
├── chaincode
├── ca-client
            └── tls-cas
```

## 2. Generate the needed cryptographic materials
To generate the cryptographic materials, we need 2 certificates that we once generated for the CA's. The root TLS CA for the intermediate CA and other for the TLS CA. Because we need to enroll the admin of the org1 and also we need the TLS certificates for the communication.

Note that the intermediate CA certificate is verifyied by the TLS CA.

1. Copy both root CA's, that are the TLS certificates that we created once for the clients to establish the CA's to the tls-cas folder
2. Name the tls as tls-root-ca.pem and the intermediate as int-root-ca.pem
3. Register the peer1 in the intermediate CA
For register, go to the client that we setted in the host machine that already has the admin msp and use the following command:
```
fabric-ca-client register -d -u https://localhost:7779 --id.type peer --id.affiliation org1.doctor --id.name peer1 --id.secret 12341234 --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.hosts "192.168.1.100,peer1,127.0.0.1,172.17.0.2" --csr.cn peer1 --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp/
``` 
4. Enroll on the virtual machine side, the certificate for this org1
```
fabric-ca-client enroll -d -u https://peer1:12341234@192.168.1.78:7779 --id.type peer --id.affiliation org1.doctor  --csr.cn peer1 --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.hosts "192.168.1.100,peer1,127.0.0.1" --tls.certfiles tls-cas/int-root-ca.pem --mspdir ../msp
```
5. Register the tls certificate for the peer1 (also in the host machine)
```
fabric-ca-client register -d -u https://localhost:7777 --id.name peer1 --id.secret 12341234 --id.type peer --id.affiliation org1.doctor  --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.cn peer1 --csr.hosts "192.168.1.100,peer1,127.0.0.1,172.17.0.2" --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --mspdir tls-ca/tlsadmin/msp/
```
6. Enroll the tls certificate for the peer1 (in the virtual machine side)
```
fabric-ca-client enroll -d -u https://peer1:12341234@192.168.1.78:7777 --id.type peer --id.affiliation org1.doctor  --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.cn peer1 --csr.hosts "192.168.1.100,peer1,127.0.0.1,172.17.0.2" --tls.certfiles tls-cas/tls-root-ca.pem --mspdir ../tls-msp --enrollment.profile tls
```
7. Register the adm identity for intermediate CA
In this step you will also need to go to the client that we setted up in the intermediate CA
```
fabric-ca-client register -d -u https://localhost:7779 --id.name adm-iter --id.secret 12341234 --id.type admin --id.affiliation org1 --csr.names  "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn peer1  --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp/
```
9. Enroll the adm identity for the intermediate CA
```
fabric-ca-client enroll -d -u https://adm-iter:12341234@localhost:7779 --id.type admin --id.affiliation org1  --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn peer1  --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir msp/admin/msp
```
8. Register the adm identity for tls CA
```
fabric-ca-client register -d -u https://localhost:7777 --id.name adm --id.secret 12341234 --id.type admin --id.affiliation org1 --csr.names  "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn peer1  --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir tls-ca/iteradm/msp/ --enrollment.profile tls
```
9. Enroll the adm identity for tls CA
```
fabric-ca-client enroll -d -u https://adm:12341234@localhost:7777  --id.type admin --id.affiliation org1 --csr.names  "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn peer1  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir ../../cryptographic-materials/peer1/tls-msp-admin --enrollment.profile tls
```
10. Extract chaincode-go from fabric-samples
Go to asset-transfer-basic/chaincode-go and run this command
```
GO111MODULE=on go mod vendor
```
After that pick the chaincode-go dir and paste it inside of the chaincode folder in the peer1. Since it is inside of a machine use the "sftp" command. (This is a suggestion)

11. Put the config.yaml files for MSP identification inside of the tls-msp and msp that we have created so far

Note that, for the tls-msp we have a file that already configed inside of /orderer-config-files/NodeOUS/tls-msp/ and for the msp we have a file in /orderer-config-files/NodeOUS/msp/

This files will map, which OUS correspond to a certain rule inside of the MSP(client,admin,peer,orderer). Also, we provide the certificate of the Root CA that issued those certificates. The OUS, are defined in the csr.names or id.type or even id.affiliation. (Eg: csr.names "OU=something",--id.type admin, --id.affiliation Org1.nurse)
- With the csr.names we can put whatever we want in terms of OU's
- id.type we can only put those 4 roles (client,admin,peer,orderer)
- id.affiliation it puts the OUS relative to a certain hierarchy, for example in case of the Org1.nurse, it would create 2 OUs (Org1 and nurse) 
## 3 - Create the peer configuration
Well , in order to config the peer we need to create a file called core.yaml. To do so, we need to grab a template from the internet and config it. We already did that, it is on the peer-config-files. Also, there are comments about every field that we can see much better with better comments extension of vscode. Note that in order for everything works well, you need to check the notes relative to the couchdb, otherwise it will fail to run.

1. Copy the core.yaml to the config/ folder 
## 4 - Do the same thing for the peer2, changing of course the profiles (the organization remains the same) 
In my config, in the affiliations instead of Org1.doctor, i putter Org1.nurse in peer2
## 5 - Start the containers with the following configuration:
You can run this in a bash script
```
#!/bin/bash

docker run \
  --name peer1 \
  -p 7051:7051 \
  -e FABRIC_CFG_PATH=/tmp/hyperledger/org1/peer1/config\
  -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
  -e FABRIC_LOGGING_SPEC=debug \
  -e CORE_PEER_GOSSIP_SKIPHANDSHAKE=true \
  -v /var/run:/host/var/run \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-peer:/tmp/hyperledger/org1/peer1 \
  -w /tmp/hyperledger/org1/peer1\
   hyperledger/fabric-peer
```
For more info check out the vm-files/peer1/deploy-peer, thats exacly how it becomes after this steps and other more (there are steps from other notes, but you get the idea by looking into it)