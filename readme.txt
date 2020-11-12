To build a test bed, several steps must be executed in sequence.
The next deployment step MUST ONLY be executed when the previous step is complete

1) deploy using the template "1-networks.json".
Most parameters have default values. You must enter a one-to-three letter ID for the landscape.
As you can deploy multiple landscapes (=playgrounds) which are independent of each other, this ID is used to distinguish between them. The ID will appear in all resource names.

2) navigate to the storage account you just created. This storage account will be named
«Location Code»st«Landscape»«storageaccountname». E.g. if you accept all defaults and use "xyz" for the landscape ID, the storage account resource will be named "euwstxyzmystor1"
Navigate to "Containers", "wamscripts", and upload the two powershell files.

3) deploy using the template "2-domainController.json.
Be sure to use the same landscape ID, also you need to provide a domain admin password

4) deploy using the template "2-appserver.json.
Be sure to use the same landscape ID, also you need to provide a local admin and a domain admin password
