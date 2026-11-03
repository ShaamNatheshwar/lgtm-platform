pipeline {
  agent any
  environment {
    AWS_REGION = 'us-east-1'
    ECR_REPO   = 'lgtm-sample-app'
  }
  stages {
    stage('Validate') {
      steps {
        sh 'test -f app/Dockerfile'
        sh '''python3 -c "
import yaml, glob
files = glob.glob('**/*.yaml', recursive=True)
for f in files:
    list(yaml.safe_load_all(open(f)))
print('YAML OK:', len(files), 'files')
"'''
      }
    }
    stage('Build') {
      steps {
        sh 'docker build -t $ECR_REPO:$(echo $GIT_COMMIT | cut -c1-7) app'
      }
    }
    stage('Push to ECR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds',
                                          usernameVariable: 'AWS_ACCESS_KEY_ID',
                                          passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            TAG=$(echo $GIT_COMMIT | cut -c1-7)
            ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
            REG=$ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
            aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REG
            docker tag $ECR_REPO:$TAG $REG/$ECR_REPO:$TAG
            docker tag $ECR_REPO:$TAG $REG/$ECR_REPO:latest
            docker push $REG/$ECR_REPO:$TAG
            docker push $REG/$ECR_REPO:latest
          '''
        }
      }
    }
  }
}
