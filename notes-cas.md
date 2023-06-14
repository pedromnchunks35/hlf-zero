# DEPLOYING A CA's
## Create a dir for every ca (In our case we only will put one CA)
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
# TLS CA
## 1. We will init the tls CA server first (enter the tls-ca directory)
   
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

## 2. Config the fabric-ca-server-config.yaml for the tls-ca

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
## 3. Delete the certificates and keys
-> Since we changed the csr we need to delete all the cryptographic material, otherwise we will have an error in matching keys. Delete the following: msp folder, ca-cert.pem, IssuerPublicKey, IssuerRevocationPublicKey and tls-cert.pem.
## 4. Set the FABRIC_CA_HOME
-> Since in our case, we will have the CA'S all in the host machine we should put the home as the $pwd, which is the current work directory we are into, which will obligate us to be on the directory of the CA we want to run but thats ok.

You should add the following into the bashrc:

![Fabric ca client home](assets-notes/bashrc-fabric-ca-server-home.png)
## 5. Start the tls-ca server
```
fabric-ca-server start
```
-> Since we deleted all the cryptographic material, we renew the material again by starting the server :)

-> If it is the first time running the server, it will even generate a tls certificate for the CA server, since we enabled tls
## 6. Create a dir for the clients of the CA's (client for tls-ca, intermediate-ca )
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
## 7. Copy and rename the certificate of the TLS CA

-> This certificate is the "ca-cert.pem", that was generated when we started the server.

-> We should rename it to tls-ca-cert.pem

-> The destiny of this file is the tls-root-cert, on the tls-server-ca under the fabric-ca-clients of course

-> Note that for making connections to the TLS CA every client needs this certificate

## 8. Create the FABRIC_CA_CLIENT_HOME

## 9. Enroll the admin
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
# Register and enroll Organization CA
Every peer needs a TLS certificate to communicate, so in order to deploy the Organization CA, we will firstly register the administrator of the Organization CA.

## 1. Register the admin of the Organization CA in the TLS CA
```
fabric-ca-client register -d --id.name org1ca --id.secret 12341234 -u https://localhost:7777  --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
```
- This command will be runned by the TLS Client that we created before
- The user name will be "org1ca"
- The password will be "12341234"
- The tls certificate of course will be the TLS CA certificate
- We will give our msp location so that it can get the private key to sign the message out, but for tlsadmin
![Success](assets-notes/tls-maded.png)
- The tls connection :)
## 2. Enrool the new admin for the organization CA
```
fabric-ca-client enroll -d -u https://org1ca:12341234@localhost:7777 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'hospital.org1-ca,localhost,192.168.1.78' --mspdir tls-ca/org1ca/msp
```
- Now we generate the cryptographic material again but this time is for our organization1 CA admin that we already registered
- The tls certificate remains the same
- The profile is tls as the one before (we can omit but we maintain because it does not give errors anyway, and if we later on add profiles it is a good practise)
- We add the possible hosts
- In "mspdir", we will put a non-existent dir so it creates a dir just for serving the org1ca, like with admin
- Once again we run this in the tls client
- The signed certificate is generated under /org1ca/msp/signcert
- The private key is generated under /org1ca/msp/keystore
- To deploy the Organization CA, we will need to copy those files and reference them in the tls section (in the configuration.yaml)
# Register and enroll the intermediate CA admin with the TLS CA
This step is to create a intermediate CA admin in the TLS CA, for issue certificates on behalf of the organization CA, you should also register and enroll the intermediate CA.
## 1. Register the intermediate CA admin
```
fabric-ca-client register -d --id.name interadm --id.secret 12341234 -u https://localhost:7777 --tls.certfiles tls-root-cert/tls-ca-cert.pem --mspdir tls-ca/tlsadmin/msp
```
## 2. Enroll the CA admin
```
fabric-ca-client enroll -d -u https://interadm:12341234@localhost:7777 --tls.certfiles tls-root-cert/tls-ca-cert.pem --enrollment.profile tls --csr.hosts 'hospital.inter-ca,localhost,192.168.1.78' --mspdir tls-ca/interadm/msp
```
# Deploy the organization 1 CA
## 1. Navigate to the folder you created once, create a directory for store the tls files you generated in the client of the TLS-CA
  
![Result directores](assets-notes/org1-ca-result.png)

## 2. Initialize again a CA
```
fabric-ca-server init -b org1ca:12341234
```

## 3. Modify the configuration once again
- port will be 7778
- tls.enabled is true
  ```
  Because you enable tls, dont you forget to put the relative path for either the certfile and the keyfile
  Note that the private key may have a strange name.. you should rename it to become more easy for you to put that in the configuration
  I will rename it to key.pem
  The configuration will become like this:

  tls:
  # Enable TLS (default: false)
  enabled: true
  # TLS for the server's listening port
  certfile: "/tls/cert.pem"
  keyfile: "/tls/key.pem"
  ```
