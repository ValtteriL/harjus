// Description: Jenkinsfile for building, testing, and releasing Harjus
pipeline {
    agent any
    environment {
      ECR_REGISTRY = '137068223640.dkr.ecr.ap-northeast-1.amazonaws.com'
      ECR_REPOSITORY = 'harjus'
      AWS_DEFAULT_REGION = 'ap-northeast-1'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Quality') {
            steps {
                sh """
                  nix-shell --pure -A devEnv --run "
                    cmake -B build
                    cmake --build build --config Debug --target all --
                    ctest -j8 -C Debug -T test --output-on-failure --test-dir build/
                    "
                """
            }
        }
        stage('Build') {
            // Run on the main branch or when a pull request is made to the main branch
            when {
                anyOf {
                    branch 'main';
                    changeRequest target: 'main'
                }
            }
            steps {
                sh 'nix-build'
            }
        }
        stage('Push') {
            // Run on main
            when {
                branch 'main'
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials']]) {
                  sh """
                    nix-shell --pure -A devEnv --run "

                    # Login to ECR
                    aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR_REGISTRY}"

                    # Tag and push with commit hash and "latest"
                    IMAGE=\$(docker image load -q < result-2 | awk '{print \$3}')
                            
                    docker tag \$IMAGE ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT}
                            
                    docker tag \$IMAGE ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:latest
                    "
                  """
                }
            }
        }
        stage('Release') {
            // Run on main when tagged with a version
            // (theres a tag releases/x.y.z where x.y.v is a semver)
            when {
              allOf {
                branch 'main';
                tag pattern: '^releases/\\d+\\.\\d+\\.\\d+$', comparator: "REGEXP"
              }
            }
            steps {
                sh """
                  nix-shell --pure -A devEnv --run "
                    SEMVER_TAG=\$(echo ${TAG_NAME} | sed 's/releases\\////')

                    docker tag ${ECR_REGISTRY}/${ECR_REPOSITORY}:${GIT_COMMIT} ${ECR_REGISTRY}/${ECR_REPOSITORY}:${SEMVER_TAG}
                    docker push ${ECR_REGISTRY}/${ECR_REPOSITORY}:${SEMVER_TAG}
                    "
                """
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