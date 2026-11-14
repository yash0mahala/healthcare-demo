pipeline {
  // Configure this label on a Linux agent with Docker, kubectl, Python 3, Bash, and sed.
  agent { label 'linux-docker-k8s' }

  options {
    timestamps()
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  parameters {
    string(name: 'REGISTRY_HOST', defaultValue: 'docker.io', description: 'Container registry host')
    string(name: 'IMAGE_REPOSITORY', defaultValue: 'yash361/healthcare-demo', description: 'Repository path without registry host')
    string(name: 'DEPLOY_NAMESPACE', defaultValue: 'healthcare-demo', description: 'Kubernetes namespace')
  }

  environment {
    REGISTRY_HOST = "${params.REGISTRY_HOST}"
    IMAGE_REPOSITORY = "${params.IMAGE_REPOSITORY}"
    DEPLOY_NAMESPACE = "${params.DEPLOY_NAMESPACE}"
  }

  stages {
    stage('Prepare') {
      steps {
        script {
          env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(12)}"
          env.IMAGE = "${env.REGISTRY_HOST}/${env.IMAGE_REPOSITORY}:${env.IMAGE_TAG}"
        }
      }
    }

    stage('Test') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          python3 -m venv .venv
          . .venv/bin/activate
          pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt
          PYTHONPATH=. pytest -q
        '''
      }
    }

    stage('SAST') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          mkdir -p reports
          docker run --rm -v "$WORKSPACE:/src" returntocorp/semgrep:1.101.0 \
            semgrep scan --config p/owasp-top-ten --error --json --output /src/reports/semgrep.json /src
        '''
      }
    }

    stage('Dependency audit') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          . .venv/bin/activate
          pip-audit -r requirements.txt
        '''
      }
    }

    stage('Build image') {
      steps {
        sh 'docker build --pull --tag "$IMAGE" .'
      }
    }

    stage('Image vulnerability scan') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          mkdir -p reports
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$WORKSPACE/reports:/reports" \
            aquasec/trivy:0.58.1 image --exit-code 1 --ignore-unfixed --severity HIGH,CRITICAL \
            --format json --output /reports/trivy-image.json "$IMAGE"
        '''
      }
    }

    stage('SBOM') {
      steps {
        sh '''#!/usr/bin/env bash
          set -euo pipefail
          docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$WORKSPACE/reports:/reports" \
            aquasec/trivy:0.58.1 image --format cyclonedx --output /reports/sbom.cdx.json "$IMAGE"
        '''
      }
    }

    
stage('Publish image') {
  steps {
    withCredentials([
      usernamePassword(
        credentialsId: 'registry-credentials',
        usernameVariable: 'REGISTRY_USER',
        passwordVariable: 'REGISTRY_PASSWORD'
      )
    ]) {
      sh '''#!/usr/bin/env bash
        set -euo pipefail

        printf '%s' "$REGISTRY_PASSWORD" | docker login "$REGISTRY_HOST" \
          --username "$REGISTRY_USER" --password-stdin

        trap 'docker logout "$REGISTRY_HOST" >/dev/null 2>&1 || true' EXIT

        docker push "$IMAGE"
      '''
    }
  }
}


    stage('Blue-green deploy') {
      steps {
        sh 'bash scripts/deploy-blue-green.sh "$DEPLOY_NAMESPACE" "$IMAGE"'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'reports/*.json', allowEmptyArchive: true
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
}