- ca.name will be hospital.org1-ca
- csr.hosts will be the hosts we once applyied when enrooling the certificate such as 'hospital.org1-ca,localhost,192.168.1.78
- csr.pathlength will be 1, which means that this CA can issue intermediate certificates, but the intermediate CA cannot issue CA certificates (only one intermediate). Case it was 0, you could put more than one intermediate
- signing.ca.maxpathlenzero will be false, which means that we will have a maxpathlen greater than 0
- signing.ca.maxpathlen will be "1", since we want 1 intermediate CA
- operations.listenAddress, the port will be 9444, since we have a CA already in port 9443
- affiliations
  ```
  The affiliations will become like this:
  
  affiliations:
  org1:
    - doctor
    - nurse
  ```
## 4. Delete all the cryptographic material because we changed the csr
## 5. Start the server
## 6. Enroll the CA admin for the Organization CA

-> Go to the server folder and copy the certificate and put it on the client folder, inside of the folder org1-root-cert (remember, that we now assigned one tls certificate inside of the folder tls, which means that the automatically generated cert.pem, is no longer in this case the certificate of that precise server. By all means, you will use a certificate that was created by the client of the TLS CA).

-> Dont forget to rename the certificate for "org1-ca-cert.pem" :)
```
Now, to enroll we put the following command:
fabric-ca-client enroll -d -u https://org1ca:12341234@localhost:7778 --csr.hosts 'hospital.org1-ca,localhost,192.168.1.78' --tls.certfiles org1-root-cert/org1-ca-cert.pem --enrollment.profile ca --mspdir org1-ca/org1ca/msp
```
-> Note that this command has the "--enrollment.profile ca", which means he is deploying a certificate of type CA, and not tls, which means that we will get a certificate for authentication and not for securing communication
- This will generate a ton of files with the following structure:
  ```
  └── msp
    ├── cacerts
        └── localhost-7778.pem
    ├── keystore
        └── (BIG HASH)
    ├── signcerts
        └── cert.pem
    ├── user
    ├── IssuerPublicKey
    └── IssuerRevocationPublicKey  
  ```
- localhost-7778.pem is the Organization CA root certificate
- the (BIG HASH) is the private key for the organization CA admin identity
- cert.pem is the CA admin identity signed certificate
# Register the intermediate CA identity with the organization root CA (this is how we form a chain of trust)
We form a chain of trust by registering the user using the CA root cert, but we also need to add a attribute called hf.IntermediateCA=true
```
fabric-ca-client register -u https://localhost:7778  --id.name interadm --id.secret 12341234 --id.attrs '"hf.Registrar.Roles=user,admin","hf.Revoker=true","hf.IntermediateCA=true"' --tls.certfiles org1-root-cert/org1-ca-cert.pem --mspdir org1-ca/org1ca/msp
```
-> The register is done but the enroll will be done in the intermediate CA
# Deploy an intermediate CA
## 1. Create a directory named tls like in the previous deploy and copy paste the tls public key and private key that you once generated in the client of the tls-ca for the intermediate CA :) (signcert is where the public key resides and in the keystore is the privatekey)
 
![Where it resides](assets-notes/where-it-resides.png)
- This is what you once generated for the intermediate CA. We should copy the signcerts and the keystore as i mention before
- Dont forget to rename the private key to key.pem, in order to be easier for you to call it in the server config file!!

![tls config intermediate ca](assets-notes/tls-intermediate-ca.png)
- It would end up like this
- Also, dont forget to put here the ca-cert.pem of the tls-ca and rename it to tls-ca-cert.perm
## 2. Init the server
 ```
 fabric-ca-server init -b interadm:12341234
 ```
## 3. config the fabric-ca-server-config.yaml
- port change it for 7779
- tls.enables true
- tls.certfile is the "tls/cert.pem"
- tls.keystore is the "tls/key.pem"
- csr.cn must be blank for intermediate CA's
- csr.ca.pathlength must be 0, because we will not have more CA's in the chain
- intermediate.parentserver.url, must be the url of the parent of this CA, which is the org1-ca, so the url will be https:iteradm:12341234@localhost:7778
- intermediate.parentserver.caname, this is the name of the parent CA "hospital.org1-ca"
- intermediate.enrollment.hosts, is the localhost,192.168.1.78,hospital.org1-ca
- intermediate.enrollment.profile which is the signing profile "ca", for issuing certificates, the tls would be to generate a tls certificate which is different
- intermediate.tls.certfiles, you put here the tls main certificate for telling which tls certificate you will use to communicate with the parent "tls/tls-ca-cert.pem"
- operations.listenAddress will be 127.0.0.1:9445
- afilliation are the same as the others
  ```
  org1:
  - doctor
  - nurse
  ```
- dont forget to delete all over again the cryptographic materials to re-run the server and the changes get applyied (if you changed the csr)
## 4. Start the server
- You should note that a ca-chain got created wich is the chain certificate where you have both org1 and inter certificates
## 5. Enroll the admin certificate

-> To enroll the adm certificate, go to the client tls, copy the signcert destinated for the intermediate CA and paste it in the directory that you will create with the name "tls-root-cert". Paste there the certificate and change his name for tls-root-cert.pem ,just for you to understand which certificate it is

-> Enroll the admin as so:
   ```
   fabric-ca-client enroll -d -u https://interadm:12341234@localhost:7779 --tls.certfiles /tls-root-cert/tls-root-cert.pem --csr.hosts 'localhost,hospital.inter-ca,192.168.1.78" --mspdir int-ca/iteradm/msp --enrollment-profile ca
   ```