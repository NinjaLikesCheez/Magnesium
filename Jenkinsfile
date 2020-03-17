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
                    reportDir: 'fastlane/coverage_report',
                    reportFiles: 'index.html',
                    reportName: "Code Coverage"
                ])
            }
        }
    }
    post {
        success {
            archiveArtifacts 'fastlane/build_output/*.ipa'
        }
        always {
            step([
                $class: 'Mailer',
                notifyEveryUnstableBuild: true,
                recipients: "$MAIL_RECIPIENTS",
                sendToIndividuals: false
                ])
        }
    }
}
