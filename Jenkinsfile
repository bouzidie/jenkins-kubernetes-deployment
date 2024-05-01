pipeline {
  environment {
    dockerimagename = "bouzidieslem/itop:latest"
    dockerImage = ""
  }
  agent any
  stages {
    stage('Checkout Source') {
      steps {
        git 'https://github.com/bouzidie/jenkins-kubernetes-deployment.git'
      }
    }
    stage('Build image') {
      steps{
        script {
          dockerImage = docker.build bouzidieslem/itop:latest
        }
      }
    }
    stage('Pushing Image') {
      environment {
          registryCredential = 'dockerhub-credentials'
           }
      steps{
        script {
          docker.withRegistry( 'https://registry.hub.docker.com', registryCredential ) {
            dockerImage.push("latest")
          }
        }
      }
    }
    stage('Deploying itop container to Kubernetes') {
      steps {
        script {
          kubernetesDeploy(configs: "Deployment_itop.yaml", 
                                         "service_itop.yaml")
        }
      }
    }
  }
}
