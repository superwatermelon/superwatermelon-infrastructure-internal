#!groovy

/*
 * Configures the master node.
 */

import hudson.model.*
import jenkins.model.*

def main() {
  def jenkins = Jenkins.instance
  disableMasterNodeBuilds(jenkins)
  configureLocation(jenkins)
  jenkins.save()
}

def getJenkinsUrl() {
  System.getenv('JENKINS_URL')
}

def getJenkinsAdminAddress() {
  System.getenv('JENKINS_ADMIN_ADDRESS')
}

def disableMasterNodeBuilds(jenkins) {
  jenkins.numExecutors = 0
}

def configureLocation(jenkins) {
  def config = jenkins.getDescriptorByType(JenkinsLocationConfiguration)
  config.url = getJenkinsUrl()
  config.adminAddress = getJenkinsAdminAddress()
  config.save()
}

main()
