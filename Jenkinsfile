node('osx') {
    withEnv(['PATH+LOCAL=/usr/local/bin:/Users/ddg/.fastlane/bin', 'LC_CTYPE=en_US.UTF-8', 'LC_ALL=en_US.UTF-8', 'LANG=en_US.UTF-8']) {  
        properties([pipelineTriggers([[$class: 'GitHubPushTrigger']])])
        stage('Checkout') {
           checkout scm
	   sh 'git clean -fdx'
	}
        stage('Test') {
	    sh 'xcodebuild test -quiet -project DuckDuckGo.xcodeproj -scheme DuckDuckGo'
	}
        stage('Build') {
            sh 'fastlane gym'
        }
        stage('Artifact') {
            sh 'tar czf DuckDuckGo.tar.gz DuckDuckGo.app'
            archiveArtifacts artifacts: 'DuckDuckGo.tar.gz'
        }
    }
}

