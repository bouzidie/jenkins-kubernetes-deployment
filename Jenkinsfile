pipeline {
    agent any
    
    environment {
        dockerImage = "bouzidieslem/itop:latest"
        registryCredential = 'Dockerhub credential'
        kubernetesCredential = 'mykubeconfig'
    }
    
    stages {
        stage('Checkout Source') {
            steps {
                git credentialsId: 'Github credential', url: 'https://github.com/bouzidie/jenkins-kubernetes-deployment.git'
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    docker.build(dockerImage)
                }
            }
        }
        
        stage('Push Image to Docker Hub') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com', registryCredential) {
                        dockerImage.push()
                    }
                }
            }
        }
        
        stage('Deploy itop Container to Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: kubernetesCredential, variable: 'kubeconfig')]) {
                        kubernetesDeploy(configs: ["Deployment_itop.yaml", "service_itop.yaml"], kubeconfig: kubeconfig)
                    }
                }
            }
        }
    }
}
