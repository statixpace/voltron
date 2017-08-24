#!/bin/bash
# provisions a docker server
set -e
LOGFILE=/var/log/provision.log

apt-get update |& tee -a ${LOGFILE}
echo "Updated apt-get" >> ${LOGFILE}

i="0"
while [ $i -lt 15 ]
do 
    if [ $(fuser /var/lib/dpkg/lock) ]; then 
        i="0"
    fi 
    sleep 1
    i=$[$i+1]
done

echo "Installing Docker ..." >> ${LOGFILE}
# install came from this script https://releases.rancher.com/install-docker/17.03.sh
docker_version=17.03.2
CHANNEL="stable"
dist_version="$(lsb_release --codename | cut -f2)"
lsb_dist="$(lsb_release -si)"
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
pre_reqs="apt-transport-https ca-certificates curl software-properties-common"
apt_repo="deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$lsb_dist $dist_version $CHANNEL"
while [ $i -lt 15 ]
do 
    if [ $(fuser /var/lib/dpkg/lock) ]; then 
        i="0"
    fi 
    sleep 1
    i=$[$i+1]
done
apt-get install -y -q $pre_reqs |& tee -a ${LOGFILE}
curl -fsSl "https://download.docker.com/linux/$lsb_dist/gpg" | apt-key add -
add-apt-repository "$apt_repo"
apt-get update |& tee -a ${LOGFILE}
apt-get install -y -q docker-ce=$(apt-cache madison docker-ce | grep ${docker_version} | head -n 1 | cut -d ' ' -f 4) |& tee -a ${LOGFILE}
usermod -aG docker voltron |& tee -a ${LOGFILE}
# Ubuntu 16.04 uses systemd, so we gots to edit the unit file and reload
# this will enable the Docker API.
sed -i "s#ExecStart=/usr/bin/dockerd -H fd://#ExecStart=/usr/bin/docker daemon -H fd:// -H tcp://0.0.0.0:2375#" /lib/systemd/system/docker.service |& tee -a ${LOGFILE}
systemctl daemon-reload |& tee -a ${LOGFILE}
service docker restart |& tee -a ${LOGFILE}
echo "Docker Installed!" >> ${LOGFILE}

# launch docker agent - add to Web environment
echo "Spinning up Rancher agent" >> ${LOGFILE}
sudo docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/rancher:/var/lib/rancher rancher/agent:v1.2.5 http://192.168.1.124:8080/v1/scripts/9D302DF95A01E31CE9A4:1483142400000:MTMTG8Qgxcj3wfRZw91fX2kct8 |& tee -a ${LOGFILE}
echo "Instance added to Rancher Environment" >> ${LOGFILE}
