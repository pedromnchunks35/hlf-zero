# Configtx.yaml Overview
- This a file to config a given channel
- We can have multiple channels, which are multiple configtx.yaml files
- It is a good practise to store this channel info in different directories
- We use configtxgen tool (binarie), to generate the configuration files from that file, that later on form a channel genesis block, which stands for the first block of the channel
- configtxgen, takes the configtx.yaml file and converts it to a protobuf file, so it can be read by the hyper ledger fabric
- Note that examples of configuration can be found in the test network configuration

# Configtx.yaml structure
The file has the following structure:
1. Organizations
2. Capabilities
3. Application
4. Orderer
5. Channel
6. Profiles

## 1. Organizations
- Represents the channel members
- Each org as a MSP ID and a channel MSP
- It is the section that manages the channel MSP (identitie inside of the channel)

> Example of this section:
```
- &Org1
    # DefaultOrg defines the organization which is used in the sampleconfig
    # of the fabric.git development environment
    Name: Org1MSP

    # ID to load the MSP definition as
    ID: Org1MSP

    MSPDir: ../organizations/peerOrganizations/org1.example.com/msp

    # Policies defines the set of policies at this level of the config tree
    # For organization policies, their canonical path is usually
    #   /Channel/<Application|Orderer>/<OrgName>/<PolicyName>
    Policies:
        Readers:
            Type: Signature
            Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
        Writers:
            Type: Signature
            Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
        Admins:
            Type: Signature
            Rule: "OR('Org1MSP.admin')"
        Endorsement:
            Type: Signature
            Rule: "OR('Org1MSP.peer')"

    # OrdererEndpoints is a list of all orderers this org runs which clients
    # and peers may to connect to to push transactions and receive blocks respectively.
    OrdererEndpoints:
        - "orderer.example.com:7050"
 ```
 - Name
    ```
    - Informal name to identify the organization
    ```
 - ID
    ```
    - This is the identifier of the organization 
    - The MSP ID inside of the channel
    - It will be referenced
    ``` 
 - MSPDir
    ```
    - MSP folder, created by the organization
    - configtxgen, will use this msp to create the MSP channel
    - MSP requirements:
        - Root CA of the organization itsel
            - It is required for identify if a app, peer or adm belong to a channel member
        - Root TLS CA the issued the tls certificates
            - It is used by the gossip protocol to identify the organization
        - Case OUs is enabled, then we need to have a config.yaml file, to identify the adm, the peer and clients based on the x509 certificates
        - Case OUs is enabled, we need to have the admincerts folder with the adms certificates inside
        - The MSP, only has public certificates 
    ```
 - Policies
   ```
   - Signature policies over the channel member
   ```
 - OrdererEndpoints
   ```
   - The orderer peers addresses, this serve as service discovering by the peers
   ```
## 2. Capabilities
- It is used to limit functionalities because of different versions of fabric. This allows multiple fabric nodes, to be able to use the same channel. By using this, if someone as a feature in his version that other does not have, then he cannot use that feature.
- There are 3 capabilities groups:
    - Application
      ```
      It can govern:
      - Features used by nodes such as chaincode lifecycle
      - Minimum fabric binaries version for peers
      ```
    - Orderer
      ```
      It can govern:
      - Features used by orderer nodes such as consensus protocols
      - Minimum fabric binaries version for orderers
      ```
    - Channel
      ```
      - Ser minimum version of peer and ordering nodes (We will put the max version of course)
      ```
## 3. Application
- Policies that dictate how peer organizations can interact with application channels. 
- It says the number of peers that need to approve a chaincode definition 
- It says the number of peers that need to sign a request to update the configuration of the channel
- Also can restrict channel resources assessment(ability to write or to read(query))

## 4. Orderer
- Configurations related to ordering the transaction
- It says the consensus algorithm that we will use
- It says the group of nodes that will be responsible for ordering the transactions
- Some examples:
  ```
  # TO SET THE CONSENSUS TYPE
  OrdererType: etcdraft
  # TO SET THE CONSENSUS GROUP
  EtcdRaft:
    Consenters:
    - Host: orderer.example.com
      Port: 7050
      ClientTLSCert: ../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
      ServerTLSCert: ../organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
  ```
