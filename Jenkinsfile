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
        stage('Unit Test'){
            steps{
                script{
                    sh """
                        echo 'Running unit tests'
                        npm test
                    """
                }

            }
        }
        stage('sonar scan'){
            environment{
                def scannerHome = tool 'sonar-8.x'
            }
            steps{
                script{
                    withSonarQubeEnv('sonar-server'){
                        sh '${scannerHome}/bin/sonar-scanner'
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                // Pause pipeline and wait for SonarQube webhook response
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        stage('Dependabot Security Gate') {
            environment {
                GITHUB_OWNER = 'vamsi562'
                GITHUB_REPO  = 'catalogue'
                GITHUB_API   = 'https://api.github.com'
                GITHUB_TOKEN = credentials('GITHUB_TOKEN')
            }

            steps {
                script{
                    /* Use sh """ when you want to use Groovy variables inside the shell.
                    Use sh ''' when you want the script to be treated as pure shell. */
                    sh '''
                    echo "Fetching Dependabot alerts..."

                    response=$(curl -s \
                        -H "Authorization: token ${GITHUB_TOKEN}" \
                        -H "Accept: application/vnd.github+json" \
                        "${GITHUB_API}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/dependabot/alerts?per_page=100")

                    echo "${response}" > dependabot_alerts.json

                    high_critical_open_count=$(echo "${response}" | jq '[.[] 
                        | select(
                            .state == "open"
                            and (.security_advisory.severity == "high"
                                or .security_advisory.severity == "critical")
                        )
                    ] | length')

                    echo "Open HIGH/CRITICAL Dependabot alerts: ${high_critical_open_count}"

                    if [ "${high_critical_open_count}" -gt 0 ]; then
                        echo "❌ Blocking pipeline due to OPEN HIGH/CRITICAL Dependabot alerts"
                        echo "Affected dependencies:"
                        echo "$response" | jq '.[] 
                        | select(.state=="open" 
                        and (.security_advisory.severity=="high" 
                        or .security_advisory.severity=="critical"))
                        | {dependency: .dependency.package.name, severity: .security_advisory.severity, advisory: .security_advisory.summary}'
                        exit 1
                    else
                        echo "✅ No OPEN HIGH/CRITICAL Dependabot alerts found"
                    fi
                    '''
                    
                }
            }
        }
        stage('Build Image'){
            steps{
                script{
                    withAWS(credentials: 'aws-auth', region: 'us-east-1'){
                        sh """
                            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com
                            docker build -t ${ACC_ID}.dkr.ecr.us-east-1.amazonaws.com/${PROJECT}/${Component}:${appVersion} .
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