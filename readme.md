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