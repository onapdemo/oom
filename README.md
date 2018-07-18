# OOM (ONAP Operations Manager)
This is a fork of OOM project in https://gerrit.onap.org

Master branch a clone of  Amsterdam release version.

To have a stable deployment on Azure cloud, several modifications has been made to the config parameters and deployment files.
Value charts are modified to deploy docker images built specifically to run vFW and vDNS use cases(Open lop) on Azure.

<b>Beijing Branch</b>

This repo is a clone of beijing release version of OOM project in ONAP gerrit.

The readiness and liveliness times of certain pods are increased so that the pods wont get restarted after the timeout and went to Unknown state
