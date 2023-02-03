Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
sudo yum -y update
sudo yum install -y docker
sudo yum install -y ansible 
sudo git clone https://github.com/silver2mike/ProdEnv.git
ansible-playbook -i localhost stages.yml

 
#sudo yum -y install httpd
#myip=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
#cd ~
#sudo cat <<EOF > index.html
#<html>
#<body bgcolor="black">
#<h2><font color="gold">Build by Power of Terraform<font color="red">v1.01</font></h2><br><p>
#<font color="green">Server Private IP: <font color="aqua">$myip<br><br>
#<font color="magenta">
#<b>Version 3.0</b>
#</body>
#</html>
#EOF
#sudo rm -f /var/www/html/index.html
#sudo mv index.html /var/www/html/
#sudo systemctl start httpd
#sudo chkconfig httpd on

--//--
