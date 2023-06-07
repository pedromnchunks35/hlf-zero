# DEPLOYING A CA
## 1. Create a dir for every ca (In our case we only will put one CA)
- We should have a CA for tls, another for intermediate certificates and a organization CA for each organization
- Order of deployment is like so:
  ```
  1. TLS CA
  2. Organization CA
  3. Intermediate CA
  ```
- We will create a structure for server side tls
  ```
  server-side -> Only the server has the tls certificate, therefore it does not obligate the client to apresent one but it secures the communication anyway
  mutual -> Both client and server present the TLS certificate, both authenticate themselfs
  ```
## 2. We will init the tls CA server first (enter the tls-ca directory)
   
The script is as follow:
  ```
  fabric-ca-server init -b <user>:<password>
  ```
We in this case will put as follow:
  ```
  fabric-ca-server init -b admin:12341234
  ```
This command above will generate multiple files such as: 
- ca-cert.pem
  ```
  This is the signed certificate for the CA (self-signed in this case of course)     
  You should share this certificate with the clients that want to transact with any node in the organization (it is a public key), they must include this certificate as part of the transaction
  ``` 
- IssuerPublicKey
  ```
  Public key to issue certificates
  ```
- IssuerRevocationPublicKey
  ```
  Public key to revocate certificates
  ```
- fabric-ca-server-config.yaml
  ```
  Template with the default configurations such as port to run, if we use tls or not, etc...
  ```
- fabric-ca-server.db
  ```
  sqlite database (atleast if you dont override the database in the fabric-ca-server-config.yaml)
  ```
- msp
  ```
  This is the directory where we store the cryptographic materials
  The structure is like this:
  MSP
    - keystore
      - (file with huge hash)
      - IssuerRevocationPrivateKey
      - IssuerSecretKey
  Keystore is a directory specially designed to store private keys of the organization
  The file with huge hash name is the private key associated to the certificate of the CA
  The IssuerRevocationPrivateKey is a private key to revoke certificates
  IssuerSecretKey is a private key to issue certificates
  ```
-> Every key pair does a certain task, in case of issuing certificates(public key which is on the main directory and private inside of the keystore)

## 3. Config the fabric-ca-server-config.yaml for the tls-ca

-> This file as a huge number of parameters, but since we are creating a TLS-CA, we should at the minimum config the following:
- port
  ```
  For the tls-ca, im putting the port number 7777
  ```
- tls.enabled
  ```
  For this situation, we will enable it, which will create a certificate automatically called "tls-cert.pem" when the server starts. Note that, since this is the TLS CA, the certificate can be automatically generated but then we need to generate here certificates for another entities. Also, this certificate will be the one that the server will present to the client during a TLS handshake, which the client will then verify using the TLS CA "ca-cert.pem"
  ```
- ca.name
  ```
  The name of the CA
  ```
- csr.hosts
  ```
  This is the provable hosts that this server can use that will be present in the TLS certificate
  Since we are in the localhost, the probable hosts that we will be using are: 
  -> "hopistal.tls-ca", case we use docker compose
  -> "localhost", case we simply are in the localhost
  -> "192.168.1.78", case we are in our private network
  ```
- signing.profiles.ca
  ```
  Since this is a root CA, which means it is not a intermediate CA, we will delete all the ca block of profiles, remaining only the tls
  ```
-> We will make another relevant changes such as:
- affiliations
  ```
  - Afilliations are something like a subgroup inside of a organization
  - We will only have 1 organization so, lets put only 1 organization and 2 departments
  It will pretty much become something like this:
  affiliations:
   org1:
      - doctor
      - nurse
  ```
- csr.cn
  ```
  CA certificate common name
  We will set it to hospital.tls-ca
  ```
