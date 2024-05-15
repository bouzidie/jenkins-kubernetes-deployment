pipeline {
    agent any

    environment {
        dockerImage = 'bouzidieslem/itop:latest'
    }

    stages {
        stage('Git Checkout') {
            steps {
                // Checkout using the webhook token
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'webhookToken', url: 'https://github.com/bouzidie/jenkins-kubernetes-deployment.git']])
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
                withCredentials([file(credentialsId: 'minikube-config', variable: 'KUBECONFIG')]) {
                    sh "kubectl apply -f Deployment_itop.yaml -f service_itop.yaml --kubeconfig=\$KUBECONFIG"
                }
            }
        }

        stage('Setup Helm Repositories') {
            steps {
                script {
                    sh '''
                        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
                        helm repo add grafana https://grafana.github.io/helm-charts
                        helm repo update
                    '''
                }
            }
        }

        stage('Install or Update Prometheus') {
            steps {
                withCredentials([file(credentialsId: 'minikube-config', variable: 'KUBECONFIG')]) {
                    script {
                        sh '''
                            if helm list --kubeconfig=\$KUBECONFIG | grep -q prometheus; then
                                echo "Prometheus is already installed. Upgrading..."
                                helm upgrade prometheus prometheus-community/kube-prometheus-stack -f values.yaml --kubeconfig=\$KUBECONFIG
                            else
                                echo "Installing Prometheus..."
                                helm install prometheus prometheus-community/kube-prometheus-stack -f values.yaml --kubeconfig=\$KUBECONFIG
                            fi
                            kubectl expose service prometheus-kube-prometheus-prometheus --type=NodePort --target-port=9090 --name=prometheus-server-ext --kubeconfig=\$KUBECONFIG --dry-run=client -o yaml | kubectl apply -f - --kubeconfig=\$KUBECONFIG
                        '''
                    }
                }
            }
        }

        stage('Install or Update Grafana') {
            steps {
                withCredentials([file(credentialsId: 'minikube-config', variable: 'KUBECONFIG')]) {
                    script {
                        sh '''
                            if helm list --kubeconfig=\$KUBECONFIG | grep -q grafana; then
                                echo "Grafana is already installed. Upgrading..."
                                helm upgrade grafana grafana/grafana -f values.yaml --kubeconfig=\$KUBECONFIG
                            else
                                echo "Installing Grafana..."
                                helm install grafana grafana/grafana -f values.yaml --kubeconfig=\$KUBECONFIG
                            fi
                            kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-ext --kubeconfig=\$KUBECONFIG --dry-run=client -o yaml | kubectl apply -f - --kubeconfig=\$KUBECONFIG
                        '''
                    }
                }
            }
        }

        stage('Get Grafana Credentials') {
            steps {
                withCredentials([file(credentialsId: 'minikube-config', variable: 'KUBECONFIG')]) {
                    script {
                        sh '''
                            echo "Grafana Admin Password:"
                            kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" --kubeconfig=\$KUBECONFIG | base64 --decode ; echo
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Application, Prometheus, and Grafana deployed or updated successfully'
        }
        failure {
            echo 'Deployment failed'
        }
    }
}
