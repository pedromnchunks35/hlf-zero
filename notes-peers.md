# Deploy a peer
## 1. Create the needed directories
Inside of the root folder where you will deploy the peer, you need to have the following folder structures: 

(This is personal configuration for using a client ca to get the needed certificates)
```
├── ca-client
            └── tls-cas
```

## 2. Generate the needed cryptographic materials
To generate the cryptographic materials, we need 2 certificates that we once generated for the CA's. The root CA for the intermediate CA and other for the TLS CA. Because we need to enroll the admin of the org1 and also we need the TLS certificates for the communication.

Note that the intermediate CA certificate is verifyied by the TLS CA.

1. Copy both root CA's, that are the TLS certificates that we created once for the clients to establish the CA's to the tls-cas folder
2. Name the tls as tls-root-ca.pem and the intermediate as int-root-ca.pem
3. Register the peer1 in the intermediate CA
For register, go to the client that we setted in the host machine that already has the admin msp and use the following command:
```
fabric-ca-client register -d -u https://localhost:7779 --id.type peer --id.affiliation org1.doctor --id.name peer1 --id.secret 12341234 --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.hosts "192.168.1.100,peer1,127.0.0.1" --csr.cn peer1 --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp/
``` 
4. Enroll on the virtual machine side, the certificate for this org1
```
fabric-ca-client enroll -d -u https://peer1:12341234@192.168.1.78:7779 --id.type peer --id.affiliation org1.doctor  --csr.cn peer1 --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.hosts "192.168.1.100,peer1,127.0.0.1" --tls.certfiles tls-cas/int-root-ca.pem --mspdir ../msp
```
5. Register the tls certificate for the peer1 (also in the host machine)
```
fabric-ca-client register -d -u https://localhost:7777 --id.name peer1 --id.secret 12341234 --id.type peer --id.affiliation org1.doctor  --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.cn peer1 --csr.hosts "192.168.1.100,peer1,127.0.0.1" --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --mspdir tls-ca/tlsadmin/msp/
```
6. Enroll the tls certificate for the peer1 (in the virtual machine side)
```
fabric-ca-client enroll -d -u https://peer1:12341234@192.168.1.78:7777 --id.type peer --id.affiliation org1.doctor  --csr.names "C=PT,ST=Porto,L=Aliados,O=Hospital" --csr.cn peer1 --csr.hosts "192.168.1.100,peer1,127.0.0.1" --tls.certfiles tls-cas/tls-root-ca.pem --mspdir ../tls-msp --enrollment.profile tls
```
8. Register a new adm identity with the hf.Role as administrator
```
fabric-ca-client register -d -u https://localhost:7779 --id.type admin --id.name adm-iter --id.secret 12341234 --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn adm-iter --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp/
``` 
9. Enroll the new adm identity for use in both peer1 and peer2 (on creating the peer2 , we skip the registration and in the enroll step, we just go to the client and copy the certificate)
```
fabric-ca-client enroll -d -u https://adm-iter:12341234@localhost:7779 --id.type admin --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --csr.cn adm-iter --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/identity-adm-role-based
```
10. Do the steps 1-6 to the peer2, changing the port of the host, the csr.hosts, the name of the peer and the affiliations (dont forget to copy the adm certificate to it)
11. To enable the NodeOUs, you need to put a config.yaml file inside of the msp (check the notes of the channel to do that)
## 3. Know where resides the TLS private key and create an folder called admincerts to put the admin certificate in it
On this step, we should know, which private key is related to the tls certificate that we have. In forder to do that we can do as follow:
```
1-> We create a file with content inside like a .txt file

2-> We use this command for every private key to create a signature per private key:

    openssl dgst -sha256 -sign key1.pem -out ../signcerts/1.bin teste.txt
        
        notes:
        - key1.pem , is the private key from we will create the signature
        - ../signcerts/1.bin is , is the path and also the name of the signature that needs to end with a .bin
        - teste.txt, is the file that we want to sign on

3-> We extract the public key from the certificate:
    
    openssl x509 -pubkey -noout -in cert.pem > pubkey.pem

        notes:
        - cert.pem, is the certificate
        - pubkey.pem, is the public key that will be generated

4-> Verify signature with public key:

    openssl dgst -sha256 -verify pubkey.pem -signature 1.bin ../keystore/teste.txt

        notes:
        - pubkey.pem, is the public key that we extracted before
        - 1.bin, is the signature that we generated before
        - ../keystore/teste.txt is the file that got generated
```

On the forth step, it will either throw an error in case they dont match or success case it matches, case it matches we want to use that private key.
Inside of the msp generated by the TLS CA, we should create a directory called "admincerts". Move the intermediate CA admin certificate that we generated once in the client we created once for the CA'S to the folder "admincerts", this corresponds to the admin of the organization 1 btw.

Notes about the keys:
- Because we generated tls certificate with tls profile we will have a certificate in the tls directory representing the root tls CA.
- We will have a cert and a key inside of signcert and keystore, which represent the tls certificate for the peer1
- Dont forget to rename the private key to key.pem, for becoming easy to get in the configuration

## 4 - Do the same thing for the peer2, changing of course the profiles (the organization remains the same)
## 5 - Start the containers with the following configuration:
Note , you change the CORE_PEER_GOSSIP_EXTERNALENDPOINT which is the ip address that identifies you in a certain network for server discovery, name of the peer, the peer id and the CORE_PEER_GOSSIP_BOOTSTRAP
```
docker run \
  --name peer1 \
  -p 7050:7051 \
  -e CORE_PEER_ID=peer1 \
  -e CORE_PEER_ADDRESS=127.0.0.1:7051 \
  -e CORE_PEER_LOCALMSPID=org1MSP \
  -e CORE_PEER_MSPCONFIGPATH=/tmp/hyperledger/org1/peer1/msp \
  -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
  -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=guide_fabric-ca \
  -e FABRIC_LOGGING_SPEC=debug \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_CERT_FILE=/tmp/hyperledger/org1/peer1/tls-msp/signcerts/cert.pem \
  -e CORE_PEER_TLS_KEY_FILE=/tmp/hyperledger/org1/peer1/tls-msp/keystore/key.pem \
  -e CORE_PEER_TLS_ROOTCERT_FILE=/tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-192-168-1-78-7777.pem \
  -e CORE_PEER_GOSSIP_USELEADERELECTION=true \
  -e CORE_PEER_GOSSIP_ORGLEADER=false \
  -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=192.168.1.100:7051 \
  -e CORE_PEER_GOSSIP_BOOTSTRAP=192.168.1.140:7051 \
  -e CORE_PEER_GOSSIP_SKIPHANDSHAKE=true \
  -v /var/run:/host/var/run \
  -v /root/go-workspace/src/github.com/pedromnchunks/deploy-peer:/tmp/hyperledger/org1/peer1 \
  -w /opt/gopath/src/github.com/hyperledger/fabric/org1/peer1 \
   hyperledger/fabric-peer
```
 