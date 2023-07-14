#!/bin/bash -e

cd /etc/swanctl

# Generate priv keys for mains, fars and remote
pki --gen --type ed25519 --outform pem > mainsKey.pem
pki --gen --type ed25519 --outform pem > farsKey.pem
pki --gen --type ed25519 --outform pem > remoteKey.pem
echo "private keys generated"

# Create the CA based oj the mains priv key
pki --self --ca --lifetime 3652 --in mainsKey.pem \
           --dn "C=CH, O=heig, CN=heig Root CA" \
           --outform pem > caCert.pem
echo "CA generated"

# Generate the csr for mains, fars and remote		 
pki --req --type priv --in mainsKey.pem \
          --dn "C=CH, O=heig, CN=heig.mains" \
          --outform pem > mainsReq.pem
		  
pki --req --type priv --in farsKey.pem \
          --dn "C=CH, O=heig, CN=heig.fars" \
          --outform pem > farsReq.pem
		  		  
pki --req --type priv --in remoteKey.pem \
          --dn "C=CH, O=heig, CN=heig.remote" \
          --outform pem > remoteReq.pem
echo "CSR generated"
		  
# Issue the CSR for fars and remote
pki --issue --cacert caCert.pem --cakey mainsKey.pem \
            --type pkcs10 --in mainsReq.pem --serial 01 --lifetime 1826 \
            --outform pem > mainsCert.pem
			
pki --issue --cacert caCert.pem --cakey mainsKey.pem \
            --type pkcs10 --in farsReq.pem --serial 01 --lifetime 1826 \
            --outform pem > farsCert.pem
			
pki --issue --cacert caCert.pem --cakey mainsKey.pem \
            --type pkcs10 --in remoteReq.pem --serial 01 --lifetime 1826 \
            --outform pem > remoteCert.pem
echo "CSR issued"

# Copy all pems in root
cp *.pem /root
echo "pems copied"

#remove copied files
rm *.pem
echo "old pems deleted"