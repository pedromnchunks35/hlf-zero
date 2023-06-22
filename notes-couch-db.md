To init the couchdb we need to:
- Pull the image
- Run the image passing the credentials and volume of the data
```
sudo docker run \
    -p 5989:5984 \
    -e COUCHDB_BIND_ADDRESS=127.0.0.1 \
    -e COUCHDB_USER=admin \
    -e COUCHDB_PASSWORD=12341234 \
    -v /home/pedromn35/go/src/github.com/pedromnchunks35/hlf-zero/couchdb-persist/peer1/:/opt/couchdb/data \
    --name couch-peer1 \
    couchdb

curl -X PUT http://admin:12341234@localhost:5989/_users
curl -X PUT http://admin:12341234@127.0.0.1:5989/_replicator
curl -X PUT http://admin:12341234@localhost:5989/_global_changes
```
For peer2:
```
sudo docker run \
    -p 5990:5984 \
    -e COUCHDB_BIND_ADDRESS=127.0.0.1 \
    -e COUCHDB_USER=admin \
    -e COUCHDB_PASSWORD=12341234 \
    -v /home/pedromn35/go/src/github.com/pedromnchunks35/hlf-zero/couchdb-persist/peer2/:/opt/couchdb/data \
    --name couch-peer2 \
    couchdb

curl -X PUT http://admin:12341234@localhost:5990/_users
curl -X PUT http://admin:12341234@127.0.0.1:5990/_replicator
curl -X PUT http://admin:12341234@localhost:5990/_global_changes
```