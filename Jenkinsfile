/*
 * Jenkins pipeline file for JSON.sh, with zproject-inspired structure
 * Copyright (C) 2018 by Jim Klimov <jimklimov@gmail.com>
 */

// import jenkins.model.*
// import hudson.model.*
// @NonCPS
def testShell(String PATH_SHELL, String TAG_SHELL) {
    // Tests JSON.sh with the specified shell interpreter
    // (path to program and tag for reports and test dir name)
    def gotShell = false
    try {
        sh """ echo 'exit 0;' | ${PATH_SHELL} """
        gotShell = true
    } catch (Exception e) {
        currentBuild.result = 'UNSTABLE'
        manager.buildUnstable()
        error("This system does not seem to have the shell interpreter '${TAG_SHELL}' in PATH or by full filesystem name: '${PATH_SHELL}'")
        return null
    }
    if ( gotShell ) {
        dir("tmp/test-${TAG_SHELL}") {
            deleteDir()
            unstash 'prepped'
            timeout (time: "${params.USE_TEST_TIMEOUT}".toInteger(), unit: 'MINUTES') {
                sh """
if test -n "${params.DEBUG}" ; then DEBUG="${params.DEBUG}"; export DEBUG; fi && \
SHELL_PROGS="$PATH_SHELL" && export SHELL_PROGS && \
./all-tests.sh
"""
                sh """ echo "Are GitIgnores good after testing with '${TAG_SHELL}'? (should have no output below)"; make check-gitstatus || if [ "${params.REQUIRE_GOOD_GITIGNORE}" = false ]; then echo "WARNING GitIgnore tests found newly changed or untracked files" >&2 ; exit 0 ; else echo "FAILED GitIgnore tests" >&2 ; exit 1; fi """
            }
            script {
                if ( params.DO_CLEANUP_AFTER_BUILD ) {
                    deleteDir()
                }
            }
        }
    }
}

