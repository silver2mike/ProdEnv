// Update artefact version if new uploaded to DockerHub

pipeline {
	agent {label 'Ansible'}
	environment {
    		ANSIBLE_PK = credentials('AWS-ProdServer-private-key')
	}
  	stages {
// 		Ansible playbook with dynamic inventory
		stage('Update ProdServer, install and run Docker by Ansible') {
    		steps {
        		withCredentials([[
         		$class:            'AmazonWebServicesCredentialsBinding', 
	     		credentialsId:     'AWS_EC2_Inventory', 
    	  		accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
      			secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
	        		sh '''
           			ansible-playbook --private-key=$ANSIBLE_PK -i aws_ec2.yaml check.yml
				'''
	       		}
     		}
		}
	}
}		
