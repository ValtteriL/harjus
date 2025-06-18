// Description: Jenkinsfile for building, testing, and releasing Harjus
pipeline {
    agent any
    environment {
      ECR_REGISTRY = '137068223640.dkr.ecr.ap-northeast-1.amazonaws.com'
      ECR_REPOSITORY = 'harjus'
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
                  nix-shell -A devEnv --run "
                    set -e
                    
                    cmake -B build -G Ninja
                    ninja -C build -j$(nproc)
                    ctest -j$(nproc) -C Debug -T test --output-on-failure --test-dir build/
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
                sh 'nix-build -A harjus'
            }
        }
        stage('Release') {
            when {
                tag pattern: env.TAG_PATTERN, comparator: "REGEXP" // Run on tagged releases
            }
            steps {
                sh '''
                set -e
                
                SEMVER_TAG=$(echo ${TAG_NAME} | sed 's/releases\\///')
                nix-build -A harjus --argstr version "${SEMVER_TAG}"
                '''
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