pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh 'bundle config set deployment true'
                sh 'scripts/run_ci.sh'
            }
        }
    }
}
