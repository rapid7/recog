@Library('jenkins-octo-shared-libraries@master') _
pipeline {
    agent {
        kubernetes(
            k8sAgent(name: 'ruby', rubyRuntime: '2.7', defaultContainer: 'ruby', idleMinutes: 0)
        )
    }

    parameters {
        booleanParam(name: 'RELEASE', defaultValue: false, description: 'Decide whether to release')
        choice(name: 'VERSION_BUMP', choices: ['patch', 'minor', 'major'], description: 'Which version to bump')
    }
    
    stages {
        stage('Install dependencies') {
            steps {
                sh 'gh --version'
                sh 'bundle install'
                sh 'gem install rake'
                sh 'wget -O semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.3.0/src/semver && chmod +x semver'
            }
        }

        stage('Run tests') {
            steps {
                sh 'bundle exec rake tests'
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

        stage('Zip recog-content') {
            steps {
                sh "zip -r recog-content-${VERSION}.zip xml"
            }
        }

        stage('Release') {
            when { 
                anyOf {
                    expression { params.RELEASE }
                }
            }

            stages {
                stage('')




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
