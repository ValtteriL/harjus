// Description: Jenkinsfile for building and testing Harjus
pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build') {
            steps {
                sh 'just fstack::release' // ensure fstack dependency is built
                sh 'just build'
            }
        }
        stage('Test') {
            steps {
                sh 'just test'
            }
        }
    }
    post {
        failure {
             mail (
                subject: "Failed Job: ${env.JOB_NAME} build ${env.BUILD_NUMBER}",
                body: "Failed CI job -> <a href=\"${env.BUILD_URL}\">${env.JOB_NAME} build ${env.BUILD_NUMBER}</a>",
                mimeType: 'text/html',
                to: "valtteri@shufflingbytes.com"
             )
        }
    }
}