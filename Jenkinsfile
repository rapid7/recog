@Library('jenkins-octo-shared-libraries@master') _
s3ReleasePipeline(
    testCmd = [
        'Debug: Try checkout semver-tool': { 
        checkout([
            $class: 'GitSCM',
            branches: [[name: 'refs/tags/3.3.0']],
            userRemoteConfigs: [[credentialsId: 'github-app-key', url: 'git@github.com:fsaintjacques/semver-tool.git']]
        ])
        sh 'ls -l'
    }]
)