// Description: Jenkinsfile for building, testing, and releasing Harjus
pipeline {
    agent any
    environment {
      ECR_REGISTRY = '137068223640.dkr.ecr.ap-northeast-1.amazonaws.com'
      ECR_REPOSITORY = 'harjus'
      AWS_DEFAULT_REGION = 'ap-northeast-1'
      TAG_PATTERN = '^releases/\\d+\\.\\d+\\.\\d+$' // Regular expression for release tags (releases/x.y.z) where x, y, z are digits
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
                  nix-shell --pure -A devEnv --run "
                    set -e
                    
                    cmake -B build
                    cmake --build build --config Debug --target all --
                    ctest -j8 -C Debug -T test --output-on-failure --test-dir build/
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
                sh 'nix-build'
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
                    set -e
                    IMAGE=$(docker image load -q < result-2 | awk '{print $3}')
                    
                    nix-shell -A devEnv --run "
                    set -e

                    # Login to ECR
                    aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REGISTRY}

                    # Tag and push with commit hash and latest
                    docker tag ${IMAGE} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT}
                            
                    docker tag ${IMAGE} ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    "
                  '''
                }
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
                
                  nix-shell --pure -A devEnv --run "
                    set -e

                    docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${SEMVER_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${SEMVER_TAG}
                    "
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