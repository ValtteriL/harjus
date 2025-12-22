// Description: Jenkinsfile for building, testing, and releasing Harjus
pipeline {
    agent any
    environment {
      S3_BUCKET = 'harjus-artifacts-b38813ae'
      AWS_DEFAULT_REGION = 'ap-northeast-1'
      TAG_PATTERN = '^releases/\\d+\\.\\d+\\.\\d+$' // Regular expression for release tags (releases/x.y.z) where x, y, z are digits
      CCACHE_BASEDIR = "$WORKSPACE"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Quality') {
            steps {
                sh '''
                  nix-shell --run "
                    set -e

                    just fstack::release
                    just flashfix::release
                    just flashfix::test
                    just build
                    just test
                    "
                '''
            }
        }
        stage('Build') {
            when {
                anyOf {
                    branch 'main'; // Run on main branch
                    changeRequest target: 'main' // Run on pull requests targeting main
                    tag pattern: env.TAG_PATTERN, comparator: "REGEXP" // Run on tagged releases
                }
            }
            steps {
                sh '''
                  nix-shell --run "
                    set -e
                    
                    just build
                    "
                '''
            }
        }
        stage('Push') {
            when {
                anyOf {
                    branch 'main'; // Run on main branch
                    tag pattern: env.TAG_PATTERN, comparator: "REGEXP" // Run on tagged releases
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials']]) {
                  sh '''
                    nix-shell --run '
                        set -e

                        # Tag and push with commit hash and latest
                        nix-store --export $(nix-store --query --requisites ./result) | gzip > harjus-latest.nar.gzip
                        aws s3 cp harjus-latest.nar.gzip s3://${S3_BUCKET}/ --quiet

                        nix-build -A harjus --argstr version ${GIT_COMMIT}
                        nix-store --export $(nix-store --query --requisites ./result) | gzip > harjus-${GIT_COMMIT}.nar.gzip
                        aws s3 cp harjus-${GIT_COMMIT}.nar.gzip s3://${S3_BUCKET}/ --quiet
                    '
                  '''
                }
            }
        }
        stage('Release') {
            when {
                tag pattern: env.TAG_PATTERN, comparator: "REGEXP" // Run on tagged releases
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials']]) {
                  sh '''
                    nix-shell --run '
                        set -e

                        SEMVER_TAG=$(echo ${TAG_NAME} | sed "s/releases\\///")
                        just release ${SEMVER_TAG}
                        nix-store --export $(nix-store --query --requisites ./result) | gzip > harjus-${SEMVER_TAG}.nar.gzip
                        aws s3 cp harjus-${SEMVER_TAG}.nar.gzip s3://${S3_BUCKET}/ --quiet
                    '
                  '''
                }
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