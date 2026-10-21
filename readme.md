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
```
    stage('sonar scan'){
                environment{
                    def scannerHome = tool 'sonar-8.x' # tool which we installed under tools in manage jenkins
                }
                steps{
                    script{
                        withSonarQubeEnv('sonar-server'){ # sonar-server - defined under system, with sonar token and sonar resource URL
                            sh '${scannerHome}/bin/sonar-scanner'
                        }
                    }
                }
            }
```
sonar-poject.properties file - contains few details like project name, exclusions etc

In sonarqube, we can create a quality gate and make it default for testing. Though jenkins pipeline run successfully but in sonar project it failed

To make pipeline check quality gates in itself and fail if any issues, add stage quality gate
sonar qube to let know jenkins about quality gate - we need create a webhook
 administration -> configuration -> webhook -> create new
  name -> any name
  URL ->  http://<jenkins-url>/sonarqube-webhook/

  add below step in jenkins file
    ```
        stage('Quality Gate') {
            steps {
                // Pause pipeline and wait for SonarQube webhook response
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    ```

5.Dependabot integration
create webhook in repo and name as below
``` https://jenkins.chikoo.fun:8080//github-webhook/ ```


curl -I \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer <github_token>" \
  https://api.github.com/repos/daws-86s/catalogue/dependabot/alerts

6.trivy integration for image scan

installtion steps
    ```
        cat << EOF | sudo tee -a /etc/yum.repos.d/trivy.repo
        [trivy]
        name=Trivy repository
        baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
        gpgcheck=1
        enabled=1
        gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
        EOF
        sudo yum -y update
        sudo yum -y install trivy
    ```
(or)
    ```
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.76.0
    ```

command 
    ```
        trivy image \
        --scanners vuln \
        --severity HIGH,CRITICAL,MEDIUM \
        --pkg-types os \
        --exit-code 1 \
        --no-progress \
        --format table \
        <account_id>.dkr.ecr.us-east-1.amazonaws.com/roboshop/catalogue:1.0.0
    ```

add pipeline task after build image if any vulnerabilities detected it will fail pipeline