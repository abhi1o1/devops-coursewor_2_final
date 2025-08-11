pipeline {
    agent any
    
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')
        IMAGE_NAME = 'abhiwable4/cw2-server'
        PRODUCTION_SERVER = '172.31.46.138'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker image: ${IMAGE_NAME}:${BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                    sh "docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Test Container Launch') {
            steps {
                script {
                    echo "Testing container launch..."
                    sh '''
                        # Clean up any existing test container
                        docker rm -f test-container-${BUILD_NUMBER} 2>/dev/null || true
                        
                        # Run container for testing
                        docker run -d --name test-container-${BUILD_NUMBER} -p 8082:8081 ${IMAGE_NAME}:${BUILD_NUMBER}
                        
                        # Wait for container to start
                        sleep 15
                        
                        # Test if container responds
                        curl -f http://localhost:8082 || exit 1
                        echo "Container test passed!"
                        
                        # Cleanup
                        docker stop test-container-${BUILD_NUMBER}
                        docker rm test-container-${BUILD_NUMBER}
                    '''
                }
            }
        }
        
        stage('Push to DockerHub') {
            steps {
                script {
                    echo "Pushing image to DockerHub..."
                    sh '''
                        echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                        docker push ${IMAGE_NAME}:${BUILD_NUMBER}
                        docker push ${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    echo "Deploying to Kubernetes..."
                    sh '''
                        ssh -o StrictHostKeyChecking=no ubuntu@${PRODUCTION_SERVER} "
                            export KUBECONFIG=/home/ubuntu/.kube/config
                            kubectl set image deployment/cw2-deployment cw2-server=${IMAGE_NAME}:${BUILD_NUMBER}
                            kubectl rollout status deployment/cw2-deployment --timeout=300s
                            kubectl get pods -l app=cw2-server
                        "
                    '''
                }
            }
        }
    }
    
    post {
        always {
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
            sh 'docker rm -f test-container-${BUILD_NUMBER} 2>/dev/null || true'
        }
    }
}
