#/bin/bash
sudo apt update -y
sudo apt install make gcc pkg-config libssl-dev tcl-tls -y
wget http://download.redis.io/releases/redis-6.0.5.tar.gz
tar -xvf redis-6.0.5.tar.gz
wget  https://s3-us-west-1.amazonaws.com/anjuna-security.runtime/anjuna-runtime-ubuntu18-0.22.0025.bin
chmod +x ./anjuna-runtime-ubuntu18-0.22.0025.bin
./anjuna-runtime-ubuntu18-0.22.0025.bin && source $HOME/anjuna-runtime-ubuntu18-0.22.0025/env.sh
cd redis-6.0.5/
sudo make BUILD_TLS=yes install
mkdir $HOME/redis
cd $HOME/redis
anjuna-sgxrun --setup redis-server
sed -i "s/#encrypted_output_files:/encrypted_output_files:\n- temp-*.rdb\n- dump.rdb\n- temp-*.aof\n- appendonly.aof/g" $HOME/redis/manifest.template.yaml
sed -i "s/#output_encryption:/output_encryption:\n  type: SGX_MRSIGNER /g" $HOME/redis/manifest.template.yaml
sed -i "s/#encrypted_input_files:/encrypted_input_files:\n- server.key.sealed/g" $HOME/redis/manifest.template.yaml
anjuna-sgxrun --provision redis-server
anjuna-check-attestation --quote-file redis-server.quote.bin --rsa-key-file redis-server.provision.key
openssl genrsa -out ca.key 4096 
openssl req \
    -x509 -new -nodes -sha256 \
    -key ca.key \
    -days 3650 \
    -subj '/O=Redislabs/CN=Redis Prod CA' \
    -out ca.crt
openssl genrsa -out server.key 2048
openssl req \
    -new -sha256 \
    -key server.key \
    -subj '/O=Redislabs/CN=Production Redis' | \
    openssl x509 \
        -req -sha256 \
        -CA ca.crt \
        -CAkey ca.key \
        -CAserial ca.txt \
        -CAcreateserial \
        -days 365 \
        -out server.crt
openssl dhparam -out server.dh 2048
anjuna-prov-seal --public-key redis-server.provision.key server.key
anjuna-sgxrun redis-server \
--tls-port 6379 --port 0 \
--tls-cert-file server.crt \
--tls-key-file server.key.sealed \
--tls-ca-cert-file ca.crt \
--tls-auth-clients no
echo "127.0.0.1 Production Redis" | sudo tee -a /etc/hosts

#Notes:
# To use a Redis.conf file do not use a trusted input and enter the key as sealed.
