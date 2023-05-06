pipeline {
    agent any
    environment {
        DOCKER_IMAGE = "myapp:${env.BUILD_NUMBER}"
        ECR_REPOSITORY = "029944322236.dkr.ecr.us-east-1.amazonaws.com"
    }
    stages {
        stage('Build') {
            steps {
                script {
                    docker.build("${ECR_REPOSITORY}/${DOCKER_IMAGE}", ".")
                }
            }
        }
        stage('Push to ECR') {
            steps {
                // Authenticate with the ECR registry
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-credentials', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                    sh "aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ECR_REPOSITORY}"
                

                // Tag the Docker image with the ECR repository URL
                    script {
                        def image = docker.image("${ECR_REPOSITORY}/${DOCKER_IMAGE}")
                        image.push()
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
