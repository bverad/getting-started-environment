#!/bin/bash
#installing components
echo "installing libraries"
apt update
apt install curl
apt install wget
#installing docker
echo "docker installing"
curl -sSL https://get.docker.com/ | sh
#intalling maven 
echo "installing maven"
wget --no-verbose -O /tmp/apache-maven-3.6.3-bin.tar.gz https://downloads.apache.org/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf /tmp/apache-maven-3.6.3-bin.tar.gz -C /opt/
ln -s  /opt/apache-maven-3.6.3 /opt/maven
ln -s /opt/maven/bin/mvn /usr/local/bin
rm /tmp/apache-maven-3.6.3-bin.tar.gz
#intalling trivy 
echo "installing trivy"
wget https://github.com/aquasecurity/trivy/releases/download/v0.18.3/trivy_0.18.3_Linux-64bit.deb
dpkg -i trivy_0.18.3_Linux-64bit.deb
#intalling kubectl
echo "installing kubectl"
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.20.0/bin/linux/amd64/kubectl && chmod +x kubectl
mv ./kubectl /usr/local/bin/kubectl
echo "installing original entrypoint"
bash /usr/local/bin/jenkins.sh
echo "finish entrypoint"
#El proceso termina junto con el script, por lo que hay que utilizar alguna instruccion que mantenga vivo el proceso
#while true; do sleep 1000; done
