# DEPLOY A ORDERER
As we know, the disposition of the configuration depends always of the person that is making the configuration. We should do what better fits us.
## 1. Create the Schema for our needs
With the same resources as the other vms, we created the following structure initially
```
deploy-orderer
  └── org1
       ├── admin
       ├── orderer
       └── ca-client
            └── tls-cas
                 ├── int-root-ca.pem (Tls certificate to access intermediate CA)
                 └── tls-root-ca.pem (Tls certificate to access the TLS Root CA)
```

After all the iteractions we will be doing, the output structure will becOme something like this:

```
deploy-orderer
  ├── org1
  │    ├── admin
  │    │    └── msp
  │    │         ├── cacerts
  │    │         │    └── 192-168-1-78-7778.pem (Root CA certificate that 
  │    │         │                              signed admin certificate)
  │    │         │                               
  │    │         ├── intermediatecerts 
  │    │         │    └── 192-168-1-78-7779.pem (CA certificate that signed admin
  │    │         │                        certificate. Note that it got signed by
  │    │         │                        a intermediate CA)
  │    │         ├── IssuerPublicKey
  │    │         ├── IssuerRevocationPublicKey
  │    │         ├── keystore (this has a private key, that we will not use)
  │    │         ├── signcerts 
  │    │         │    └── cert.pem (admin certificate)
  │    │         │
  │    │         └── user 
  │    ├── msp
  │    │    ├── admincerts
  │    │    │    └── admin-org1-cert.pem (admin certificate for org1, which is the
  │    │    │                             the one we generated above. Since we on-
  │    │    │                             ly have 1 org we will use the admin cert
  │    │    │                             in both org1 msp and in the orderer msp)
  │    │    ├── cacerts
  │    │    │    └── 192-168-1-78-7778.pem (Root CA certificate that 
  │    │    │                              signed admin certificate)
  │    │    │                               
  │    │    ├── intermediatecerts 
  │    │    │    └── 192-168-1-78-7779.pem (CA certificate that issues org1 certs.
  │    │    │                      this is the same intermediate that issued the
  │    │    │                      admin above)
  │    │    ├── tlscacerts 
  │    │    │    └── tls-192-168-1-78-7777.pem (Root TLS CA)
  │    │    │
  │    │    └── user 
  │    ├── orderer
  │    │    ├── msp
  │    │    │    ├── admincerts
  │    │    │    │    └── admin-org1-cert.pem (admin certificate for org1, which
  │    │    │    │        is the the one we generated above. Since we only have 1 
  │    │    │    │        org we will use the admin cert in both org1 msp and in
  │    │    │    │        the orderer msp)
  │    │    │    │                                         
  │    │    │    ├── cacerts
  │    │    │    │    └── 192-168-1-78-7779.pem (Root CA certificate that 
  │    │    │    │                               signed admin certificate)
  │    │    │    ├── intermediatecerts
  │    │    │    │    └──192-168-1-78-7779.pem (CA certificate that issues 
  │    │    │    │                 org1 certs. this is the same intermediate
  │    │    │    │                 that issued the admin above)
  │    │    │    │ 
  │    │    │    ├── keystore (this has a private key inside)
  │    │    │    │ 
  │    │    │    │                                                             
  │    │    │    ├── IssuerPublicKey
  │    │    │    ├── IssuerRevocationPublicKey
  │    │    │    ├── signcerts
  │    │    │    │    └── cert.pem (this is the orderer certificate, issued by
  │    │    │    │                  the intermediate CA)
  │    │    │    └── user
  │    │    └── tls-msp
  │    │         ├── keystore
  │    │         │    └── key.pem (private key for the TLS certificate)
  │    │         ├── IssuerPublicKey
  │    │         ├── IssuerRevocationPublicKey
  │    │         ├── signcerts
  │    │         │    └── cert.pem (Tls certificate for the orderer)
  │    │         ├── tlscacerts
  │    │         │    └── tls-192-168-1-78-7777.pem (TLS Root CA, that  signed the
  │    │         │                                   tls certificate of the
  │    │         │                                   orderer)
  │    │         └── user
  │    └── ca-client
  │         └── tls-cas
  │              ├── int-root-ca.pem (Tls certificate to access intermediate CA)
  │              └── tls-root-ca.pem (Tls certificate to access the TLS Root CA)
  ├── channel.tx (The channel.tx artifact that we will generate with configtxgen)
  ├── configtx.yaml (This is the file used by the configtxgen to generate
  │                  the artifact channel.tx and genesis.block, we can create
  │                  multiple configtx.yaml for create multiple profiles or create
  │                  multiple profiles in a single one, depending of the organiza-
  │                  tion we want. Refer to the notes-channel-config for more info)
  └── genesis.block (This is a artifact that we will generate with configtxgen
                     , we should note that this is the first block of the orderer
                     it retains the sys configurations to all channels)
```
## 2. Register the admin identity in the intermediate CA
In order to achieve that, we went to the client we once created for the intermediate CA for setting the CA's and we introduced this:
```
fabric-ca-client register -d -u https://localhost:7779 --id.name adm-iter --id.secret 12341234 --id.type admin --id.affiliation org1 --csr.cn adm-iter --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp
```
## 3. Enroll the adm in the orderer side
We go to the ca-client dir, we set the new CLIENT_CA_HOME and we use this command:
```
fabric-ca-client enroll -d -u https://adm-iter:12341234@192.168.1.78:7779 --id.type admin --id.affiliation org1 --csr.cn adm-iter --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --tls.certfiles tls-cas/int-root-ca --mspdir ../admin/msp
```
## 4. Register the orderer
In order to achieve that, we went to the client we once created for the intermediate CA for setting the CA's and we introduced this:
```
fabric-ca-client register -d -u https://localhost:7779 --id.name orderer --id.secret 12341234 --id.type orderer --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp
```

