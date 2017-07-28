#!groovy

import hudson.model.*
import jenkins.model.*
import hudson.plugins.ec2.*
import com.amazonaws.regions.Regions
import com.amazonaws.services.ec2.*
import com.amazonaws.services.ec2.model.*
import javaposse.jobdsl.plugin.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import java.util.logging.Logger
import static java.util.logging.Level.INFO

def main() {

  def jenkins = Jenkins.instance
  def keyPair = createJenkinsAgentKeyPair(jenkins)
  def privateKey = keyPair.keyMaterial
  configureSshCredentials(jenkins, privateKey)
  configureCloud(jenkins, privateKey)
  jenkins.save()
}

def getJenkinsAgentKeyPairPrefix() {
  System.getenv('JENKINS_AGENT_KEY_PAIR_PREFIX')
}

def getJenkinsAgentAmi() {
  System.getenv('JENKINS_AGENT_AMI')
}

def getJenkinsAgentRegion() {
  System.getenv('JENKINS_AGENT_REGION')
}

def getJenkinsAgentSubnetId() {
  System.getenv('JENKINS_AGENT_SUBNET_ID')
}

def getJenkinsAgentInstanceProfile() {
  System.getenv('JENKINS_AGENT_INSTANCE_PROFILE')
}

def getJenkinsAgentSecurityGroups() {
  System.getenv("JENKINS_AGENT_SECURITY_GROUPS")
}

def getJenkinsAgentName() {
  System.getenv('JENKINS_AGENT_NAME')
}

def getJenkinsCloudName() {
  System.getenv('JENKINS_CLOUD_NAME')
}

def createJenkinsAgentKeyPair(jenkins) {
  def jenkinsAgentKeyPairPrefix = getJenkinsAgentKeyPairPrefix()
  def jenkinsAgentKeyPair = "${jenkinsAgentKeyPairPrefix}-${UUID.randomUUID().toString()}"
  def region = getJenkinsAgentRegion()
  def amazonClient = new AmazonEC2Client().withRegion(Regions.fromName(region))
  def createKeyPairRequest = new CreateKeyPairRequest(jenkinsAgentKeyPair)
  def createKeyPairResult = amazonClient.createKeyPair(createKeyPairRequest)
  def keyPair = createKeyPairResult.keyPair
  keyPair
}

def configureSshCredentials(jenkins, privateKey) {
  def globalDomain = Domain.global()
  def credentialsStore = jenkins.getExtensionList(SystemCredentialsProvider)[0].getStore()
  def credentials = new BasicSSHUserPrivateKey(
    /* Scope */
    CredentialsScope.GLOBAL,
    /* ID */
    'jenkins-agent',
    /* Username */
    'jenkins',
    /* Private key source */
    new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(privateKey),
    /* Passphrase */
    '',
    /* Description */
    'Jenkins agent SSH key'
  )
  credentialsStore.addCredentials(globalDomain, credentials)
}

def configureCloud(jenkins, privateKey) {
  def jenkinsAgentAmi = getJenkinsAgentAmi()
  def jenkinsAgentRegion = getJenkinsAgentRegion()
  def jenkinsAgentSubnetId = getJenkinsAgentSubnetId()
  def jenkinsAgentInstanceProfile = getJenkinsAgentInstanceProfile()
  def jenkinsAgentSecurityGroups = getJenkinsAgentSecurityGroups()
  def jenkinsAgentName = getJenkinsAgentName()
  def jenkinsCloudName = getJenkinsCloudName()

  def linuxAgent = new SlaveTemplate(
    /* AMI */
    jenkinsAgentAmi,
    /* Availability zone */
    '',
    /* Spot configuration */
    null,
    /*  Security groups */
    jenkinsAgentSecurityGroups,
    /* Remote FS root */
    '/var/jenkins',
    /* Instance type */
    InstanceType.T2Nano,
    /* EBS optimized */
    false,
    /* Label string */
    '',
    /* Mode */
    null,
    /* Description */
    'Linux agent',
    /* Init script */
    '',
    /* Override temporary dir location */
    '',
    /* User data */
    '''\
      #!/bin/bash
      yum -y install git docker java-1.8.0-openjdk-devel
      update-alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java
      chkconfig docker on
      service docker start
      groupadd -g 1000 jenkins
      adduser -g jenkins -u 1000 -d /var/jenkins jenkins
      passwd -d jenkins
      mkdir /var/jenkins/.ssh
      cat /home/ec2-user/.ssh/authorized_keys >/var/jenkins/.ssh/authorized_keys
      chown -R jenkins:jenkins /var/jenkins /var/run/docker.sock
      chmod 700 /var/jenkins/.ssh
      chmod 600 /var/jenkins/.ssh/authorized_keys
    '''.stripIndent(),
    /* Number of executors */
    '8',
    /* Remote user */
    'jenkins',
    /* AMI type */
    new UnixData(
      /* Root command prefix */
      '',
      /* SSH port */
      '22'
    ),
    /* JVM options */
    '',
    /* Stop on termination */
    false,
    /* Subnet ID */
    jenkinsAgentSubnetId,
    /* Tags */
    [
      new EC2Tag(
        /* Key */
        'Name',
        /* Value */
        jenkinsAgentName
      )
    ],
    /* Idle termination minutes */
    '30',
    /* Use private DNS name */
    false,
    /* Instance cap */
    '',
    /* IAM instance profile */
    jenkinsAgentInstanceProfile,
    /* Use ephemeral devices */
    false,
    /* Use dedicated tenancy */
    false,
    /* Launch timeout */
    '',
    /* Associate public IP */
    false,
    /* Custom device mapping */
    '',
    /* Connect by SSH process */
    false,
    /* Connect using public IP */
    false
  )

  def cloud = new AmazonEC2Cloud(
    /* Cloud name */
    jenkinsCloudName,
    /* Use instance profile for credentials */
    true,
    /* Credentials ID */
    'jenkins-agent',
    /* Region */
    jenkinsAgentRegion,
    /* Private key */
    privateKey,
    /* Instance cap */
    '',
    /* Templates */
    [
      linuxAgent
    ]
  )

  jenkins.clouds.removeAll(cloud.getClass())
  jenkins.clouds.add(cloud)
}

main()
