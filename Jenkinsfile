@Library('jenkins-octo-shared-libraries@master') _
s3ReleasePipeline(
    testCmd: [
        'Debug: install semver-tool': { 
            sh 'wget -O semver-tool https://raw.githubusercontent.com/fsaintjacques/semver-tool/3.3.0/src/semver '
            sh 'chmod +x semver-tool/semver'
            sh 'semver-tool/semver --version'
        }
    ]
)