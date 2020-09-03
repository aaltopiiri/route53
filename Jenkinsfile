pipeline {

agent any

  stages {

    stage('TF Plan') {
      steps {
          sh 'terraform init'
          sh '-var-file=variables.tfvars'
      }      
    }


    stage('TF Apply') {
      steps {
          sh 'terraform apply -input=false myplan'
      }
    }
  } 
}