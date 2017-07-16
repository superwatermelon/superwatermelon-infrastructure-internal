#!groovy

/*
 * Generates a SSH key for Jenkins to use and adds the SSH key
 * into the Jenkins credentials store.
 */

import hudson.model.*
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*

def main() {
  def jenkins = Jenkins.instance
  generateSshKey()
  configureSshCredentials(jenkins)
  jenkins.save()
}

def generateSshKey() {
  def home = System.getenv 'HOME'
  def out = new StringBuffer()
  def err = new StringBuffer()
  def privateKey = new File("${home}/.ssh/id_rsa")

  if (!privateKey.exists()) {
    def sshKeyGen = [
      "ssh-keygen",
      "-t", "rsa",
      "-N", "",
      "-C", "jenkins",
      "-f", "${home}/.ssh/id_rsa"
    ].execute()
    sshKeyGen.consumeProcessOutput(out, err)
    sshKeyGen.waitFor()
  }
}

def configureSshCredentials(jenkins) {
  def globalDomain = Domain.global()
  def credentialsStore = jenkins.getExtensionList(SystemCredentialsProvider)[0].getStore()
  def credentials = new BasicSSHUserPrivateKey(
    /* Scope */
    CredentialsScope.GLOBAL,
    /* ID */
    'git',
    /* Username */
    'git',
    /* Private key source */
    new BasicSSHUserPrivateKey.UsersPrivateKeySource(),
    /* Passphrase */
    '',
    /* Description */
    'Git SSH key'
  )
  credentialsStore.addCredentials(globalDomain, credentials)
}

main()
