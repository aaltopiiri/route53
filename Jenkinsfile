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


	stages {
    stage('Parameters'){
		when { anyOf
					{
						environment name: 'ACTION', value: 'plan';
					}
				}
                steps {
                    script {
                    properties([
                            parameters([
                                [$class: 'ChoiceParameter', 
                                    choiceType: 'PT_SINGLE_SELECT', 
                                    description: 'Select the Environemnt from the Dropdown List', 
                                    filterLength: 1, 
                                    filterable: false, 
                                    name: 'Env', 
                                    script: [
                                        $class: 'GroovyScript', 
                                        fallbackScript: [
                                            classpath: [], 
                                            sandbox: false, 
                                            script: 
                                                "return['Could not get The environemnts']"
                                        ], 
                                        script: [
                                            classpath: [], 
                                            sandbox: false, 
                                            script: 
                                                "return['dev','stage','prod']"
                                        ]
                                    ]
                                ],
                                [$class: 'CascadeChoiceParameter', 
                                    choiceType: 'PT_SINGLE_SELECT', 
                                    description: 'Select the AMI from the Dropdown List',
                                    name: 'AMI List', 
                                    referencedParameters: 'Env', 
                                    script: 
                                        [$class: 'GroovyScript', 
                                        fallbackScript: [
                                                classpath: [], 
                                                sandbox: false, 
                                                script: "return['Could not get Environment from Env Param']"
                                                ], 
                                        script: [
                                                classpath: [], 
                                                sandbox: false, 
                                                script: '''
                                                if (Env.equals("dev")){
                                                    return["ami-sd2345sd", "ami-asdf245sdf", "ami-asdf3245sd"]
                                                }
                                                else if(Env.equals("stage")){
                                                    return["ami-sd34sdf", "ami-sdf345sdc", "ami-sdf34sdf"]
                                                }
                                                else if(Env.equals("prod")){
                                                    return["ami-sdf34sdf", "ami-sdf34ds", "ami-sdf3sf3"]
                                                }
                                                '''
                                            ] 
                                    ]
                                ],
                                [$class: 'DynamicReferenceParameter', 
                                    choiceType: 'ET_ORDERED_LIST', 
                                    description: 'Select the  AMI based on the following infomration', 
                                    name: 'Image Information', 
                                    referencedParameters: 'Env', 
                                    script: 
                                        [$class: 'GroovyScript', 
                                        script: 'return["Could not get AMi Information"]', 
                                        script: [
                                            script: '''
                                                    if (Env.equals("dev")){
                                                        return["ami-sd2345sd:  AMI with Java", "ami-asdf245sdf: AMI with Python", "ami-asdf3245sd: AMI with Groovy"]
                                                    }
                                                    else if(Env.equals("stage")){
                                                        return["ami-sd34sdf:  AMI with Java", "ami-sdf345sdc: AMI with Python", "ami-sdf34sdf: AMI with Groovy"]
                                                    }
                                                    else if(Env.equals("prod")){
                                                        return["ami-sdf34sdf:  AMI with Java", "ami-sdf34ds: AMI with Python", "ami-sdf3sf3: AMI with Groovy"]
                                                    }
                                                    '''
                                                ]
                                        ]
                                ]
                            ])
                        ])
                    }
                }
            }

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