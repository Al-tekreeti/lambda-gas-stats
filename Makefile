.PHONY: clean create-bucket-name fetch-dependencies docker-build docker-run lambda-build lambda-deploy lambda-remove

## delete build files
clean:		
	@rm -rf package

# to ensure name uniqueness
create-bucket:
	./1-create-bucket.sh


fetch-dependencies:		## download chromedriver, headless-chrome to `./bin/`
	./2-fetch-dependencies.sh

## prepares dependencies for AWS Lambda deploy 
lambda-build: 
	./3-build-layer.sh

## deploy Lambda function
lambda-deploy:
	./4-deploy-lambda.sh
		
## cleanup resources after finish
lambda-remove:
	./5-remove-resources.sh

## create Docker image
docker-build:		
	docker-compose build --force-rm

## run `src.lambda_function.lambda_handler` with docker-compose
docker-run:			
	docker-compose run --rm lambda src.lambda_function.lambda_handler

## deploy and invoke locally using a docker container
deploy-locally: docker-build docker-run

## deploy and invoke in the aws cloud
deploy-aws: create-bucket lambda-build lambda-deploy

## deploy and invoke in the aws after using github actions
deploy-github-actions: fetch-dependencies lambda-build lambda-deploy
