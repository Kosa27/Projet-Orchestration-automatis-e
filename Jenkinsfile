pipeline {
    agent any

    environment {
        TF_VAR_account_id = '991701732850'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Init') {
            steps { sh 'terraform init -input=false' }
        }
        
        stage('Plan ECS') {
            steps {
                sh 'terraform plan -target=module.ecs -out=plan-ecs -input=false'
            }
        }
        stage('Plan K8s') {
            steps {
                sh 'terraform plan -target=module.k8s -out=plan-k8s -input=false'
            }
        }
        stage('Approve') {
            steps {
                input message: 'Appliquer ECS + K8s ?', ok: 'Oui'
            }
        }
        stage('Apply ECS') {
            steps {
                sh 'terraform apply -auto-approve plan-ecs'
            }
        }
        stage('Apply K8s') {
            steps {
                sh 'terraform apply -auto-approve plan-k8s'
            }
        }
    }
    post {
        always { cleanWs() }
    }
}
stage('Validate') {
    steps {
        sh 'terraform fmt'
        sh 'terraform validate'
    }
}
