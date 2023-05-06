pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "myapp:${env.BUILD_NUMBER}"
        ECR_REPOSITORY = "029944322236.dkr.ecr.us-east-1.amazonaws.com/myapp"
    }

    stages {
        stage('Build') {
            steps {
                // Build the Docker image and tag it with the Jenkins build number
                script {
                    docker.build(DOCKER_IMAGE, "--build-arg BUILD_NUMBER=${env.BUILD_NUMBER} .")
                }
            }
        }

        stage('Push to ECR') {
            steps {
                // Authenticate with the ECR registry
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-credentials', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                }

                // Tag the Docker image with the ECR repository URL
                script {
                    def image = docker.image(DOCKER_IMAGE)
                    image.tag("${ECR_REPOSITORY}:${env.BUILD_NUMBER}")
                }

                // Push the Docker image to ECR
                script {
                    docker.withRegistry(ECR_REPOSITORY, 'ecr:us-east-1') {
                        def image = docker.image(DOCKER_IMAGE)
                        def tag = "${ECR_REPOSITORY}:${env.BUILD_NUMBER}"
                        image.push(tag)
                    }
                }
            }
        }

        stage('Test') {
            steps {
                sh 'echo "Test"'
            }
        }

        stage('Deploy') {
            steps {
                sh 'echo "Deploy"'
            }
        }

        stage('Monitor') {
            steps {
                sh 'echo "Monitor"'
            }
        }
    }
}
