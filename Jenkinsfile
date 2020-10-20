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
/* 		activeChoiceParam('Service') {
			description('Select service you wan to deploy')
            choiceType('SINGLE_SELECT')
            groovyScript {
                script('return ['web-service', 'proxy-service', 'backend-service']')
                fallbackScript('"fallback choice"')
            }
    } */
	}

	options([ 
    parameters([
        [$class: 'ChoiceParameter', choiceType: 'PT_SINGLE_SELECT', description: 'Select a choice', filterLength: 1, filterable: true, name: 'choice1', randomName: 'choice-parameter-7601235200970', script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: 'return ["ERROR"]'], script: [classpath: [], sandbox: false, script: 'return[\'aaa\',\'bbb\']']]], 
        [$class: 'CascadeChoiceParameter', choiceType: 'PT_SINGLE_SELECT', description: 'Active Choices Reactive parameter', filterLength: 1, filterable: true, name: 'choice2', randomName: 'choice-parameter-7601237141171', referencedParameters: 'choice1', script: [$class: 'GroovyScript', fallbackScript: [classpath: [], sandbox: false, script: 'return ["error"]'], script: [classpath: [], sandbox: false, script: 'if(choice1.equals("aaa")){return [\'a\', \'b\']} else {return [\'aaaaaa\',\'fffffff\']}']]]
    ])
])
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
						wrap([$class: 'AnsiColorBuildWrapper', $class: 'ChoiceParameter', colorMapName: 'xterm']) {

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
						wrap([$class: 'AnsiColorBuildWrapper', $class: 'ChoiceParameter', colorMapName: 'xterm']) {

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
						wrap([$class: 'AnsiColorBuildWrapper', $class: 'ChoiceParameter', colorMapName: 'xterm']) {
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