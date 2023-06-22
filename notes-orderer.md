# DEPLOY A ORDERER
As we know, the disposition of the configuration depends always of the person that is making the configuration. We should do what better fits us.

The configuration that i will make will be something like this:
```
deploy-orderer
 ├── ledger-vault (this is where the ledger data will be stored)
 ├── admin-client (client for the CA to retrieve every cryptographic material 
 │    │            we need)
 │    └── tls-cas
 │         ├── int-root-ca.pem (tls certificate for the Intermediate CA)
 │         └── tls-root-ca.pem (tls certificate for the Root CA)
 ├── config (this will contain the orderer.yaml)
 └── org1 
      ├── msp
      │    ├── cacerts
      │    └── tlscacerts
      └── orderer
           ├── msp
           └── tls-msp
``` 
## 1. Copy TLS Root CA, Root CA and Intermediate CA certificates to the MSP of the org1 (also the config.yaml)
-> The TLS Root CA, is on the client we setted for CA'S config, and it is one that is self-signed by hospital.tls-ca. Copy it to deploy-orderer/org1/msp/tlscacerts

-> The Root CA, is the CA that signed the intermediate CA, since we have Root and 1 intermediate CA. This certificate is also self signed and is org1-ca. Place it under deploy-orderer/org1/msp/cacerts/

-> The intermediate CA, is the intermediate CA certificate that got signed by the Root CA, it is the iteradm identity. Place it inside of deploy-orderer/org1/msp/intermediatecerts

-> Place also a config.yaml file inside of the directory deploy-orderer/org1/msp/. We already configed this file and it is to enable NodeOUS and also to identify which identity is trusted by who and which identity is which in terms of roles (peer,admin,etc..). We can attribute a csr.names.OU="estrela" and map it to estrela=admin thanks to this file

## 2. Register the TLS certificate for the orderer
As you know is good practise for the admin first register the node in a private client, and the enroll later on became done in the host that we will install the cryptographic tools. So, with the client created to set the CA's
```
fabric-ca-client register -d -u https://localhost:7777 --id.name orderer --id.secret 12341234 --id.type orderer --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer,127.0.0.1,localhost" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir tls-ca/iteradm/msp
```

## 3. Enroll the TLS certificate for the orderer
From the client that we disposed in the orderer host:
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7777 --id.type orderer --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer,127.0.0.1,localhost" --enrollment.profile tls --tls.certfiles tls-cas/tls-root-ca.pem --mspdir ../org1/orderer/tls-msp
```
Go to the keystore and rename the private key to key.pem
## 4. Register local msp for the orderer
```
fabric-ca-client register -d -u https://localhost:7779 --id.name orderer --id.secret 12341234 --id.type orderer --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer,127.0.0.1,localhost" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp
```
## 5. Enroll the local msp for the orderer
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7779  --id.type orderer --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer,127.0.0.1,localhost" --tls.certfiles tls-cas/int-root-ca.pem --mspdir ../org1/orderer/msp 
```
## 6. Place once again the config.yaml for the NodeOUS inside of this local msp of the orderer (it is the secound, the first got placed in the org msp)
## 7. Place a config.yaml inside of the tls-msp of the orderer
## 8. Make the configuration of the orderer.yaml (we will place it inside of config). We have a configuration inside of orderer-config-files
## 9. Place this script and run it 
-> 7050 is the port of the orderer

-> 9443 is the port for the api that the admin will access to create the channel 

-> We will create a volume that will retain everything in -v 

-> We will also set the FABRIC_CFG_PATH, to the path where the orderer.yaml is located
```
#!/bin/bash
docker run \
  --name orderer \
  -e FABRIC_CFG_PATH=/tmp/hyperledger/deploy-orderer/config \
  -p 7050:7050 \
  -p 7053:7053 \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-orderer:/tmp/hyperledger/deploy-orderer/ \
  hyperledger/fabric-orderer
```