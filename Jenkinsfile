def COLOR_MAP = [
    'SUCCESS': 'good', 
    'FAILURE': 'danger',
]
pipeline{
    agent any
    tools{
        maven "MAVEN3"
        jdk "JDK"
    }
    environment{
        registry_dockerhub = "zhajili/petclinic-app"
        registryCredential_dockerhub = 'dockerhub'
    }

    stages{
        stage("PACKAGE THE APPLICATION"){
            //step to skip Unit Tests and pass parameters from settings.xml and install dependencies locally.
            steps {
              script{
                    sh 'mvn -B -DskipTests clean package'
                }
              }
            post{
                success {
                echo "Now archiving"
                archiveArtifacts artifacts: '**/*.jar'

                }
            }
        }

        stage('BUILD DOCKER IMAGE FOR DOCKERHUB') { 
            steps { 
                script { 
                    dockerImage = docker.build registry_dockerhub + ":$BUILD_NUMBER" + "_$BUILD_TIMESTAMP"
                }
            } 
        }
        stage("Upload Docker image to DockerHub"){
            steps{
                script { 
                    docker.withRegistry( '', registryCredential_dockerhub ) { 
                        dockerImage.push() 
                    }
                } 
            }
        }
    }
    post {
    always {
        echo 'Slack Notifications.'
        slackSend channel: '#jenkins',
            color: COLOR_MAP[currentBuild.currentResult],
            message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
                }
            }
    }