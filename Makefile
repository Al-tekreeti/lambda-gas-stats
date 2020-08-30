.PHONY: clean create-bucket-name fetch-dependencies lambda-build lambda-deploy

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
		curl -SL https://chromedriver.storage.googleapis.com/85.0.4183.87/chromedriver_linux64.zip > chromedriver.zip
		
		unzip chromedriver.zip -d bin/

		# Get Headless-chrome
		curl -SL https://github.com/adieuadieu/serverless-chrome/releases/download/v1.0.0-55/stable-headless-chromium-amazonlinux-2017-03.zip > headless-chromium.zip

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

		aws cloudformation deploy --template-file out.yml --stack-name gas-station-scraper --capabilities CAPABILITY_NAMED_IAM
		



