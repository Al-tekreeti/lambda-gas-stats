.PHONY: clean create-bucket-name fetch-dependencies docker-build docker-run lambda-build lambda-deploy

## delete build files
clean:		
	@rm -rf package

# to ensure name uniqueness
create-bucket-name:
	BUCKET_ID=$(dd if=/dev/random bs=8 count=1 2>/dev/null | od -An -tx1 | tr -d ' \t\n')
	BUCKET_NAME=lambda-$(BUCKET_ID);\
	echo $(BUCKET_NAME) > bucket-name.txt


fetch-dependencies:		## download chromedriver, headless-chrome to `./bin/`
	@mkdir -p bin/

	# Get chromedriver
	curl -SL https://chromedriver.storage.googleapis.com/2.37/chromedriver_linux64.zip > chromedriver.zip
	
	unzip chromedriver.zip -d bin/

	# Get Headless-chrome
	curl -SL https://github.com/adieuadieu/serverless-chrome/releases/download/v1.0.0-41/stable-headless-chromium-amazonlinux-2017-03.zip > headless-chromium.zip

	unzip headless-chromium.zip -d bin/

	# Clean
	@rm headless-chromium.zip chromedriver.zip

## prepares dependencies for AWS Lambda deploy 
lambda-build: clean fetch-dependencies
	mkdir package package/python package/python/lib
	cp -r bin package/python/.
	pip install --target package/python/lib/. -r requirements.txt

## deploy Lambda function
lambda-deploy:
	ARTIFACT_BUCKET=$(cat bucket-name.txt)
	aws cloudformation package --template-file template.yml --s3-bucket $ARTIFACT_BUCKET --output-template-file out.yml

	aws cloudformation deploy --template-file out.yml --stack-name gas-station-scraper --parameter-overrides BucketName=$ARTIFACT_BUCKET --capabilities CAPABILITY_NAMED_IAM
		
## cleanup resources after finish
lambda-remove:
	STACK=gas-station-scraper
	if [[ $# -eq 1 ]] ; then
		STACK=$1
		echo "Deleting stack $STACK"
	fi
	FUNCTION=$(aws cloudformation describe-stack-resource --stack-name $STACK --logical-resource-id function --query 'StackResourceDetail.PhysicalResourceId' --output text)
	aws cloudformation delete-stack --stack-name $STACK
	echo "Deleted $STACK stack."

	if [ -f bucket-name.txt ]; then
		ARTIFACT_BUCKET=$(cat bucket-name.txt)
		if [[ ! $ARTIFACT_BUCKET =~ lambda-artifacts-[a-z0-9]{16} ]] ; then
			echo "Bucket was not created by this application. Skipping."
		else
			while true; do
				read -p "Delete deployment artifacts and bucket ($ARTIFACT_BUCKET)? (y/n)" response
				case $response in
					[Yy]* ) aws s3 rb --force s3://$ARTIFACT_BUCKET; rm bucket-name.txt; break;;
					[Nn]* ) break;;
					* ) echo "Response must start with y or n.";;
				esac
			done
		fi
	fi

	while true; do
		read -p "Delete function log group (/aws/lambda/$FUNCTION)? (y/n)" response
		case $response in
			[Yy]* ) aws logs delete-log-group --log-group-name /aws/lambda/$FUNCTION; break;;
			[Nn]* ) break;;
			* ) echo "Response must start with y or n.";;
		esac
	done

	rm -f out.yml out.json function/*.pyc
	rm -rf package function/__pycache__

## create Docker image
docker-build:		
	docker-compose build --force-rm

## run `src.lambda_function.lambda_handler` with docker-compose
docker-run:			
	docker-compose run --rm lambda src.lambda_function.lambda_handler

