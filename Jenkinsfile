pipeline {
  agent any

  triggers {
    githubPush()
  }

  environment {
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    AWS_REGION = 'ap-south-1'
  }

  stages {

    stage('Checkout') {
      steps {
        git branch: 'main',
            credentialsId: 'GITHUB_TOKEN',
            url: 'https://github.com/YOUR_USERNAME/YOUR_REPO.git'
      }
    }

    stage('Build') {
      steps {
        sh 'pip install -r requirements.txt'
      }
    }

    stage('Test') {
      steps {
        sh 'python -m pytest tests/ -v'
      }
    }

    stage('Docker Build') {
      steps {
        withCredentials([string(credentialsId: 'DOCKER_HUB_USER', variable: 'DOCKER_USER')]) {
          sh "docker build -t ${DOCKER_USER}/flask-app:${IMAGE_TAG} ."
        }
      }
    }

    stage('Image Scan') {
      steps {
        withCredentials([string(credentialsId: 'DOCKER_HUB_USER', variable: 'DOCKER_USER')]) {
          sh """
            trivy image \
              --exit-code 1 \
              --severity CRITICAL \
              --no-progress \
              ${DOCKER_USER}/flask-app:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'DOCKER_HUB_CREDS',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )
        ]) {
          sh """
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${DOCKER_USER}/flask-app:${IMAGE_TAG}
          """
        }
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        withCredentials([
          usernamePassword(
            credentialsId: 'DOCKER_HUB_CREDS',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
          )
        ]) {
          sh """
            aws eks update-kubeconfig --region ${AWS_REGION} --name flask-cluster

            kubectl apply -f k8s/namespace.yaml
            kubectl wait --for=jsonpath='{.status.phase}'=Active \
              namespace/flask-app --timeout=30s

            sed -i 's|IMAGE_PLACEHOLDER|${DOCKER_USER}/flask-app:${IMAGE_TAG}|g' k8s/deployment.yaml

            kubectl apply -f k8s/serviceaccount.yaml
            kubectl apply -f k8s/service.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl apply -f k8s/networkpolicy.yaml
            kubectl apply -f k8s/ingress.yaml
            kubectl apply -f k8s/hpa.yaml
            kubectl apply -f k8s/flask-servicemonitor.yaml

            kubectl rollout status deployment/flask-app -n flask-app --timeout=120s
          """
        }
      }
    }

  }

  post {
    success {
      echo "Deployed ${IMAGE_TAG} successfully"
    }
    failure {
      echo 'Pipeline failed — check stage logs above'
    }
    always {
      withCredentials([string(credentialsId: 'DOCKER_HUB_USER', variable: 'DOCKER_USER')]) {
        sh "docker rmi ${DOCKER_USER}/flask-app:${IMAGE_TAG} || true"
      }
    }
  }
}