
# Simple Automated Docker-Server
> Main
- I have created this simple script file to quickly deploy my docker server with some containers in an Debian/Ubuntu enviroment.
- It also has a dinamic DNS script to update DNS records in Route53. You can run this from any Linux system.
- If you want to use it, make sure you edit with your own settings.
- You need to configure AWS CLI with IAM access key with permission to modify Route53 and SNS, you can also attach an IAM role to an EC2 instance.
- The script comes with Pi-Hole, Netdata, Nginx, Syncthing, Portainer and Whoogle.
- But you could add many more apps.
- Make sure you firewall or Security Group allows ports 22 for SSH, 80 and 443 for Nginx and 53 TCP/UDP 67/UDP for Pi-hole

> Sources:
- https://docs.docker.com/engine/install/ubuntu/
- https://nickjanetakis.com/blog/docker-tip-30-running-docker-compose-from-a-different-directory
- https://www.portainer.io/installation/
- https://github.com/pi-hole/docker-pi-hole/#running-pi-hole-docker
- https://dbtechreviews.com/2020/09/whoogle-installed-on-docker-your-own-private-google-search/
- https://learn.netdata.cloud/docs/agent/packaging/docker/
- https://docs.linuxserver.io/images/docker-projectsend
- https://docs.linuxserver.io/images/docker-rdesktop
- https://docs.linuxserver.io/images/docker-syncthing
- https://gist.github.com/dnburgess/756c4d7fca28c03be2d726b845e4cac6
- https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker
- https://nginxproxymanager.com/#quick-setup
- https://www.cloudsavvyit.com/3103/how-to-roll-your-own-dynamic-dns-with-aws-route-53/

