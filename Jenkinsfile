pipeline {
  agent any

  environment {
    AWS_REGION   = 'us-east-1'
    ECR_REGISTRY = '661193795121.dkr.ecr.us-east-1.amazonaws.com'
    ECR_REPO     = 'lgtm-sample-app'
  }

  stages {
    stage('Validate') {
      steps {
        sh 'test -f app/Dockerfile'
        // Every YAML file in the repo must parse
        sh '''python3 -c "
import yaml, glob
files = [f for f in glob.glob('**/*.yaml', recursive=True)]
for f in files:
    list(yaml.safe_load_all(open(f)))
print('YAML OK:', len(files), 'files')
"'''
      }
    }

    stage('Build') {
      steps {
        sh '''
          TAG=$(echo $GIT_COMMIT | cut -c1-7)
          docker build -t $ECR_REGISTRY/$ECR_REPO:$TAG -t $ECR_REGISTRY/$ECR_REPO:latest app
        '''
      }
    }

    stage('Push to ECR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            TAG=$(echo $GIT_COMMIT | cut -c1-7)
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
            docker push $ECR_REGISTRY/$ECR_REPO:$TAG
            docker push $ECR_REGISTRY/$ECR_REPO:latest
          '''
        }
      }
    }
  }
}
