pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh 'bundle config set deployment true'
                sh 'git submodule update --init --recursive'
                ansiColor('xterm') {
                    sh 'scripts/run_ci.sh'
                }
                junit 'fastlane/report.xml'
                publishHTML(target: [
                    reportDir: 'fastlane/coverage_report/Magnesium',
                    reportFiles: 'index.html',
                    reportName: "Magnesium coverage"
                ])
                publishHTML(target: [
                    reportDir: 'fastlane/coverage_report/Preferences',
                    reportFiles: 'index.html',
                    reportName: "Preferences coverage"
                ])
            }
        }
    }
    post {
        success {
            archiveArtifacts 'fastlane/build_output/*.ipa'
        }
        failure {
            step([
                $class: 'Mailer',
                notifyEveryUnstableBuild: true,
                recipients: 'james@jameshurst.ca',
                sendToIndividuals: false
                ])
        }
    }
}
