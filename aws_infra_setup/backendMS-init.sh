cd /home/ubuntu/

sudo apt-get update -y
sudo apt-get install -y ansible unzip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -R aws 
rm awscliv2.zip