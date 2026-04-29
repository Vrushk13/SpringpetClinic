pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ACCOUNT_ID = '512190912096'
        ECR_REPO = 'petclinic-repo'
        IMAGE_TAG = 'latest'
        ECR_URI = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Vrushk13/SpringpetClinic.git'
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                """
            }
        }

        stage('AWS Login') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | \
                docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """
            }
        }

        stage('Push Image') {
            steps {
                sh "docker push ${ECR_URI}:${IMAGE_TAG}"
            }
        }

        stage('Deploy to ECS') {
    steps {
        sh """
        aws ecs update-service \
        --cluster petclinic-cluster \
        --service petclinic-service \
        --force-new-deployment \
        --region ${AWS_REGION}
        """
    }
}
    }
}
