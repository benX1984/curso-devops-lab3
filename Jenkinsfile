pipeline {
    agent any

    environment {
        APP_NAME = "lab3-app"
        DOCKER_IMAGE = "bmordoj/lab3-app"
        GHCR_IMAGE = "ghcr.io/benx1984/lab3-app"
        VERSION = "1.0.${BUILD_NUMBER}"

        SONAR_SERVER = "sonarqube"

        DOCKERHUB_CREDENTIALS = "docker-hub"
        GHCR_CREDENTIALS = "ghcr-token"

        K8S_NAMESPACE = "bmordoj"
        K8S_DEPLOYMENT = "lab3-app"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                url: 'https://github.com/benx1984/curso-devops-lab3.git'
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
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    withSonarQubeEnv("${SONAR_SERVER}") {
                        sh """
                        sonar-scanner \
                        -Dsonar.projectKey=lab3-devops \
                        -Dsonar.sources=src \
                        -Dsonar.host.url=http://sonarqube:9000 \
                        -Dsonar.token=${SONAR_TOKEN}
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

        stage('Docker Build') {
            steps {
                sh """
                docker build -t ${DOCKER_IMAGE}:${VERSION} .
                docker tag ${DOCKER_IMAGE}:${VERSION} ${DOCKER_IMAGE}:latest
                """
            }
        }

        stage('Docker Hub Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKERHUB_CREDENTIALS}",
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh """
                    echo $PASS | docker login -u $USER --password-stdin

                    docker push ${DOCKER_IMAGE}:${VERSION}
                    docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('GHCR Push') {
            steps {
                withCredentials([string(credentialsId: "${GHCR_CREDENTIALS}", variable: 'GHCR_TOKEN')]) {
                    sh """
                    echo $GHCR_TOKEN | docker login ghcr.io -u benx1984 --password-stdin

                    docker tag ${DOCKER_IMAGE}:${VERSION} ${GHCR_IMAGE}:${VERSION}
                    docker tag ${DOCKER_IMAGE}:${VERSION} ${GHCR_IMAGE}:latest

                    docker push ${GHCR_IMAGE}:${VERSION}
                    docker push ${GHCR_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy Kubernetes') {
            steps {
                sh """
                kubectl apply -f kubernetes.yaml

                kubectl set image deployment/${K8S_DEPLOYMENT} \
                app=${GHCR_IMAGE}:${VERSION} -n ${K8S_NAMESPACE}
                """
            }
        }
    }

    post {
        success {
            echo "✅ PIPELINE COMPLETO Y EXITOSO"
        }
        failure {
            echo "❌ PIPELINE FALLÓ - revisar logs"
        }
    }
}
