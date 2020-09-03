pipeline {

agent any

  stages {

    stage('TF Plan') {
      steps {
          sh 'terraform init'
          sh 'terraform plan -var-file=variables.tfvars'
      }      
    }


    stage('TF Apply') {
      steps {
          sh 'terraform apply -var-file=variables.tfvars --auto-approve'
      }
    }
  } 
}