pipeline {
    agent any

    environment {
        REGISTRY       = "localhost:5000"
        IMAGE_NAME     = "kijani/kk-payments"
        STAGING_NS     = "kijani-staging"
        PROD_NS        = "default"
        K8S_DIR        = "k8s"
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
                        echo "Building image: ${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
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
                echo "Pushed: ${REGISTRY}/${IMAGE_NAME}:${env.IMAGE_TAG}"
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
                    def maxRetries = 5
                    def retryCount = 0
                    def passed = false

                    while (retryCount < maxRetries && !passed) {
                        def status = sh(
                            script: """
                                curl -s -o /dev/null -w "%{http_code}" \
                                http://kijani-staging.local/payments/health
                            """,
                            returnStdout: true
                        ).trim()

                        if (status == "200") {
                            echo "Smoke test passed — staging health endpoint returned 200"
                            passed = true
                        } else {
                            retryCount++
                            echo "Smoke test attempt ${retryCount}/${maxRetries} — got ${status}, retrying in 10s"
                            sleep 10
                        }
                    }

                    if (!passed) {
                        error "Smoke test FAILED after ${maxRetries} attempts — blocking production approval gate"
                    }
                }
            }
        }

        stage('Approval gate') {
            steps {
                script {
                    def approvalInput = input(
                        message: "Staging smoke test passed. Approve production deployment?",
                        parameters: [
                            string(
                                name: 'APPROVAL_REASON',
                                description: 'State the reason for approving this deployment',
                                defaultValue: ''
                            )
                        ],
                        submitterParameter: 'APPROVER'
                    )
                    echo "Production deployment approved by: ${approvalInput['APPROVER']}"
                    echo "Approval reason: ${approvalInput['APPROVAL_REASON']}"
                    env.APPROVER = approvalInput['APPROVER']
                    env.APPROVAL_REASON = approvalInput['APPROVAL_REASON']
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
                echo "Approved by: ${env.APPROVER} — ${env.APPROVAL_REASON}"
            }
        }
    }

    post {
        success {
            echo "Pipeline complete — ${env.IMAGE_TAG} deployed to production"
        }
        failure {
            echo "Pipeline FAILED — rolling back staging"
            sh """
                kubectl rollout undo deployment/kk-payments -n ${STAGING_NS} || true
            """
        }
    }
}