- There are extra configurations fields like:
    - BatchTimeout
      ```
      - Max time that a peer will wait before doing a block proposal
      ```
    - BatchSize
      ```
      - Max size of a block, in terms of number of transactions
      - It also has MaxMessageCount,AbsoluteMaxBytes and PrefferedMaxBytes settings.
      ``` 
    - Policies
      ```
      - Policies for the consenter set
      ```
## 5. Channel
- Governs the policies that govern the highest level of the channel configuration
- It governs the hashing algorithm, data hashing structure to create new blocks and the channel capability level

## 6. Profiles
- Section used by configtxgen to build channel configuration in terms of profile
- It creates profiles using other sections data
- It overrides configurations that we made in other sections
- Example
  ```
  TwoOrgsApplicationGenesis:
  <<: *ChannelDefaults
  Orderer:
    <<: *OrdererDefaults
    Organizations:
      - *OrdererOrg
    Capabilities: *OrdererCapabilities
  Application:
    <<: *ApplicationDefaults
    Organizations:
      - *Org1
      - *Org2
    Capabilities: *ApplicationCapabilities
  ```
  Note that *{name} , references a given section with that name, this way we can create profiles :P
- Another example
  ```
  SampleAppChannelEtcdRaft:
    <<: *ChannelDefaults
    Orderer:
        <<: *OrdererDefaults
        OrdererType: etcdraft
        Organizations:
            - <<: *SampleOrg
              Policies:
                  <<: *SampleOrgPolicies
                  Admins:
                      Type: Signature
                      Rule: "OR('SampleOrg.member')"
    Application:
        <<: *ApplicationDefaults
        Organizations:
            - <<: *SampleOrg
              Policies:
                  <<: *SampleOrgPolicies
                  Admins:
                      Type: Signature
                      Rule: "OR('SampleOrg.member')"
  ```
  Note that here we overwrite some opts

# POLICIES
## Types of signatures:
1. Signature policies
2. ImplicitMeta signaturs

## 1. Signature policies
- They are maded uppon given signatures
- This kind of policies are submited by roles (admin,client,peer,etc..)
- Organization section
- Permissions of the members
- Example:
  ```
  - &Org1

  ...

  Policies:
      Readers:
          Type: Signature
          Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
      Writers:
          Type: Signature
          Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
      Admins:
          Type: Signature
          Rule: "OR('Org1MSP.admin')"
      Endorsement:
          Type: Signature
          Rule: "OR('Org1MSP.peer')"
  ```

## 2. Implicit Signatures
- Application section (for channels)
- They refer the Organization section policies
- All organizations voting
- Example
  ```
  Policies:
    Readers:
        Type: ImplicitMeta
        Rule: "ANY Readers"
    Writers:
        Type: ImplicitMeta
        Rule: "ANY Writers"
    Admins:
        Type: ImplicitMeta
        Rule: "MAJORITY Admins"
    LifecycleEndorsement:
        Type: ImplicitMeta
        Rule: "MAJORITY Endorsement"
    Endorsement:
        Type: ImplicitMeta
        Rule: "MAJORITY Endorsement"
  ```

# Notes about roles
The Role is specified in the OU
To enable NodeOUs, we need to create a confix.yaml file with this information: (we can also give different names to the entities)
```
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.sampleorg-cert.pem
    OrganizationalUnitIdentifier: <CLIENT-OU-NAME>
  PeerOUIdentifier:
    Certificate: cacerts/ca.sampleorg-cert.pem
    OrganizationalUnitIdentifier: <PEER-OU-NAME>
  AdminOUIdentifier:
    Certificate: cacerts/ca.sampleorg-cert.pem
    OrganizationalUnitIdentifier: <ADMIN-OU-NAME>
  OrdererOUIdentifier:
    Certificate: cacerts/ca.sampleorg-cert.pem
    OrganizationalUnitIdentifier: <ORDERER-OU-NAME>
```
The distinctions between departments is maded using affiliations
![Affiliations](assets-notes-channel-config/certificate-with-type-and-affiliations.png)

As you can see in this photo, we enrolled a certificate with a type of entitie as admin, and affiliations of org1.doctor type and thats the result of that creation.
