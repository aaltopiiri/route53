def tfCmd(String command, 
String options = ''
)
{
	ACCESS = "export AWS_PROFILE=${PROFILE} && export TF_ENV_profile=${PROFILE}"
	sh ("cd $WORKSPACE && ${ACCESS} && terraform init") // main
	sh ("cd $WORKSPACE && terraform workspace select ${ENV_NAME} || terraform workspace new ${ENV_NAME}")
	sh ("echo ${command} ${options}") 
    sh ("cd $WORKSPACE && ${ACCESS} && terraform init && terraform ${command} ${options} && terraform show -no-color > show-${ENV_NAME}.txt")
}



pipeline {
  agent any

	environment {
		AWS_DEFAULT_REGION = "${params.AWS_REGION}"
		PROFILE = "${params.PROFILE}"
		ACTION = "${params.ACTION}"
		DOMAIN_NAME = "${params.DOMAIN_NAME}"
		PROJECT_DIR = "terraform"
  }
	options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
  }
	parameters {
		choice (name: 'AWS_REGION',
				choices: ['us-west-1', 'us-west-2'],
				description: 'Pick A regions defaults to us-west-2')
		string (name: 'ENV_NAME',
			   defaultValue: 'tf-customer1',
			   description: 'Env name')
		string (name: 'DOMAIN_NAME',
			   description: 'Domain name')	   
		choice (name: 'ACTION',
				choices: [ 'plan', 'apply', 'destroy'],
				description: 'Run terraform plan / apply / destroy')
		string (name: 'PROFILE',
			   defaultValue: 'terraform',
			   description: 'Optional. Target aws profile defaults to terraform')
		
}

//Comment
	stages {

		stage('Checkout & Environment Prep'){
			steps {
				script {
					wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm'])  {8
							try {
								echo "Setting up Terraform"
								def tfHome = tool name: 'terraform-0.13.1',
									type: 'org.jenkinsci.plugins.terraform.TerraformInstallation'
									env.PATH = "${tfHome}:${env.PATH}"
									currentBuild.displayName += "[$AWS_REGION]::[$ACTION]"
									sh("""
										export AWS_PROFILE=${PROFILE}
										export TF_ENV_profile=${PROFILE}
										mkdir -p /tmp/jenkins/.terraform.d/plugins/macos
									""")
									tfCmd('version')
							} catch (ex) {
                                                                echo 'Err: Incremental Build failed with Error: ' + ex.toString()
								currentBuild.result = "UNSTABLE"
							}
					}
				}
			}
		}		
		stage('terraform plan') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'plan';
						environment name: 'ACTION', value: 'apply'
					}
				}
			steps {

				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {

								try {
									tfCmd('plan', '-var profile="${PROFILE}" -var region="us-west-2" -var domain_name="${DOMAIN_NAME}" -lock=false -detailed-exitcode -out=tfplan')
								} catch (ex) {
									if (ex == 2 && "${ACTION}" == 'apply') {
										currentBuild.result = "UNSTABLE"
									} else if (ex == 2 && "${ACTION}" == 'plan') {
										echo "Update found in plan tfplan"
									} else {
										echo "Try running terraform again in debug mode"
									}

							}
						}
					}
				}
			}
		}
		stage('terraform apply') {
			when { anyOf
					{
						environment name: 'ACTION', value: 'apply'
					}
				}
			steps {
				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {

								try {
									tfCmd('apply', '-lock=false tfplan')
								} catch (ex) {
                  currentBuild.result = "UNSTABLE"
								}
							}
					}
				}
			}

		}
		stage('terraform destroy') {    
			when { anyOf
					{
						environment name: 'ACTION', value: 'destroy';
					}
				}
			steps {
				script {
					def IS_APPROVED = input(
						message: "Destroy ${ENV_NAME} !?!",
						ok: "Yes",
						parameters: [
							string(name: 'IS_APPROVED', defaultValue: 'No', description: 'Think again!!!')
						]
					)
					if (IS_APPROVED != 'Yes') {
						currentBuild.result = "ABORTED"
						error "User cancelled"
					}
				}
				dir("${PROJECT_DIR}") {
					script {
						wrap([$class: 'AnsiColorBuildWrapper', colorMapName: 'xterm']) {
								try {
									tfCmd('destroy', '-var region="us-west-2" -var domain_name="${DOMAIN_NAME}" -lock=false -auto-approve')
								} catch (ex) {
									currentBuild.result = "UNSTABLE"
								}
						}
					}
				}
			}
		}	
  	}



}