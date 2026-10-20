# Steps
1.As we run this pipeline from agent lets install below needed

    - after installing node js 20, sshd issue arises because of openssl istalled package different from upgrade. run below command
    - first query with   ``` sshd -t ``` -> found any discrepancy execute below commands else working fine
        ``` sudo less /var/log/cloud-init-output.log
            sudo dnf update -y openssl\* openssh\*
        ```
    
2.Install docker - required to for image generation
    ```
    dnf -y install dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    systemctl start docker
    systemctl enable docker
    usermod -aG docker ec2-user
    ```

3. use ECR for our images

- create a ECR repository & use commands as listed in aws
    ```
        aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 055610219795.dkr.ecr.us-east-1.amazonaws.com
        docker build -t roboshop/catalogue .
        docker tag roboshop/catalogue:latest 055610219795.dkr.ecr.us-east-1.amazonaws.com/roboshop/catalogue:latest
        docker push 055610219795.dkr.ecr.us-east-1.amazonaws.com/roboshop/catalogue:latest
    ```
install aws steps plugin, go to creds -> select aws credentials -> create
we will bind aws creds in jenkins pipeline using below
``` withAWS(credentials: 'aws-auth', region: 'us-east-1') ```

4.SonarQube:
- static source code analysis and static application security testing
installation - provision ec2 instance, install docker and run sonar qube container(***as sonar qube is costly***). Create route53 record for sonar.<domain_name> with public ip of sonar server
use instance type that have min of 2 GB RAM
**note - sonar server sg must allow inbound 9000 traffic from jenkins sg**
    ```
        sudo growpart /dev/nvme0n1 4
        sudo lvextend -L +30G /dev/mapper/RootVG-varVol
        sudo xfs_growfs /var
        docker run -d --name sonarqube-practice -p 9000:9000 sonarqube:community
    ```
access snarqube server -> sonar.<domain_name>:9000
login creds username and password admin -> change once logged in

Logged in -> generate token(my account-> security-> token) -> copy

In jenkins-> system -> sonarqube server -> provide name, server URL and add cred secret text with sonarqube token
