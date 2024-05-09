#!/bin/bash
sudo yum update
sudo yum upgrade -y
sudo yum install ssh
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl restart ssh