pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ACCOUNT_ID = '512190912096'
        ECR_REPO = 'petclinic-repo'
        IMAGE_TAG = 'latest'
        ECR_URI = "512190912096.dkr.ecr.eu-north-1.amazonaws.com/petclinic-repo"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/Vrushk13/SpringpetClinic.git'
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t petclinic:${IMAGE_TAG} ."
            }
        }

        stage('Login ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_URI}
                """
            }
        }

        stage('Tag Image') {
            steps {
                sh "docker tag petclinic:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}"
            }
        }

        stage('Push Image') {
            steps {
                sh "docker push ${ECR_URI}:${IMAGE_TAG}"
            }
        }
    }
}
