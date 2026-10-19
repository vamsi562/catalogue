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
        stage('Test'){
            steps{
                script{
                    sh """
                        echo 'testing job'
                    """
                }
            }
        }
        stage('Deploy'){
            input {
                message "Should we continue?"
                ok "Yes, we should."
                submitter "alice,bob"
                parameters {
                    string(name: 'PERSON', defaultValue: 'Mr Jenkins', description: 'Who should I say hello to?')
                }
            }
            // when{
            //     expression { "${params.Deploy}" == "true" } // this stage will execute only if Deploy parameter is true
            // }
            steps{
                script{
                    sh """
                        echo 'Deploying Job'
                    """
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