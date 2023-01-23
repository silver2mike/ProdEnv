pipeline {
  agent {label 'Ansible'}
  environment {
    ANSIBLE_PK = credentials('AWS-ProdServer-private-key')
  }
  stages {
    stage('AWS Env Provisioning by Terrsform') {
      steps {
        withCredentials([[
          $class:            'AmazonWebServicesCredentialsBinding', 
          credentialsId:     'AWS_Terraform', 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          
            sh '''
            terraform init
            terraform apply --auto-approve
            '''
       }
     }
   }
    
    stage('Update ProdServer by Ansible') {
      steps {
        withCredentials([[
          $class:            'AmazonWebServicesCredentialsBinding', 
          credentialsId:     'AWS_EC2_Inventory', 
          accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          
            sh 'ansible-playbook --private-key=$ANSIBLE_PK -i aws_ec2.yaml prod.yml'
            
        }
      }
    }
  }
}
