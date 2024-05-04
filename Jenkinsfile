pipeline {
    agent any
    
    environment {
        dockerImage = 'bouzidieslem/itop:latest'
    }
    
    stages {
        stage('Git Checkout') {
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
        
        stage('Deploy itop Container to Kubernetes') {
            steps {
                // Récupérer le fichier kubeconfig depuis Jenkins
                withCredentials([file(credentialsId: 'minikube-config', variable: 'KUBECONFIG')]) {
                    // Déployer l'application sur Kubernetes en utilisant le fichier kubeconfig
                    sh "kubectl apply -f Deployment_itop.yaml -f service_itop.yaml --kubeconfig=\$KUBECONFIG"
                }
            }
        }
    }
}
