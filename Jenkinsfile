pipeline {
    agent any

    environment {
        APP_NAME = "curso-devops-lab3"
        IMAGE_NAME = "bmordoj/lab3-app"
        VERSION = "1.0.${BUILD_NUMBER}"

        DOCKER_HUB_CREDENTIALS = "docker-hub"
        SONARQUBE_SERVER = "sonarqube"

        // FIX: asegurar acceso a sonar-scanner
        PATH = "/opt/sonar-scanner/bin:${env.PATH}"
    }

    stages {

        stage('Checkout GitHub') {
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
                            -Dsonar.host.url=http://host.docker.internal:9000 \
                            -Dsonar.login=$SONAR_AUTH_TOKEN
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${VERSION} .
                    docker tag ${IMAGE_NAME}:${VERSION} ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Docker Hub Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_HUB_CREDENTIALS}",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh """
                    docker push ${IMAGE_NAME}:${VERSION}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }

        stage('Notify Success') {
            steps {
                echo "✅ Pipeline finalizado correctamente: ${IMAGE_NAME}:${VERSION}"
            }
        }
    }

    post {
        success {
            echo "🎉 Build exitoso"
        }

        failure {
            echo "❌ Build falló"
        }

        always {
            cleanWs()
        }
    }
}
