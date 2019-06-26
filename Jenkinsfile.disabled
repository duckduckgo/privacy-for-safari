pipeline {

    agent {
         label 'osx'
    }

    environment {
	PATH = "/usr/local/bin:/Users/ddg/.fastlane/bin:$PATH"
    }

    stages {
        stage('Checkout') { steps {
           checkout scm
	   sh 'git clean -fdx'
	} }
        stage('Test') { steps {
            sh 'xcodebuild clean'
            sh 'xcodebuild test -quiet -project DuckDuckGo.xcodeproj -scheme DuckDuckGo'
	} }
        stage('Build') { steps {
            sh 'fastlane run gym scheme:DuckDuckGo'
        } }
    }
    post {
        success {
            sh 'tar czf DuckDuckGo.tar.gz DuckDuckGo.app'
            archiveArtifacts artifacts: 'DuckDuckGo.tar.gz'
	}
        failure {
            emailext body: "You can see the build here: ${BUILD_URL}",
                     subject: "'${JOB_NAME}' (${BUILD_NUMBER}) failed 😭",
                     to: "brindy@duckduckgo.com"
        }
        fixed {
            emailext body: "You can see the build here: ${BUILD_URL}",
                     subject: "'${JOB_NAME}' (${BUILD_NUMBER}) is fixed 🎉",
                     to: "brindy@duckduckgo.com"

        }
    }
}
