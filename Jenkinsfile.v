// Validate Production AWS Infrastructure

pipeline {
  agent {label 'Ansible'}
  parameters {
    choice choices: ['validate', 'plan', 'build', 'destroy'], name: "CHOICE"
}
  environment {
    ANSIBLE_PK = credentials('AWS-ProdServer-private-key')
  }
  stages {
    stage('AWS Env ${CHOICE} by Terrsform') {
      steps {
        withCredentials([[
          $class:            'AmazonWebServicesCredentialsBinding', 
          credentialsId:     'AWS_Terraform', 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          
            sh '''
              terraform init
              terraform ${CHOICE}
            '''
            echo "${CHOICE}"
        }
      }
    }
  }
}
