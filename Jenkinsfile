def projectName="cats-api"
def status
pipeline {
    agent any
    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    environment {
        NEXUS_CREDENTIALS = credentials('nexus')
    }

    stages {
        stage('Build'){
            steps{
                sh "mvn clean install -Dmaven.test.skip=true"
                sh 'docker build -t 172.22.119.181:8000/cats-api:latest .'
            }
        }

        stage('Test'){
            steps {
                script {
                    echo "Executing tests"
                    sh "mvn -Dmaven.test.failure.ignore=true test"

                    echo "Scanning code"
                    scannerHome = tool 'sonarqube-scanner'
                    withSonarQubeEnv('sonarqube') {
                      sh "${scannerHome}/bin/sonar-scanner -Dsonar.sources=src/main/java/ -Dsonar.java.binaries=. -Dsonar.host.url=http://sonarqube-server:9000 -Dsonar.projectKey=${projectName} -Dsonar.projectName=${projectName} -Dsonar.projectVersion=1.0 -Dsonar.language=java"
                    }

                    echo "Searching vulnerabilities"
                    sh "trivy image --format template --template '@/html.tpl' --ignore-unfixed --severity CRITICAL --exit-code 1 -o trivy-report.html 172.21.111.214:8000/cats-api:latest"

                }
            }
        }

        stage('Registry'){
            steps{
                sh 'echo $NEXUS_CREDENTIALS_PSW | docker login 172.21.111.214:8000 -u $NEXUS_CREDENTIALS_USR --password-stdin'
                sh 'docker push 172.22.119.181:8000/cats-api:latest'
            }
        }


        stage('Deploy') {
            steps {
                withCredentials(bindings: [string(credentialsId: 'kubernetes-jenkins-server-account', variable: 'api_token')]) {
                    sh "kubectl --token ${api_token} --server https://192.168.65.2:56403 --insecure-skip-tls-verify=true apply -f '2. deployment-openapi-app-jenkins.yaml' "
                }

          }
        }
    }

    post {
        always{
            sh 'docker logout'
            junit(testResults: 'target/surefire-reports/*.xml', allowEmptyResults : true)
        }

        success {
            echo "Success"
            script{
                status = "success"
                echo "final status ${status}"

            }
        }

        failure {
            echo "Failure"
            script {
                status = "failure"
            }
        }

        aborted {
            echo "Aborted"
            script {
                status = "aborted"
            }
        }

        cleanup {
           echo "Sending slack notification"
           script {
                echo "final status ${status}"
                def slackResponse = slackSend(color:"${status.equals('success') ? 'good' : 'danger'}", blocks: getBlockSlackMessage(projectName, status))
                slackUploadFile(channel: "#onurb-jenkins:" + slackResponse.ts, filePath: "trivy-report.html", initialComment:  "Trivy report.")


                echo "Remove docker image"
                //cleanWs()
                sh "docker image rm 172.22.119.181:8000/cats-api:latest"
            }
        }
    }
}


def getBlockSlackMessage(projectName, status){
    blocks = [
        [
            "type": "header",
            "text": [
                "type": "plain_text",
                "text": "Building application ${projectName} ${status}",
                "emoji": true
            ]
        ],
        [
            "type": "divider"
        ],
        [
            "type": "section",
            "text": [
                "type": "mrkdwn",
                "text": "Details of building in the next link :ghost: *if you want* you can see the results in Jenkins. <${env.BUILD_URL}|Open>"
            ],

            "fields": [
                [
                    "type": "mrkdwn",
                    "text": "*Job name*"
                ],
                [
                    "type": "plain_text",
                    "text": "${env.JOB_NAME}"
                ],
                [
                    "type": "mrkdwn",
                    "text": "*Build URL*"
                ],
                [
                    "type": "plain_text",
                    "text": "${env.BUILD_URL}"
                ],
                [
                    "type": "mrkdwn",
                    "text": "*Build number*"
                ],
                [
                    "type": "plain_text",
                    "text": "${env.BUILD_NUMBER}"
                ],
                [
                    "type": "mrkdwn",
                    "text": "*Build display name*"
                ],
                [
                    "type": "plain_text",
                    "text": "${env.BUILD_DISPLAY_NAME}"
                ],
                [
                    "type": "mrkdwn",
                    "text": "*Branch*"
                ],
                [
                    "type": "plain_text",
                    "text": "${env.GIT_BRANCH}"
                ]
            ]
        ],
        [
            "type": "header",
            "text": [
                "type": "plain_text",
                "text": "Reports",
                "emoji": true
            ]
        ],
        [
            "type": "divider"
        ],
        [
            "type": "section",
            "text": [
                "type": "mrkdwn",
                "text": "*SonarQube*"
            ],
            "accessory": [
                "type": "button",
                "text": [
                    "type": "plain_text",
                    "text": "Click Me",
                    "emoji": true
                ],
                "value": "click_me_123",
                "url": "http://localhost:9000/dashboard?id=${projectName}",
                "action_id": "button-action"
            ]
        ]
    ]

    return blocks;
}
