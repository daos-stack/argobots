pipeline {
    agent none

    stages {
        stage('Lint') {
            stages {
                stage('RPM Lint') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos.7'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg UID=$(id -u)'
                            args  '--group-add mock --cap-add=SYS_ADMIN --privileged=true'
                        }
                    }
                    steps {
                        sh 'make rpmlint'
                    }
                }
            }
        }
        stage('Build') {
            parallel {
                stage('Build on CentOS 7') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.centos.7'
                            label 'docker_runner'
                            additionalBuildArgs '--build-arg UID=$(id -u) --build-arg JENKINS_URL=' +
                                                env.JENKINS_URL
                            args  '--group-add mock --cap-add=SYS_ADMIN --privileged=true'
                        }
                    }
                    steps {
                        sh '''rm -rf artifacts/centos7/
                              mkdir -p artifacts/centos7/
                              if make srpm; then
                                  if make mockbuild; then
                                      (cd /var/lib/mock/epel-7-x86_64/result/ &&
                                       cp -r . $OLDPWD/artifacts/centos7/)
                                      createrepo artifacts/centos7/
                                  else
                                      rc=\${PIPESTATUS[0]}
                                      (cd /var/lib/mock/epel-7-x86_64/result/ &&
                                       cp -r . $OLDPWD/artifacts/centos7/)
                                      cp -af _topdir/SRPMS artifacts/centos7/
                                      exit \$rc
                                  fi
                              else
                                  exit \${PIPESTATUS[0]}
                              fi'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'artifacts/centos7/**'
                        }
                    }
                }
                stage('Build on SLES 12.3') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.sles.12.3'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg UID=$(id -u) ' +
                                                 "--build-arg CACHEBUST=${currentBuild.startTimeInMillis}"
                        }
                    }
                    steps {
                        sh '''rm -rf artifacts/sles12.3/
                              mkdir -p artifacts/sles12.3/
                              rm -rf _topdir/SRPMS
                              if make srpm; then
                                  rm -rf _topdir/RPMS
                                  if make rpms; then
                                      ln _topdir/{RPMS/*,SRPMS}/*  artifacts/sles12.3/
                                      createrepo artifacts/sles12.3/
                                  else
                                      exit \${PIPESTATUS[0]}
                                  fi
                              else
                                  exit \${PIPESTATUS[0]}
                              fi'''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'artifacts/sles12.3/**'
                        }
                    }
                }
                stage('Build on Ubuntu 18.04') {
                    agent {
                        dockerfile {
                            filename 'Dockerfile.ubuntu.18.04'
                            label 'docker_runner'
                            additionalBuildArgs  '--build-arg UID=$(id -u) ' +
                                                 "--build-arg CACHEBUST=${currentBuild.startTimeInMillis}"
                        }
                    }
                    steps {
                        sh '''rm -rf artifacts/ubuntu18.04/
                              mkdir -p artifacts/ubuntu18.04/
                              mkdir -p _topdir
                              rm -rf _topdir/BUILD/
                              rm -rf _topdir/SOURCES
                              mkdir -p _topdir/BUILD
                              mkdir -p _topdir/SOURCES
                              : "${DEBEMAIL:="nomail@hpdd.intel.com"}"
                              : "${DEBFULLNAME:="Internal HPDD Devops"}"
                              : "${LANG:="C.UTF-8"}"
                              : "${LC_ALL:="C.UTF-8"}"
                              export DEBEMAIL
                              export DEBFULLNAME
                              export LANG
                              export LC_ALL
                              if make debs; then
                                  ln _topdir/BUILD/*{.build,.changes,.deb,.dsc,.gz}  artifacts/ubuntu18.04/
                                  pushd artifacts/ubuntu18.04/
                                    dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
                                  popd
                              else
                                  exit \${PIPESTATUS[0]}
                              fi'''
                        sh "cat _topdir/BUILD/*.build"
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'artifacts/ubuntu18.04/**'
                        }
                    }
                }
            }
        }
    }
}
