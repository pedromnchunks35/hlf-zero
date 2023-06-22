# CHANNEL CREATION
Notes about the last iteraction
- We only were able to join the orderer to the channel within the orderer container
- Tls msp also needs a config.yaml file for NodeOUS
- We cannot sogregate organizations when they are the same organization
## 1. Config the configtx.yaml, we already configed it. Check out orderer-config-files.
- We already make this step up and we have all the necessary configs and comments inside of the orderer-config-files
## 2. Generate the genesis block
```
configtxgen -profile Channel -outputBlock ../blocks/genesis_block.pb -channelID channel1
```
With this, we will generate the block and put it under the blocks directory
## 4. Registry a new admin for tls that has the --id.type admin, since the tls-ca admin does not have that rule (i learned that the worst way possible)
Go to the host side client when we setted the CA and do this:
```
fabric-ca-client register -d -u https://localhost:7777 --id.name adm-orderer --id.secret 12341234 --id.type admin --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir tls-ca/tls-admin/msp
```
## 5. Enroll the tls admin that we just created in the orderer side
```
fabric-ca-client enroll -d -u https://adm-orderer:12341234@192.168.1.78:7777  --id.type admin --id.affiliation org1 --csr.cn orderer --csr.names "C=PT,ST=Porto,L=Aliados,O=Universidade do minho" --enrollment.profile tls --tls.certfiles tls-root-cert/tls-root-cert.pem --mspdir tls-msp/admin/msp
```
## 6. Join the orderer into the channel
-> If you try to use this command outside the container, the error logs will be filtered.. But you can try outside the container, but if it throws a error, for debugging is better to put the binarie inside the docker volume and try to run the command inside.

Inside of the client-ca dir:
```
osnadmin channel join --channelID channel1 --config-block ../blocks/genesis_block.pb -o 127.0.0.1:7053 --ca-file tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --client-cert tls-msp/admin/msp/signcerts/cert.pem --client-key tls-msp/admin/msp/keystore/key.pem
```
This will return a map saying that the block heigth is 1

We should not that, joining orderers that are not in the consenter set, puts the orderer inside the channel but not as consenter but as a follower. This means that the orderer replicates the ledger but is not ready yet to work. In order to work we need to update the channel policies. (we can use the genesis block or the latest added block). Only add the new orderer as consenter when the heigth is very clone. Also, this orderer to be even a follower needs to have his organization in the channel config.

Note that in a real scenario, we can setup up a orderer as follower and when it charges all the blocks or the blocks are close to the heigth of the others, thats when we add him to the consenter list of roderers.