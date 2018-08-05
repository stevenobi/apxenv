##########################################################################################################################################

# create a root authority cert
./create_root_cert_and_key.sh

# create a wildcard cert for mysite.com
./create_certificate_for_domain.sh mysite.com

# or create a cert for www.mysite.com, no wildcards
./create_certificate_for_domain.sh www.mysite.com www.mysite.com

####################################################################################################
### create_root_cert_and_key.sh

#!/usr/bin/env bash
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem


####################################################################################################
### create_certificate_for_domain.sh
#!/usr/bin/env bash

if [ -z "$1" ]
then
  echo "Please supply a subdomain to create a certificate for";
  echo "e.g. www.mysite.com"
  exit;
fi

if [ ! -f rootCA.pem ]; then
  echo 'Please run "create_root_cert_and_key.sh" first, and try again!'
  exit;
fi
if [ ! -f v3.ext ]; then
  echo 'Please download the "v3.ext" file and try again!'
  exit;
fi

# Create a new private key if one doesnt exist, or use the xeisting one if it does
if [ -f device.key ]; then
  KEY_OPT="-key"
else
  KEY_OPT="-keyout"
fi

DOMAIN=$1
COMMON_NAME=${2:-*.$1}
SUBJECT="/C=CA/ST=None/L=NB/O=None/CN=$COMMON_NAME"
NUM_OF_DAYS=1024
openssl req -new -newkey rsa:2048 -sha256 -nodes $KEY_OPT device.key -subj "$SUBJECT" -out device.csr
cat v3.ext | sed s/%%DOMAIN%%/"$COMMON_NAME"/g > /tmp/__v3.ext
openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days $NUM_OF_DAYS -sha256 -extfile /tmp/__v3.ext 

# move output files to final filenames
mv device.csr "$DOMAIN.csr"
cp device.crt "$DOMAIN.crt"

# remove temp file
rm -f device.crt;

echo 
echo "###########################################################################"
echo Done! 
echo "###########################################################################"
echo "To use these files on your server, simply copy both $DOMAIN.csr and"
echo "device.key to your webserver, and use like so (if Apache, for example)"
echo 
echo "    SSLCertificateFile    /path_to_your_files/$DOMAIN.crt"
echo "    SSLCertificateKeyFile /path_to_your_files/device.key"


####################################################################################################
### v3.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = %%DOMAIN%%
DNS.2 = trainingtrivadis.com
DNS.3 = apx.io


####################################################################################################
### convert certs to PEM format
openssl x509 -in trainingtrivadis.com.crt -out trainingtrivadis.com.pem -outform PEM


####################################################################################################
### copy cert and key to folder of yours and add it to ords standalone properties

#Wed Jun 20 08:58:49 CEST 2018
jetty.secure.port=8443
ssl.cert=/home/oracle/.ssl/clientCA/trainingtrivadis.com.pem
ssl.cert.key=/home/oracle/.ssl/clientCA/trainingtrivadis.com.key
ssl.host=sob01.trainingtrivadis.com
standalone.context.path=/ords
standalone.doc.root=/u01/app/oracle/ords/htdocs
standalone.scheme.do.not.prompt=true
standalone.static.context.path=/i/
standalone.static.path=/u01/app/oracle/product/12.1.0/dbhome_1/apex18/images/