- csr.names
  ```
  CA Certificate aspects to mention. We will put the entire csr like so:
  csr:
   cn: hospital.tls-ca
   keyrequest:
     algo: ecdsa
     size: 256
   names:
      - C: PT
        ST: Porto
        L: Aliados
        O: Universidade do minho
        OU: Centro Algoritmi
   hosts:
     - hospital.tls-ca
     - localhost
     - 192.168.1.78
   ca:
      expiry: 131400h
      pathlength: 1
  ```

-> After this configurations, since we changed the csr, we need to delete the ca-cert.pem and the entire fabric-ca-server-tls/msp
## 5. Delete the certificates and keys
-> Since we changed the csr we need to delete all the cryptographic material, otherwise we will have an error in matching keys. Delete the following: msp folder, ca-cert.pem, IssuerPublicKey, IssuerRevocationPublicKey and tls-cert.pem.
## 6. Set the FABRIC_CA_HOME
-> Since in our case, we will have the CA'S all in the host machine we should put the home as the $pwd, which is the current work directory we are into, which will obligate us to be on the directory of the CA we want to run but thats ok.

You should add the following into the bashrc:

![Fabric ca client home](assets-notes/bashrc-fabric-ca-server-home.png)
## 7. Start the tls-ca server
```
fabric-ca-server start
```
-> Since we deleted all the cryptographic material, we renew the material again by starting the server :)

-> If it is the first time running the server, it will even generate a tls certificate for the CA server, since we enabled tls
## 8. Create a dir for the clients of the CA's (client for tls-ca, intermediate-ca )
```
In our case the structure will be something like:
fabric-ca-clients
  - int-server-ca
  - org1-server-ca
  - tls-server-ca
    - tls-ca
    - tls-root-cert
Note that in this case we are only creating the client for the tls-server-ca for now.

-> tls-ca directory, will be the directory to store the certificates issued when we enroll a entity (enroll is a process after registering that creates the cryptographic material)
-> tls-root-cert directory, will be to know where the TLS CA root certificate resides that allows the fabric CA client to communicate with the TLS CA server.
```
## 9. Copy and rename the certificate of the TLS CA

-> This certificate is the "ca-cert.pem", that was generated when we started the server.

-> We should rename it to tls-ca-cert.pem

-> The destiny of this file is the tls-root-cert, on the tls-server-ca under the fabric-ca-clients of course

-> Note that for making connections to the TLS CA every client needs this certificate

![The move](assets-notes/cp-rename-ca-cert.png)

## 10. Create the FABRIC_CA_CLIENT_HOME
![CA HOME](assets-notes/bashrc-fabric-ca-client-home.png)
- You should put here the home of the client CA

## 11. Enroll the admin
```
fabric-ca-client enroll -d -u https://admin:12341234@localhost:7777 --tls.certfiles tls-root-cert/tls-ca-cert.pem  --enrollment.profile tls --mspdir tls-ca/tlsadmin/msp
```
-> Note that we enroll the admin because the admin is already registered, because in case it is not registed we would need to register him first, enroll is just for generating the cryptographic materials

-> The command template is as so:
   ```
   fabric-ca-client enroll -d -u https://<ADMIN>:<ADMIN-PWD>@<CA-URL>:<PORT> --tls.certfiles <RELATIVE-PATH-TO-TLS-CERT> --enrollment.profile tls --mspdir tls-ca/tlsadmin/msp
   ```
   - "-d", is for debug mode
   - "-u", is for put the url and also the user together as you can see
   - "--tls.certiles", the certificate of the server we are acessing path (in ourcase is tls-ca-cert.pem, because it is a copy of the ca-cert.pem of the TLS CA)
   - "--enrollment.profile", is the type of profile in our case is "tls", for telling to the server that we are under the rules of the signing options of the server config (we can omit this flag because we removed the profile block)
   - "--mspdir", is the relative path to where we will store the cryptographic material 

![Smells like sucess](assets-notes/Success.png)
- This is the sucess message when enrolling
- Please note that we can enroll the much we want to