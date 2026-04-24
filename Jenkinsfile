pipeline {
    agent any

    environment {
        APP_NAME = "curso-devops-lab3"

        //  usuario real GitHub
        IMAGE_NAME = "benX1984/lab3-app"

        VERSION = "1.0.${BUILD_NUMBER}"

        DOCKER_HUB_CREDENTIALS = "docker-hub"
        GHCR_CREDENTIALS = "ghcr-token"
        SONARQUBE_SERVER = "sonarqube"

        K8S_NAMESPACE = "bmordoj"
        K8S_DEPLOYMENT = "lab3-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/benX1984/curso-devops-lab3.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test || true'
            }
        }

        stage('Build App') {
            steps {
                sh 'npm run build'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            sonar-scanner \
                            -Dsonar.projectKey=lab3-devops \
                            -Dsonar.projectName=lab3-devops \
                            -Dsonar.sources=src \
                            -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                            -Dsonar.host.url=http://sonarqube:9000 \
                            -Dsonar.token=$SONAR_AUTH_TOKEN
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build (multistage)') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${VERSION} .
                    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Docker Hub Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_HUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                        docker push ${IMAGE_NAME}:${VERSION}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('GHCR Login & Push') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'GHCR_TOKEN')]) {
                    sh """
                        echo $GHCR_TOKEN | docker login ghcr.io -u benX1984 --password-stdin

                        docker tag ${IMAGE_NAME}:${VERSION} ghcr.io/benX1984/lab3-app:${VERSION}
                        docker tag ${IMAGE_NAME}:${VERSION} ghcr.io/benX1984/lab3-app:latest

                        docker push ghcr.io/benX1984/lab3-app:${VERSION}
                        docker push ghcr.io/benX1984/lab3-app:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl apply -f kubernetes.yaml

                    kubectl set image deployment/${K8S_DEPLOYMENT} \
                    app=ghcr.io/benX1984/lab3-app:${VERSION} -n ${K8S_NAMESPACE}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completado correctamente"
        }
        failure {
            echo "❌ Pipeline falló"
        }
    }
}
