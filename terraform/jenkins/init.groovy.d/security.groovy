#!groovy

/*
 * Disables script security. Use with caution.
 */

import hudson.model.*
import jenkins.model.*
import javaposse.jobdsl.plugin.*

def main() {
  def jenkins = Jenkins.instance
  disableJobDslScriptSecurity(jenkins)
  jenkins.save()
}

def isScriptSecurityDisabled() {
  System.getenv('JENKINS_SCRIPT_SECURITY') == 'off'
}

def disableJobDslScriptSecurity(jenkins) {
  def config = jenkins.getDescriptorByType(GlobalJobDslSecurityConfiguration)
  config.useScriptSecurity = !isScriptSecurityDisabled()
  config.save()
}

main()
