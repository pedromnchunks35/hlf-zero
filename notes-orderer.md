# DEPLOY A ORDERER
Assumptions
- We will assume that the orderer is apart of the org1 just like the other peers
- The files that we firstly will create as so, but the enroll commands will generate new directories and files
  ```
  ├── ca-client
              └── tls-cas
  ```
- After the creation of all the files, the work enviroment will be something like this:
  ```
  ├── ca-client
  ├── msp
  └── tls-msp
  ```
## 1. Register the orderer in the TLS CA
To do so, we will go to the client that we once created for the CA's and register the orderer
```
fabric-ca-client register -d -u https://localhost:7777 --id.name orderer --id.secret 12341234 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho,OU=Centro Algoritmi" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp/
```
## 2. Enroll the orderer to a directory called tls-msp
- Copy the tls certificate of the TLS CA, to the tls-cas directory (we created that when setting the cas).
- Give the name of tls-root-ca.pem 
After that, in the client you should run the following command
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7777 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho,OU=Centro Algoritmi" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-cas/tls-root-ca.pem --enrollment.profile tls --mspdir ../tls-msp
```
## 4. Register the orderer in the intermediate CA
Register the orderer in the intermediate CA client, in the adm side, when we created the CA's
```
fabric-ca-client register -d -u https://localhost:7779 --id.name orderer --id.secret 12341234 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho,OU=Centro Algoritmi" --csr.hosts "192.168.1.101,orderer" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir int-ca/iteradm/msp/
```
## 5. Enroll the orderer identity
Copy the root tls ca of the intermediate CA and then use this command and the certificate will be enrolled. Note that we dont specify a profile, this is intended to create a identity.
```
fabric-ca-client enroll -d -u https://orderer:12341234@192.168.1.78:7779 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho,OU=Centro Algoritmi" --csr.hosts "192.168.1.100,orderer" --tls.certfiles tls-cas/int-root-ca.pem --mspdir ../msp
```