## 5. Enroll the orderer in the orderer side
We go to the ca-client dir, we set the new CLIENT_CA_HOME and we use this command:
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7779 --id.type orderer --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-cas/int-root-ca --mspdir ../orderer/msp
```

## 6. Create a admincerts directory inside of the orderer msp and also inside of the org1 msp
## 7. Go inside of the msp admin directory inside of org1, copy the signed certificate, inside of "signcerts" and paste it under the previous created "admincerts" directorys. Rename it to admin-org1-cert.pem (it can be any name).
Any difficulties in this step, see the final structure of the file above, it is pretty forward

## 8. Register the tls certificate
In order to achieve that, we went to the client we once created for the TLS CA for setting the CA's and we introduced this:
```
fabric-ca-client register -d -u https://localhost:7777 --id.name orderer --id.secret 12341234 --id.type orderer --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir tls-ca/iteradm/msp
```

## 9. Enroll the tls certificate in the orderer side
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7777 --id.type orderer --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.hosts "192.168.1.101,orderer" --enrollment.profile tls --tls.certfiles tls-cas/tls-root-ca.pem --mspdir ../orderer/tls-msp
```

## 10. Rename the private key inside of the keystore to key.pem

## 11. Go get a template of the configtx.yaml and config it with the two profiles genesis and channel. We have that inside of the ordeer-config-files directory (already configured of course). Also we have the notes for the channel config

## 12. Inside of the deploy-orderer directory, create a configtx.yaml with the config we just configured and run this command individually
```
configtxgen -profile Genesis -outputBlock genesis.block -channelID syschannel
configtxgen -profile Channel -outputCreateChannelTx channel.tx -channelID mychannel
```
This will create the two needed artifacts. A genesis.block and a channel.tx files in protobuf format.

## 13. Go any directory and place this script and after run it
```
#!/bin/bash
docker run \
  --name orderer \
  -p 7050:7050 \
  -e ORDERER_HOME=/tmp/hyperledger/org1/orderer \
  -e ORDERER_HOST=127.0.0.1:7050 \
  -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0\
  -e ORDERER_GENERAL_GENESISMETHOD=file \
  -e ORDERER_GENERAL_GENESISFILE=/tmp/hyperledger/deploy-orderer/genesis.block \
  -e ORDERER_GENERAL_LOCALMSPID=OrdererMSP \
  -e ORDERER_GENERAL_LOCALMSPDIR=/tmp/hyperledger/deploy-orderer/org1/orderer/msp \
  -e ORDERER_GENERAL_TLS_ENABLED=true \
  -e ORDERER_GENERAL_TLS_CERTIFICATE=/tmp/hyperledger/deploy-orderer/org1/orderer/tls-msp/signcerts/cert.pem \
  -e ORDERER_GENERAL_TLS_PRIVATEKEY=/tmp/hyperledger/deploy-orderer/org1/orderer/tls-msp/keystore/key.pem \
  -e ORDERER_GENERAL_TLS_ROOTCAS=[/tmp/hyperledger/deploy-orderer/org1/orderer/tls-msp/tlscacerts/tls-192-168-1-78-7777.pem] \
  -e ORDERER_GENERAL_LOGLEVEL=debug \
  -e ORDERER_DEBUG_BROADCASTTRACEDIR=data/logs \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-orderer:/tmp/hyperledger/deploy-orderer \
  hyperledger/fabric-orderer
```
The orderer runs :)