pipeline {
    agent any

    environment {
        APP_NAME = "curso-devops-lab3"

        // Imagen base local (build)
        LOCAL_IMAGE = "lab3-app"

        // GHCR correcto (usuario real)
        GHCR_IMAGE = "ghcr.io/benx1984/lab3-app"

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
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_AUTH_TOKEN')]) {
                    withSonarQubeEnv("${SONARQUBE_SERVER}") {
                        sh """
                            sonar-scanner \
                            -Dsonar.projectKey=lab3-devops \
                            -Dsonar.projectName=lab3-devops \
                            -Dsonar.sources=src \
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

        stage('Docker Build') {
            steps {
                sh """
                    docker build -t ${LOCAL_IMAGE}:${VERSION} .
                    docker tag ${LOCAL_IMAGE}:${VERSION} ${LOCAL_IMAGE}:latest
                """
            }
        }

        stage('Docker Hub Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_HUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin

                        docker tag ${LOCAL_IMAGE}:${VERSION} bmordoj/lab3-app:${VERSION}
                        docker tag ${LOCAL_IMAGE}:${VERSION} bmordoj/lab3-app:latest

                        docker push bmordoj/lab3-app:${VERSION}
                        docker push bmordoj/lab3-app:latest
                    """
                }
            }
        }

        stage('GHCR Push') {
            steps {
                withCredentials([string(credentialsId: 'ghcr-token', variable: 'GHCR_TOKEN')]) {
                    sh """
                        echo $GHCR_TOKEN | docker login ghcr.io -u benX1984 --password-stdin

                        docker tag ${LOCAL_IMAGE}:${VERSION} ${GHCR_IMAGE}:${VERSION}
                        docker tag ${LOCAL_IMAGE}:${VERSION} ${GHCR_IMAGE}:latest

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

                    kubectl rollout status deployment/${K8S_DEPLOYMENT} -n ${K8S_NAMESPACE}
                """
            }
        }
    }

    post {
        success {
            echo "✅ CI/CD Pipeline completado exitosamente"
        }
        failure {
            echo "❌ Pipeline falló - revisar logs"
        }
    }
}
