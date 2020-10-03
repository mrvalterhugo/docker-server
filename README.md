# Simple Docker-Server
I have created this simple script file to quickly deploy my docker server with some containers in an Debian/Ubuntu enviroment.
It also has a dinamic DNS script to update DNS records in Route53.
If you want to use it, make sure you edit with your own settings.
You need to configure AWS CLI with IAM access key with permission to modify Route53 and SNS, you can also attach an IAM role to an EC2 instance.
The script comes with Pi-Hole, Netdata, Nginx, Syncthing, Portainer and Whoogle.
But you could add many more apps.
Make sure you firewall or Security Group allows ports 22 for SSH, 80 and 443 for Nginx and 53 TCP/UDP 67/UDP for Pi-hole
