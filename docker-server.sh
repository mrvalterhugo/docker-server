#!/bin/bash
#Install required packages
sudo apt-get remove docker docker-engine docker.io containerd awscli runc -y
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
sudo apt install unzip -y
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian buster stable"
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose jq -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose jq -y

#Create folders to be used by containers
mkdir -p ~/configs/{netdata,pihole,nginx,syncthing,portainer,whoogle}

#Create docker file inside folders

#######Portainer#######
cat << 'EOF' > ~/configs/portainer/docker-compose.yaml
version: "3"
services:
  portainer:
    container_name: portnainer
    image: portainer/portainer-ce
    ports:
      - "8000:8000"
      - "9000:9000"
    # Volumes store your data between container upgrades
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
      - './portainer_data:/data portainer/portainer-ce'
    restart: always
EOF
######Nginx - Proxy Manager#########
cat << 'EOF' > ~/configs/nginx/docker-compose.yaml
version: '3'
services:
  app:
    image: 'jc21/nginx-proxy-manager:latest'
    ports:
      - '80:80'
      - '7779:81'
      - '443:443'
    volumes:
      - ./config.json:/app/config/production.json
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
      - ./var:/var/logs
  db:
    image: 'jc21/mariadb-aria:10.4'
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql 
EOF
cat << 'EOF' > ~/configs/nginx/config.json
{
  "database": {
    "engine": "mysql",
    "host": "db",
    "name": "npm",
    "user": "npm",
    "password": "npm",
    "port": 3306
  }
}
EOF
#####PiHole#############
cat << 'EOF' >  ~/configs/pihole/docker-compose.yaml
version: "3"
# More info at https://github.com/pi-hole/docker-pi-hole/ and https://docs.pi-hole.net/
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "7778:80/tcp"
      - "7780:443/tcp"
    environment:
      TZ: 'Europe/London'
  # 'set a secure password here'
      WEBPASSWORD: 'password'
    # Volumes store your data between container upgrades
    volumes:
      - './etc-pihole/:/etc/pihole/'
      - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
    # Recommended but not required (DHCP needs NET_ADMIN)
    #   https://github.com/pi-hole/docker-pi-hole#note-on-capabilities
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
EOF
#########Whoogle##########
cat << 'EOF' > ~/configs/whoogle/docker-compose.yaml
---
version: "2"
services:
  whoogle:
    image: benbusby/whoogle-search:latest
    container_name: whoogle
    ports:
      - 7781:5000
    restart: unless-stopped
EOF
#########Syncthing##########
cat << 'EOF' > ~/configs/syncthing/docker-compose.yaml
---
version: "2.1"
services:
  syncthing:
    image: linuxserver/syncthing
    container_name: syncthing
    hostname: syncthing #optional
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
    volumes:
      - ./config:/config
      - ./data:/data1
    ports:
      - 8384:8384
      - 22000:22000
      - 21027:21027/udp
    restart: unless-stopped
EOF
#########Netdata#######
cat << 'EOF' > ~/configs/netdata/docker-compose.yaml
version: '3'
services:
  netdata:
    image: netdata/netdata
    container_name: netdata
    hostname: docker-server # set to fqdn of host
    ports:
      - 19999:19999
    restart: unless-stopped
    cap_add:
      - SYS_PTRACE
    security_opt:
      - apparmor:unconfined
    volumes:
      - netdataconfig:/etc/netdata
      - netdatalib:/var/lib/netdata
      - netdatacache:/var/cache/netdata
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro

volumes:
  netdataconfig:
  netdatalib:
  netdatacache:
EOF

#Create the Dynamic DNS Script
########DNS IP Update Script#####
cat << 'EOF' > ~/dns-checker.sh 
#!/bin/bash
#Variable Declaration - Change These
HOSTED_ZONE_ID="Z057YourZoneIDHere10J22FLTHOT0J"
NAME="YourDomainHere.com."
TYPE="A"
TTL=60
date
#get current IP address
IP=$(curl http://checkip.amazonaws.com/ 2> /dev/null )
echo "Current IP is" $IP
#validate IP address (makes sure Route 53 doesn't get updated with a malformed payload)
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	exit 1
fi
#get current
sudo aws route53 list-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID | \
jq -r '.ResourceRecordSets[] | select (.Name == "'"$NAME"'") | select (.Type == "'"$TYPE"'") | .ResourceRecords[0].Value' > /tmp/current_route53_value
old_IP=$(cat /tmp/current_route53_value)

#check if IP is different from Route 53
if grep -Fxq "$IP" /tmp/current_route53_value; then
	echo "IP Has Not Changed, Exiting"
	echo "##########################################"
	exit 1
fi
echo "IP Changed, Updating Records"
echo "Old IP is: $old_IP"
echo "New IP is: $IP"

#prepare route 53 payload
cat > /tmp/route53_changes.json << EF
   {
      "Comment":"Updated From DDNS Checker Shell Script - Linux PC",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$IP"
              }
            ],
            "Name":"$NAME",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EF
#update records
sudo aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file:///tmp/route53_changes.json >> ~/ddns.log

sudo aws sns publish --topic-arn arn:aws:sns:eu-west-2:YourIDhere7047567:ip-changed --message "Docker-Server IP has changed from $old_IP to $IP. Route53 has been updated. Happy Days!! :)"
echo "##############################################"
EOF

#Give execution permission
sudo chmod +x ~/dns-checker.sh

#Add script into Crontab to run every hour
echo "0 *     * * *   root    ~/dns-checker.sh >> ~/dns.log 2>&1" >> /etc/crontab

#Start all containers
sudo docker-compose -f ~/configs/netdata/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/pihole/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/nginx/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/syncthing/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/portainer/docker-compose.yaml up -d
sudo docker-compose -f ~/configs/whoogle/docker-compose.yaml up -d