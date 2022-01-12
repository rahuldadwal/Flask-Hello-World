Assignment 1: Flask app Hello World

To run this application we need to follow these steps:

1 we need to clone repository from given link:

-	git clone https://github.com/rahuldadwal07/Flask-Hello-World.git	#this will clone the flask app from github
-	git clone https://github.com/rahuldadwal07/terraform.git			#this will clone the terraform file from github
	
	
2 we need to build docker image

#NOTE: Please change this image url "710870128512.dkr.ecr.ap-south-1.amazonaws.com" with correct image url
#or we can copy these commands from ECR with correct image url

-	to retrieve an authentication token and authenticate your Docker client to your registry
	-	aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 710870128512.dkr.ecr.ap-south-1.amazonaws.com
	
-	Build Docker image	
	-	docker build -t python-flask .
	
-	tag image so we can push the image to this repository	
	-	docker tag python-flask:latest 710870128512.dkr.ecr.ap-south-1.amazonaws.com/python-flask:latest
	
-	push this image to your newly created AWS repository	
	-	docker push 710870128512.dkr.ecr.ap-south-1.amazonaws.com/python-flask:latest


3 To deploy AWS 

-	we need to make a change in terraform file "main.tf" in line number 173 and 178
	-	in line number 173 you need to replace arn "arn:aws:iam::710870128512:role/ecsTaskExecutionRole" with correct arn  of ecsTaskExecutionRole 
	-	in line number 178 you need to change image url "710870128512.dkr.ecr.ap-south-1.amazonaws.com/python-flask:latest" with correct image url


- Create IAM user with following policies attached

	-	AmazonECS_FullAccess
	-	AmazonECR_FullAccess
	-	AmazonVPCFullAccess
	-	ElasticLoadBalancingFullAccess

-	AWS configure
		- run "aws configure" with secret access key and access key of the created user


-	run	"terraform init"		
-	run	"terraform apply"


4	After deploying successfully we need to run following output command to check dns:

-	run "terraform output"

This will show the dns where application is running.
Copy that dns and paste it on browser it will run the application
