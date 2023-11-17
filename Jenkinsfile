@Library('jenkins-octo-shared-libraries@master') _
pipeline {
    agent {
        kubernetes(
            k8sAgent(name: 'ruby', rubyRuntime: '2.7', idleMinutes: 0)
        )
    }

    parameters {
        booleanParam(name: 'RELEASE', defaultValue: false, description: 'Decide whether to release')
        choice(name: 'VERSION_BUMP', choices: ['patch', 'minor', 'major'], description: 'Which version to bump')
    }
    
    stages {
        stage('Install dependencies') {
            steps {
                container('ruby') {
                    sh 'bundle install'
                    sh 'gem install rake'
                    sh 'wget -O semver https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.3.0/src/semver && chmod +x semver'
                }
            }
        }

        stage('Run tests') {
            steps {
                container('ruby') {
                    sh 'bundle exec rake tests'
                }
            }
        }

        stage('Bump version') {
            steps {
                script {
                    String currentVersion = sh(script: 'git describe --abbrev=0 | cut -c 2-', returnStdout: true).trim()
                    echo "${currentVersion}"

                    VERSION = sh(script: "./semver bump ${params.VERSION_BUMP} ${currentVersion}", returnStdout: true).trim()
                    echo "${VERSION}"
                }
            }
        }

        stage('Zip recog-content') {
            steps {
                sh "zip -r recog-content-${VERSION}.zip xml"
            }
        }

        stage('Tag / Release') {
            when { 
                anyOf {
                    expression { params.RELEASE }
                }
            }

            stages {
                stage('tag') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'github-app-key', usernameVariable: 'GH_APP', passwordVariable: 'GH_TOKEN')]) {
                            setGitConfig()
                            sh """git tag -a "v${VERSION}" -m "Version ${VERSION}" && git push --tags"""
                        }
                    }
                }

                stage('Release') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'github-app-key', usernameVariable: 'GH_APP', passwordVariable: 'GH_TOKEN')]) { 
                            sh """
                                curl --silent --show-error \
     -H "Content-Type: application/json" \
     -H "Accept: application/vnd.github.v3+json" \
     -H "Authorization: token ${GH_TOKEN}" \
     -d '{"tag_name":"'"v${VERSION}"'", "generate_release_notes": true, "name": "'"v${VERSION} - \$(date +"%Y.%m.%d")"'"}' \
     https://api.github.com/repos/rapid7/recog/releases > recog-content-releases-response.json
                            """
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
