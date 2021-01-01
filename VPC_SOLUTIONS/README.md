We need to terraform init -backend-config="config-name" in both of the Folders for Instance and Infrastructure respectively.
First we need to initialize the Infrastructure folder and do a terraform apply - this config init is for backend 
Next we need to initialize the Instance folder and do a terraform apply. - this init is for backend 

Use of this config init is that it stores the tf state file in 2 different folders.
Each folder has its own config which can be used to reference other resources by using data source.
