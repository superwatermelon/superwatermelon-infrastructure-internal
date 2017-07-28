# Internal Infrastructure

- [Overview](#overview)
- [Deployment](#deployment)

## Overview

The internal infrastructure for Superwatermelon contains the build and
deployment pipeline tooling as well as the internal systems used to control
and monitor the different environments.

> **NOTE:** These templates create AWS resources that incur charges!

## Deployment

The `Makefile` handles the deployment of the infrastructure. The following
variables should be set.

<table>
  <tr>
    <th scope="row"><code>JENKINS_KEY_PAIR</code></th>
    <td>
      The name of the key pair to use for the Jenkins EC2 instance, if this
      key pair does not exist it will be created.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>GIT_KEY_PAIR</code></th>
    <td>
      The name of the key pair to use for the Git EC2 instance, if this key
      pair does not exist it will be created.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>TEST_IAM_ROLE</code></th>
    <td>
      The name of the IAM role used to deploy to the <strong>Test</strong>
      AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>STAGE_IAM_ROLE</code></th>
    <td>
      The name of the IAM role used to deploy to the <strong>Stage</strong>
      AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>LIVE_IAM_ROLE</code></th>
    <td>
      The name of the IAM role used to deploy to the <strong>Live</strong>
      AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>INTERNAL_TFSTATE_BUCKET</code></th>
    <td>
      The name of the S3 bucket used to hold the TFSTATE files for the
      <strong>Internal</strong> AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>TEST_TFSTATE_BUCKET</code></th>
    <td>
      The name of the S3 bucket used to hold the TFSTATE files for the
      <strong>Test</strong> AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>STAGE_TFSTATE_BUCKET</code></th>
    <td>
      The name of the S3 bucket used to hold the TFSTATE files for the
      <strong>Stage</strong> AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>LIVE_TFSTATE_BUCKET</code></th>
    <td>
      The name of the S3 bucket used to hold the TFSTATE files for the
      <strong>Live</strong> AWS account. This is setup as part of the
      [infrastructure][superwatermelon-infrastructure] project.
    </td>
  </tr>
  <tr>
    <th scope="row"><code>INTERNAL_HOSTED_ZONE</code></th>
    <td>
      The domain that is used for the internal private DNS resolution,
      this is used for split-horizon DNS queries. Use a subdomain that
      all internal services can hang from i.e.
      <code>internal.example.com</code>. In your public DNS set up a
      record to point your service, i.e. <code>git.internal.example.com</code>
      to the public IP.

      To take advantage of split-horizon without having the service
      trapped within the internal hosted zone, i.e.
      <code>git.example.com</code> instead of
      <code>git.internal.example.com</code>. In your public DNS set up a CNAME
      record to point <code>git.example.com</code> to
      <code>git.internal.example.com</code>.
    </td>
  </tr>
</table>

The default target will plan the changes required to bring the infrastructure
up to date. For the first run, the EBS volumes will need to be formatted, the
parameter flags `JENKINS_FORMAT_VOLUME` and `GIT_FORMAT_VOLUME` should be used
to do this.

```sh
JENKINS_FORMAT_VOLUME=true GIT_FORMAT_VOLUME=true make
```

For subsequent runs, the `JENKINS_FORMAT_VOLUME` and `GIT_FORMAT_VOLUME` flags
should be omitted and will default to `false`.

```sh
make
```

If any variables are missing you will see errors as follows:

```
Makefile:34: *** JENKINS_KEY_PAIR is undefined.  Stop.
```

Running this will output a Terraform plan file which can be used to bring up
the infrastructure to the correct state. The apply target will subsequently
apply the plan created from the previouscommand.

```sh
make apply
```

> **NOTE:** It is advisable to create snapshots of the EBS volumes before
running the `apply` target as it can be destructive.

```sh
aws ec2 create-snapshot --volume-id "..." --description "..."
```

[superwatermelon-infrastructure]: https://github.com/superwatermelon/infrastructure.git
