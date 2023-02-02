// Validate Production AWS Infrastructure

pipeline {
  agent {label 'Ansible'}
  parameters {
    choice choices: ['Validate', 'Plan', 'Build', 'Destroy'], name: "CHOICE"
}
  environment {
    ANSIBLE_PK = credentials('AWS-ProdServer-private-key')
  }
  stages {
    stage('AWS Env Destroy by Terrsform') {
      steps {
        withCredentials([[
          $class:            'AmazonWebServicesCredentialsBinding', 
          credentialsId:     'AWS_Terraform', 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          
            sh '''
              terraform init
              terraform validate
            '''
            echo "${param.CHOICE}"
        }
      }
    }
  }
}
