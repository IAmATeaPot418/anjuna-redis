# The Anjuna Runtime on Azure Confidential compute standard DCSv2 machines allows for encryption in memory using Intel SGX.

This script automates the deployment of Redis using the Anjuna Runtime.

## Requirements
- Microsoft Azure Confidentail Compute instance
  - Standard_DC4s_v2 (Any DC series should work)
  - OS Ubuntu 18.04 (Bionic)
  
## Files
Install.sh 

Install.sh will install the anjuna runtime agent and configure Redis in a secure Enclave.

# Test.sh

Test.sh will walk through a memory dump example and can be used to demonstrate that the anjuna runtime is helping to support encryption in use.
