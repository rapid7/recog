@Library('jenkins-octo-shared-libraries@master') _
pipeline {
    agent {
        kubernetes(
            k8sAgent(idleMinutes: 0)
        )
    }

    parameters {
        booleanParam(name: 'RELEASE', defaultValue: false, description: 'Decide whether to release')
        choice(name: 'VERSION_BUMP', choices: ['patch', 'minor', 'major'], description: 'Which version to bump')
    }
    
    stages {
        stage('Run tests') {
            when { expression { testCmd }}
            steps {
                sh 'rake tests'
            }
        }

        stage('Release') {
            when { 
                anyOf {
                    expression { params.RELEASE }
                }
            }

            stages {
                stage('Install semver-tool') {
                    steps {
                        sh 'wget -O semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.3.0/src/semver && chmod +x semver'
                    }
                }

                stage('Bump version') {
                    steps {
                        script {
                            echo 'Current version: \$(git describe --abbrev=0 | cut -c 2-)'
                            String newVersion = sh(script: "./semver bump ${params.VERSION_BUMP}", returnStdout: true).trim()
                            echo "${newVersion}"
                        }
                    }
                }
            }
            
            /**
            post {
                success {
                    script {
                        pipelineUtils.sendSlackNotification([message: "S3 Release to ${S3_RELEASE_DESTINATION} Successful", color: 'good'])
                    }
                }
                failure {
                    script {
                        pipelineUtils.sendSlackNotification([message: "S3 Release to ${S3_RELEASE_DESTINATION} failed", color: 'bad'])
                    }
                }
            }
            **/
        }
    }
}
