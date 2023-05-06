pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                // Build the Docker image and tag it with the Jenkins build number
                script {
                    def dockerImage = docker.build("myapp:${env.BUILD_NUMBER}")
                }

                // Push the Docker image to an ECR repository
                script {
                    def ecr = AmazonWebServicesClientBuilder.standard().withRegion('us-east-1').build().createECR()
                    def ecrCredentials = amazonECR(credentialsId: 'aws-credentials', region: 'us-east-1')
                    docker.withRegistry("https://029944322236.dkr.ecr.us-east-1.amazonaws.com/myapp", 'ecr') {
                        dockerImage.push()
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