pipeline {
    agent { label "devel-image && x86_64" }
    parameters {
        // Use DEFAULT_DEPLOY_BRANCH_PATTERN and DEFAULT_DEPLOY_JOB_NAME if
        // defined in this jenkins setup -- in Jenkins Management Web-GUI
        // see Configure System / Global properties / Environment variables
        // Default (if unset) is empty => no deployment attempt after good test
        // See zproject Jenkinsfile-deploy.example for an example deploy job.
        // TODO: Try to marry MultiBranchPipeline support with pre-set defaults
        // directly in MultiBranchPipeline plugin, or mechanism like Credentials,
        // or a config file uploaded to master for all jobs or this job, see
        // https://jenkins.io/doc/pipeline/examples/#configfile-provider-plugin
        string (
            defaultValue: '${DEFAULT_DEPLOY_BRANCH_PATTERN}',
            description: 'Regular expression of branch names for which a deploy action would be attempted after a successful build and test; leave empty to not deploy. Reasonable value is ^(master|release/.*|feature/*)$',
            name : 'DEPLOY_BRANCH_PATTERN')
        string (
            defaultValue: '${DEFAULT_DEPLOY_JOB_NAME}',
            description: 'Name of your job that handles deployments and should accept arguments: DEPLOY_GIT_URL DEPLOY_GIT_BRANCH DEPLOY_GIT_COMMIT -- and it is up to that job what to do with this knowledge (e.g. git archive + push to packaging); leave empty to not deploy',
            name : 'DEPLOY_JOB_NAME')
        booleanParam (
            defaultValue: true,
            description: 'If the deployment is done, should THIS job wait for it to complete and include its success or failure as the build result (true), or should it schedule the job and exit quickly to free up the executor (false)',
            name: 'DEPLOY_REPORT_RESULT')
        string (
            defaultValue: "",
            description: 'When running tests, use this DEBUG value (as defined by JSON.sh, 99 is pretty verbose)',
            name: 'DEBUG')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a "make install" check in this run?',
            name: 'DO_TEST_INSTALL')
        string (
            defaultValue: "`pwd`/tmp/_inst",
            description: 'If attempting a "make install" check in this run, what DESTDIR to specify? (absolute path, defaults to "BUILD_DIR/tmp/_inst")',
            name: 'USE_TEST_INSTALL_DESTDIR')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_BASH')
        string (
            defaultValue: 'bash',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_BASH')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_ASH')
        string (
            defaultValue: 'ash',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_ASH')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_DASH')
        string (
            defaultValue: 'dash',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_DASH')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_ZSH')
        string (
            defaultValue: 'zsh',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_ZSH')
        booleanParam (
            defaultValue: true,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_BUSYBOX')
        string (
            defaultValue: 'busybox',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_BUSYBOX')
        booleanParam (
            defaultValue: false,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_KSH')
        string (
            defaultValue: 'ksh',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_KSH')
        booleanParam (
            defaultValue: false,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_KSH88')
        string (
            defaultValue: 'ksh88',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_KSH88')
        booleanParam (
            defaultValue: false,
            description: 'Attempt a test with specified shell interpreter in this run?',
            name: 'DO_TEST_SHELL_KSH93')
        string (
            defaultValue: 'ksh93',
            description: 'PATH-resolved or full path to the tested interpreter on the testing system',
            name: 'PATH_SHELL_KSH93')
        string (
            defaultValue: "5",
            description: 'When running tests, use this timeout (in minutes)',
            name: 'USE_TEST_TIMEOUT')
        booleanParam (
            defaultValue: true,
            description: 'When using temporary subdirs in build/test workspaces, wipe them after successful builds?',
            name: 'DO_CLEANUP_AFTER_BUILD')
    }
    triggers {
        pollSCM 'H/15 * * * *'
    }
    stages {
        stage ('prepare') {
            steps {
                dir("tmp") {
                    sh 'if [ -s Makefile ]; then make -k distclean || true ; fi'
                    sh 'chmod -R u+w .'
                    deleteDir()
                }
                stash (name: 'prepped', includes: '**/*', excludes: '**/cppcheck.xml')
            }
        }
        stage ('check') {
            parallel {
                stage ('check:bash') {
                    when { expression { return ( params.DO_TEST_SHELL_BASH ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_BASH, "bash")
                        }
                    }
                }
                stage ('check:dash') {
                    when { expression { return ( params.DO_TEST_SHELL_DASH ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_DASH, "dash")
                        }
                    }
                }
                stage ('check:ash') {
                    when { expression { return ( params.DO_TEST_SHELL_ASH ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_ASH, "ash")
                        }
                    }
                }
                stage ('check:zsh') {
                    when { expression { return ( params.DO_TEST_SHELL_ZSH ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_ZSH, "zsh")
                        }
                    }
                }
                stage ('check:busybox') {
                    when { expression { return ( params.DO_TEST_SHELL_BUSYBOX ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_BUSYBOX, "busybox-sh")
                        }
                    }
                }
                stage ('check:ksh') {
                    when { expression { return ( params.DO_TEST_SHELL_KSH ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_KSH, "ksh")
                        }
                    }
                }
                stage ('check:ksh88') {
                    when { expression { return ( params.DO_TEST_SHELL_KSH88 ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_KSH88, "ksh88")
                        }
                    }
                }
                stage ('check:ksh93') {
                    when { expression { return ( params.DO_TEST_SHELL_KSH93 ) } }
                    steps {
                        script {
                            testShell(params.PATH_SHELL_KSH93, "ksh93")
                        }
                    }
                }
                stage ('check:make install') {
                    when { expression { return ( params.DO_TEST_INSTALL ) } }
                    steps {
                        script {
                            dir("tmp/test-install-check") {
                                deleteDir()
                                unstash 'prepped'
                                timeout (time: "${params.USE_TEST_TIMEOUT}".toInteger(), unit: 'MINUTES') {
                                    sh """ make DESTDIR="${params.USE_TEST_INSTALL_DESTDIR}" install """
                                }
                                sh """ echo "Are GitIgnores good after make install? (should have no output below)"; make check-gitstatus || if [ "${params.REQUIRE_GOOD_GITIGNORE}" = false ]; then echo "WARNING GitIgnore tests found newly changed or untracked files" >&2 ; exit 0 ; else echo "FAILED GitIgnore tests" >&2 ; exit 1; fi """
                                script {
                                    if ( params.DO_CLEANUP_AFTER_BUILD ) {
                                        deleteDir()
                                    }
                                }
                            }
                        }
                    }
                } // stage:check:install
            } // parallel
        } // stage:check
        stage ('deploy if appropriate') {
            steps {
                script {
                    def myDEPLOY_JOB_NAME = sh(returnStdout: true, script: """echo "${params["DEPLOY_JOB_NAME"]}" """).trim();
                    def myDEPLOY_BRANCH_PATTERN = sh(returnStdout: true, script: """echo "${params["DEPLOY_BRANCH_PATTERN"]}" """).trim();
                    def myDEPLOY_REPORT_RESULT = sh(returnStdout: true, script: """echo "${params["DEPLOY_REPORT_RESULT"]}" """).trim().toBoolean();
                    echo "Original: DEPLOY_JOB_NAME : ${params["DEPLOY_JOB_NAME"]} DEPLOY_BRANCH_PATTERN : ${params["DEPLOY_BRANCH_PATTERN"]} DEPLOY_REPORT_RESULT : ${params["DEPLOY_REPORT_RESULT"]}"
                    echo "Used:     myDEPLOY_JOB_NAME:${myDEPLOY_JOB_NAME} myDEPLOY_BRANCH_PATTERN:${myDEPLOY_BRANCH_PATTERN} myDEPLOY_REPORT_RESULT:${myDEPLOY_REPORT_RESULT}"
                    if ( (myDEPLOY_JOB_NAME != "") && (myDEPLOY_BRANCH_PATTERN != "") ) {
                        if ( env.BRANCH_NAME =~ myDEPLOY_BRANCH_PATTERN ) {
                            def GIT_URL = sh(returnStdout: true, script: """git remote -v | egrep '^origin' | awk '{print \$2}' | head -1""").trim()
                            def GIT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --verify HEAD').trim()
                            build job: "${myDEPLOY_JOB_NAME}", parameters: [
                                string(name: 'DEPLOY_GIT_URL', value: "${GIT_URL}"),
                                string(name: 'DEPLOY_GIT_BRANCH', value: env.BRANCH_NAME),
                                string(name: 'DEPLOY_GIT_COMMIT', value: "${GIT_COMMIT}")
                                ], quietPeriod: 0, wait: myDEPLOY_REPORT_RESULT, propagate: myDEPLOY_REPORT_RESULT
                        } else {
                            echo "Not deploying because branch '${env.BRANCH_NAME}' did not match filter '${myDEPLOY_BRANCH_PATTERN}'"
                        }
                    } else {
                        echo "Not deploying because deploy-job parameters are not set"
                    }
                }
            }
        }
        stage ('cleanup') {
            when { expression { return ( params.DO_CLEANUP_AFTER_BUILD ) } }
            steps {
                deleteDir()
            }
        }
    } // stages
    post {
        success {
            script {
                if (currentBuild.getPreviousBuild()?.result != 'SUCCESS') {
                    // Uncomment desired notification

                    //slackSend (color: "#008800", message: "Build ${env.JOB_NAME} is back to normal.")
                    //emailext (to: "qa@example.com", subject: "Build ${env.JOB_NAME} is back to normal.", body: "Build ${env.JOB_NAME} is back to normal.")
                }
            }
        }
        failure {
            // Uncomment desired notification
            // Section must not be empty, you can delete the sleep once you set notification
            sleep 1
            //slackSend (color: "#AA0000", message: "Build ${env.BUILD_NUMBER} of ${env.JOB_NAME} ${currentBuild.result} (<${env.BUILD_URL}|Open>)")
            //emailext (to: "qa@example.com", subject: "Build ${env.JOB_NAME} failed!", body: "Build ${env.BUILD_NUMBER} of ${env.JOB_NAME} ${currentBuild.result}\nSee ${env.BUILD_URL}")
        }
    }
}
