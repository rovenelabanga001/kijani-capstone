pipeline {
    agent any

    environment {
        REGISTRY   = "localhost:5000"
        IMAGE_NAME = "kijani/kk-payments"
        STAGING_NS = "kijani-staging"
        PROD_NS    = "default"
    }

    stages {
        stage('Build') {
            steps {
                dir('payments') {
                    script {
                        def pkgVersion = sh(
                            script: "node -p \"require('./package.json').version\"",
                            returnStdout: true
                        ).trim()
                        def gitShort = sh(
                            script: "git rev-parse --short HEAD",
                            returnStdout: true
                        ).trim()
                        env.IMAGE_TAG = "${pkgVersion}-${gitShort}"
                        echo "Building: ${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
                    sh """
                        docker build \
                            -f Dockerfile.production \
                            -t ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} \
                            .
                    """
                }
            }
        }

        stage('Push') {
            steps {
                sh "docker push ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG}"
                echo "Pushed: ${env.IMAGE_TAG}"
            }
        }

        stage('Deploy to staging') {
            steps {
                sh """
                    kubectl set image deployment/kk-payments \
                        kk-payments=${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} \
                        -n ${STAGING_NS}
                    kubectl rollout status deployment/kk-payments \
                        -n ${STAGING_NS} \
                        --timeout=120s
                """
            }
        }

        stage('Smoke test') {
            steps {
                script {
                    def passed = false
                    for (int i = 1; i <= 5; i++) {
                        def status = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://kijani-staging.local/payments/health",
                            returnStdout: true
                        ).trim()

                        if (status == "200") {
                            echo "Smoke test passed on attempt ${i}"
                            passed = true
                            break
                        }
                        echo "Attempt ${i}/5 — got ${status}, waiting 10s"
                        sleep 10
                    }

                    if (!passed) {
                        echo "Smoke test failed — running AI diagnosis"
                        withCredentials([string(credentialsId: 'anthropic-api-key',
                                               variable: 'ANTHROPIC_API_KEY')]) {
                            sh "bash scripts/diagnose-failure.sh ${STAGING_NS}"
                        }
                        error "Smoke test failed — review AI diagnosis above before taking action"
                    }
                }
            }
        }

        stage('Approval gate') {
            steps {
                script {
                    def approval = input(
                        message: "Smoke test passed. Approve production deployment?",
                        parameters: [
                            string(
                                name: 'REASON',
                                description: 'Why are you approving this deployment?',
                                defaultValue: ''
                            )
                        ],
                        submitterParameter: 'APPROVER'
                    )
                    echo "Approved by: ${approval['APPROVER']}"
                    echo "Reason: ${approval['REASON']}"
                    env.APPROVER = approval['APPROVER']
                    env.REASON = approval['REASON']
                }
            }
        }

        stage('Deploy to production') {
            steps {
                sh """
                    kubectl set image deployment/kk-payments \
                        kk-payments=${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG} \
                        -n ${PROD_NS}
                    kubectl rollout status deployment/kk-payments \
                        -n ${PROD_NS} \
                        --timeout=120s
                """
                echo "Production deployment complete: ${env.IMAGE_TAG}"
                echo "Approved by: ${env.APPROVER} — ${env.REASON}"
            }
        }
    }

    post {
        success {
            echo "Pipeline complete — ${env.IMAGE_TAG} is live in production"
        }
        failure {
            echo "Pipeline failed — rolling back staging"
            sh "kubectl rollout undo deployment/kk-payments -n ${STAGING_NS} || true"
        }
    }
}
