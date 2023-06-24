# CHANNEL CREATION
Notes about the last iteraction
- We only were able to join the orderer to the channel within the orderer container
- Tls msp also needs a config.yaml file for NodeOUS
- We cannot sogregate organizations when they are the same organization
## 1. Config the configtx.yaml, we already configed it. Check out orderer-config-files.
- We already make this step up and we have all the necessary configs and comments inside of the orderer-config-files
- You should note that the MSP's are mapped in the config.yaml in every msp that we have of every organization in the orderer deployment
- Note that the ID of the local MSP of the orderer is Org1, because that the msp of the organization we declared in this file, this is very important otherwise it will not be able to identify the msp
- The certificates that we geneated before do not have a DNS, so we needed to apply a bunch of ips as you noticed but DNS is always a better practise, because it is changable
- Make sure every ip address is available for other peers if they need so, you can use nmap to check it out, as a debug tool
## 2. Generate the genesis block
- This is the first block of a certain channel, and it is generated according to the setting that we applyied inside of the configtx.yaml
- Note that you can create multiple profiles for each channel you desire to create, and with yaml syntax you can even override some of the parameters, it is up to you
- In this example we aplly only Signature Policies and the ImplicitMeta Policies. Inside of the organization policies we have the signature policies that are more specific to each role that we mapped. Then we have the implicit that are for a certain majority of policies agreed by the members of the channel.. the application impliti meta policies take place at the newly created channel and the channel policies take place after the channel running
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
./osnadmin channel join --channelID channel1 --config-block ../blocks/genesis_block.pb -o 127.0.0.1:7053 --ca-file tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --client-cert tls-msp/admin/msp/signcerts/cert.pem --client-key tls-msp/admin/msp/keystore/key.pem
```
This will return a map saying that the block heigth is 1

We should not that, joining orderers that are not in the consenter set, puts the orderer inside the channel but not as consenter but as a follower. This means that the orderer replicates the ledger but is not ready yet to work. In order to work we need to update the channel policies. (we can use the genesis block or the latest added block). Only add the new orderer as consenter when the heigth is very clone. Also, this orderer to be even a follower needs to have his organization in the channel config.

Note that in a real scenario, we can setup up a orderer as follower and when it charges all the blocks or the blocks are close to the heigth of the others, thats when we add him to the consenter list of roderers.
# JOIN THE CHANNEL
The next steps are meant for the peer1 side
## 1. Fetch the last block that the channel has
```
./peer channel fetch config --channelID channel1 --cafile ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem  --tls  --certfile ../ca-client/tls-msp/admin/msp/signcerts/cert.pem --keyfile ../ca-client/tls-msp/admin/msp/keystore/key.pem -o 192.168.1.101:7050
```
## 2. Join the channel
In order to join to the channel we need to enter the container since the core.yaml is configured for the directory presented on the container

We need to move the msp to the admin and then go to the config file and use the following command
```
export CORE_PEER_TLS_ROOTCERT_FILE=../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem
export CORE_PEER_MSPCONFIGPATH=../ca-client/msp/admin/msp/
peer channel join -b ./channel1_config.block
```
It will print a message saying that the request for joining got done

We can see if it was sucessfull my digit "peer list" (we only can achieve this with the right msp)
## 3. Install chaincode
We need to pick up the chaincode and convert it to a basic.tar.gz:
```
peer lifecycle chaincode package basic.tar.gz --path ../chaincode/chaincode-go/ --lang golang --label basic_1.0
```
Now we install the chaincode like this: (dont forget to put again the msp as the admin msp)
```
peer lifecycle chaincode install basic.tar.gz
```

## 4. Approve the chaincode
Grab the ID of the package that got installed like this:
```
peer lifecycle chaincode queryinstalled
```
Approve the chaincode like so:

Set the enviroment variable like so: "export CC_PACKAGE_ID=<PACKAGE ID>"
```
peer lifecycle chaincode approveformyorg -o 192.168.1.101:7050 --channelID channel1 --name basic --version 1.0 --package-id $CC_PACKAGE_ID --sequence 1  --cafile ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --tls --certfile ../ca-client/tls-msp/admin/msp/signcerts/cert.pem --keyfile ../ca-client/tls-msp/admin/msp/keystore/key.pem 
```
Note that it will approve to all the organization this peer is apart of

## 5. Commit the chaincode
```
peer lifecycle chaincode checkcommitreadiness --channelID channel1 --name basic --version 1.0 --sequence 1 --tls --cafile ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --certfile ../ca-client/tls-msp/admin/msp/signcerts/cert.pem --keyfile ../ca-client/tls-msp/admin/msp/keystore/key.pem --output json
```
This will produce a json file saying which orgs did accept the chaincode definition

Lets now commit
```
peer lifecycle chaincode commit -o 192.168.1.101:7050  --channelID channel1 --name basic --version 1.0 --sequence 1 --tls --cafile ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --peerAddresses 192.168.1.100:7051 --tlsRootCertFiles  ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem
```
Please note that if we had another peer we would need to put another --peerAddresses and --tlsRootCertFiles (you only need to put the enought organizatons that satisfy the policie, not all the peers)

Example:
```
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name basic --version 1.0 --sequence 1 --tls --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" --peerAddresses localhost:7051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" --peerAddresses localhost:9051 --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
```

To veify if it got commited or not you need to run the following:

```
peer chaincode invoke -o 192.168.1.101:7050 --tls --cafile ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem --certfile ../ca-client/tls-msp/admin/msp/signcerts/cert.pem --keyfile ../ca-client/tls-msp/admin/msp/keystore/key.pem -C channel1 -n basic --peerAddresses 192.168.1.100:7051 --tlsRootCertFiles ../ca-client/tls-msp/admin/msp/tlscacerts/tls-192-168-1-78-7777.pem -c '{"function":"InitLedger","Args":[]}'
```