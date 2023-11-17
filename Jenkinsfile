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

        stage('Build recog-content') {
            steps {
                script {
                    OLD_VERSION = sh(script: 'git describe --abbrev=0 | cut -c 2-', returnStdout: true).trim()
                    echo "Current version: ${OLD_VERSION}"

                    VERSION = sh(script: "./semver bump ${params.VERSION_BUMP} ${OLD_VERSION}", returnStdout: true).trim()
                    echo "New version: ${VERSION}"

                    sh "zip -r recog-content-${VERSION}.zip xml"
                }
            }
        }

        stage('Tag / Release') {
            when { 
                anyOf {
                    expression { params.RELEASE }
                }
            }

            stages {
                stage('Create Github tag') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'github-app-key', usernameVariable: 'GH_APP', passwordVariable: 'GH_TOKEN')]) {
                            setGitConfig()
                            sh """git tag -a "v${VERSION}" -m "Version ${VERSION}" && git push --tags"""
                        }
                    }
                }

                stage('Initialise Release') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'github-app-key', usernameVariable: 'GH_APP', passwordVariable: 'GH_TOKEN')]) { 
                            sh """
                                curl --silent --show-error \
                                    -H "Content-Type: application/json" \
                                    -H "Accept: application/vnd.github.v3+json" \
                                    -H "Authorization: token \${GH_TOKEN}" \
                                    -d '{"tag_name":"'"v${VERSION}"'", "generate_release_notes": true, "name": "'"v${VERSION} - \$(date +"%Y.%m.%d")"'"}' \
                                    https://api.github.com/repos/rapid7/recog/releases > recog-content-releases-response.json
                            """
                        }
                    }
                }

                stage('Process release response') {
                    steps {
                        script {
                            // Note: Inspect the response for error message since curl exits with code 0
                            // for the "Validation failed" response with status code 422 Unprocessable Entity
                            RELEASE_ERROR_MSG=sh( script: 'cat recog-content-releases-response.json | jq -r .message', returnStdout: true).trim()
                            echo "[DEBUG] RELEASE_ERROR_MSG = ${RELEASE_ERROR_MSG}"
                            if (RELEASE_ERROR_MSG != 'null') {
                                echo 'Failed to create release.'
                                sh 'cat recog-content-releases-response.json'
                                currentBuild.result = 'FAILURE'
                                return
                            }

                            echo "[DEBUG] Create release response:"
                            sh 'cat recog-content-releases-response.json'
                            echo "[DEBUG] upload_url:"
                            sh 'cat recog-content-releases-response.json | jq .upload_url'
                            echo "[DEBUG] processed upload_url:"
                            sh 'cat recog-content-releases-response.json | jq -r .upload_url | cut -f 1 -d "{"'

                            RELEASE_HTML_URL=sh(script: 'cat recog-content-releases-response.json | jq -r .html_url', returnStdout: true).trim()
                            echo "[*] Release v${VERSION} available at: ${RELEASE_HTML_URL}"

                            // Note: This returns an `upload_url` key corresponding to the endpoint for uploading release assets.
                            // This key is a [hypermedia resource](https://docs.github.com/rest/overview/resources-in-the-rest-api#hypermedia).
                            // All URLs are expected to be proper RFC 6570 URI templates.
                            UPLOAD_URL=sh(script: 'cat recog-content-releases-response.json | jq -r .upload_url | cut -f 1 -d "{"', returnStdout: true).trim()
                        }
                    }
                }

                stage('Upload release asset') {
                    steps {
                        withCredentials([usernamePassword(credentialsId: 'github-app-key', usernameVariable: 'GH_APP', passwordVariable: 'GH_TOKEN')]) { 
                            sh """
                                curl --silent --show-error \
                                    -H "Content-Type: application/zip" \
                                    -H "Accept: application/vnd.github.v3+json" \
                                    -H "Authorization: token \${GH_TOKEN}" \
                                    --data-binary @recog-content-${VERSION}.zip \
                                    "${UPLOAD_URL}?name=recog-content-${VERSION}.zip"
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
