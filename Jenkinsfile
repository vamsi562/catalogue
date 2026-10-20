pipeline{
    // agent any - it will run job in master
    agent{
        node{
            label 'agent-1'
        }
    } // asking jenkins to run pipeline in agent-1 node
    environment{
        // environment variable declaration, which can be accessed across all stages
        Course = 'DevOps'
        appVersion = ''
        ACC_ID = '055610219795'
        PROJECT = 'roboshop'
        Component = 'catalogue'
    }
    options{
        timeout(time: 10, unit: 'MINUTES') // pipeline will be aborted if it takes more than 10 minutes to complete
        disableConcurrentBuilds() // if any build is running then next build will be in queue and will wait for previous build to complete
    }
    stages{
        stage('ReadVersion'){
            steps{
                script{
                        def packageJson = readJSON file: 'package.json'
                        appVersion = packageJson.version
                        echo "Application Version is ${appVersion}"
                }
                
            }
        }
        stage('Install Dependencies'){
            steps{
                script{
                    sh """
                        echo 'Installing dependencies'
                        npm install
                    """
                }
            }
        }
        stage('Build Image'){
            steps{
                script{
                    withAWS(credentials: 'aws-auth', region: 'us-east-1'){
                        sh """
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com
                            docker build -t ${PROJECT}/${Component} .
                            docker tag ${PROJECT}/${Component}:${appVersion} ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT}/${Component}:${appVersion}
                            docker push ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT}/${Component}:${appVersion}
                        """
                    }
                }
            }
        }
    }
    post{ // post deployment action - execute after above stages 
        always{ // this block will always execute after all stages whether success or failure
            cleanWs()
        }
        success{ // if all stages are successful then execute this block
            echo 'succeeded'
        }
        failure{ // if any stage fails then execute this block
            echo 'failed'
        }
        aborted{ // if any stage is aborted then execute this block
            echo 'aborted'
        }
    }
}