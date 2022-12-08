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
        registryCredentials_ECR = 'ecr:us-east-1:cicdjenkins'
        imagename = "866308211434.dkr.ecr.us-east-1.amazonaws.com/zhajili_devops"
        applicationRegistry = 'https://866308211434.dkr.ecr.us-east-1.amazonaws.com'
    }

    stages{
        stage("PACKAGE THE APPLICATION"){
            //step to skip Unit Tests and pass parameters from settings.xml and install dependencies locally.
            steps {
              script{
                    sh "mvn -version"
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
        stage("Build Docker Image"){
            steps{
                script{
                    dockerImage = docker.build(imagename + ":$BUILD_ID" + "_$BUILD_TIMESTAMP",".")
                }
            }
        }
        stage("Upload Docker image to DockerHub"){
            steps{
                script{
                    docker.withRegistry ("",registryCredential_dockerhub){
                        dockerImage.push("$BUILD_ID")

                    }
                }
            }
        }
        stage("Upload Docker image to AWS ECR"){
            steps{
                script{
                    docker.withRegistry (applicationRegistry,registryCredentials_ECR){
                        dockerImage.push("$BUILD_ID")
                        dockerImage.push("latest")
                    }
                }
            }
        }
    }
    // post {
    // always {
    //     echo 'Slack Notifications.'
    //     slackSend channel: '#jenkins',
    //         color: COLOR_MAP[currentBuild.currentResult],
    //         message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
    //             }
    //         }
    }