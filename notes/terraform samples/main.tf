provider "aws" {
  region = "us-east-1"
}

variable "FDS_STACK_PREFIX" {}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "lambda_src/SupplierWDIntegration/publish"
  output_path = "SupplierWDIntegration.zip"
}

locals {
  S3_Arn = "arn:aws:s3:::${var.BUCKETNAME}"
}

module "S3_Bucket" {
    source = "git::https://github.factset.com/CloudAdmin/fds-terraform-modules//modules/service-catalog/s3/v1"

    # Required variables
    bucket_name = var.BUCKETNAME
    bucket_size = var.BUCKET_SIZE
}

module "LoadSupplierContractData" {
  source = "git::https://github.factset.com/CloudAdmin/fds-terraform-modules//modules/aws/lambda/function/v1"

  input_package_file = data.archive_file.lambda_zip.output_path
  name = "LoadSupplierContractData_DEV" 
  description = "function for loading Contract data"
  runtime = "dotnetcore3.1"
  handler = "SupplierWDIntegration::SupplierWDIntegration.Function::LoadContractData"
  timeout = 300
  package_timeout = 300
  # build = "build.sh"
  environment = {
    ACCOUNT_ID=var.ACCOUNT_ID
    USERNAME=var.USERNAME
    PASSWORDPATH=var.PASSWORDPATH
    DBUSERNAME = var.DBUSERNAME
    SQLDATASOURCE = var.SQLDATASOURCE
    ROLENAME=var.ROLENAME
    DBNAME = var.DBNAME
    S3BUCKETNAME=var.BUCKETNAME
    PREFIXNAME = var.PREFIXNAME
    DBPASSWORDPATH = var.DBPASSWORDPATH
  }
}

resource "aws_lambda_permission" "allow_bucket_LoadSupplierContractData" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.LoadSupplierContractData.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.S3_Arn    
}


module "GeneratePurchaseItemFile" {
  source = "git::https://github.factset.com/CloudAdmin/fds-terraform-modules//modules/aws/lambda/function/v1"

  input_package_file = data.archive_file.lambda_zip.output_path
  name = "GeneratePurchaseItemFile_DEV" 
  description = "function for loading Contract data"
  runtime = "dotnetcore3.1"
  handler = "SupplierWDIntegration::SupplierWDIntegration.Function::GeneratePurchaseItemFile"
  timeout = 300
  package_timeout = 300
  # build = "build.sh"
  environment = {
    ACCOUNT_ID=var.ACCOUNT_ID
    USERNAME=var.USERNAME
    PASSWORDPATH=var.PASSWORDPATH
    DBUSERNAME = var.DBUSERNAME
    SQLDATASOURCE = var.SQLDATASOURCE
    ROLENAME=var.ROLENAME
    DBNAME = var.DBNAME
    S3BUCKETNAME=var.BUCKETNAME
    PREFIXNAME = var.PREFIXNAME
    DBPASSWORDPATH = var.DBPASSWORDPATH
    GENERATEDFILETYPE="Purchase_Item"
  }
}

resource "aws_lambda_permission" "allow_bucket_GeneratePurchaseItemFile" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.GeneratePurchaseItemFile.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.S3_Arn    # "arn:aws:s3:::fdss3-workday-feeds"
}

module "GenerateSupplierContractFile" {
  source = "git::https://github.factset.com/CloudAdmin/fds-terraform-modules//modules/aws/lambda/function/v1"

  input_package_file = data.archive_file.lambda_zip.output_path
  name = "GenerateSupplierContractFile_DEV" 
  description = "function for loading Contract data"
  runtime = "dotnetcore3.1"
  handler = "SupplierWDIntegration::SupplierWDIntegration.Function::GenerateSupplierContractFile"
  timeout = 300
  package_timeout = 300
  # build = "build.sh"
  environment = {
    ACCOUNT_ID=var.ACCOUNT_ID
    USERNAME=var.USERNAME
    PASSWORDPATH=var.PASSWORDPATH
    DBUSERNAME = var.DBUSERNAME
    SQLDATASOURCE = var.SQLDATASOURCE
    ROLENAME=var.ROLENAME
    DBNAME = var.DBNAME
    S3BUCKETNAME=var.BUCKETNAME
    PREFIXNAME = var.PREFIXNAME
    DBPASSWORDPATH = var.DBPASSWORDPATH
    GENERATEDFILETYPE="Supplier_Contract"
  }
}

resource "aws_lambda_permission" "allow_bucket_GenerateSupplierContractFile" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.GenerateSupplierContractFile.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.S3_Arn    
}


module "GenerateSupplierContractAmendmentFile" {
  source = "git::https://github.factset.com/CloudAdmin/fds-terraform-modules//modules/aws/lambda/function/v1"

  input_package_file = data.archive_file.lambda_zip.output_path
  name = "GenerateSupplierContractAmendmentFile_DEV" 
  description = "function for loading Contract data"
  runtime = "dotnetcore3.1"
  handler = "SupplierWDIntegration::SupplierWDIntegration.Function::GenerateSupplierContractAmendmentFile"
  timeout = 300
  package_timeout = 300
  # build = "build.sh"
  environment = {
    ACCOUNT_ID=var.ACCOUNT_ID
    USERNAME=var.USERNAME
    PASSWORDPATH=var.PASSWORDPATH
    DBUSERNAME = var.DBUSERNAME
    SQLDATASOURCE = var.SQLDATASOURCE
    ROLENAME=var.ROLENAME
    DBNAME = var.DBNAME
    S3BUCKETNAME=var.BUCKETNAME
    PREFIXNAME = var.PREFIXNAME
    DBPASSWORDPATH = var.DBPASSWORDPATH
    GENERATEDFILETYPE="Supplier_Contract_Amendment"
  }
}

resource "aws_lambda_permission" "allow_bucket_GenerateSupplierContractAmendmentFile" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.GenerateSupplierContractAmendmentFile.function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = local.S3_Arn    
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "SupplierWDIntegration_DEV"
  role_arn = "arn:aws:iam::082730710623:role/service-execution-iam-role"

  definition = <<EOF
{
  "Comment": "This is your state machine",
  "StartAt": "Load Supplier Contract Data",
  "States": {
    "Load Supplier Contract Data": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload.$": "$",
        "FunctionName": "${module.LoadSupplierContractData.function_arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "wait_until_load"
    },
    "wait_until_load": {
      "Type": "Wait",
      "Seconds": 10,
      "Next": "Contract Data Loaded?"
    },
    "Contract Data Loaded?": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.ContractDataLoaded",
          "BooleanEquals": false,
          "Next": "Fail"
        },
        {
          "Variable": "$.ContractDataLoaded",
          "BooleanEquals": true,
          "Next": "GeneratePurchaseItemFile"
        }
      ]
    },
    "GeneratePurchaseItemFile": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.GeneratePurchaseItemFile.function_arn}",
        "Payload": {}
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Parallel"
    },
    "Parallel": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "Generate Supplier Contract File",
          "States": {
            "Generate Supplier Contract File": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload": {},
                "FunctionName": "${module.GenerateSupplierContractFile.function_arn}"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException"
                  ],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 6,
                  "BackoffRate": 2
                }
              ],
              "End": true
            }
          }
        },
        {
          "StartAt": "GenerateSupplierContractAmendmentFile",
          "States": {
            "GenerateSupplierContractAmendmentFile": {
              "Type": "Task",
              "Resource": "arn:aws:states:::lambda:invoke",
              "OutputPath": "$.Payload",
              "Parameters": {
                "Payload": {},
                "FunctionName": "${module.GenerateSupplierContractAmendmentFile.function_arn}"
              },
              "Retry": [
                {
                  "ErrorEquals": [
                    "Lambda.ServiceException",
                    "Lambda.AWSLambdaException",
                    "Lambda.SdkClientException"
                  ],
                  "IntervalSeconds": 2,
                  "MaxAttempts": 6,
                  "BackoffRate": 2
                }
              ],
              "End": true
            }
          }
        }
      ],
      "Parameters": "",
      "Next": "Success"
    },
    "Success": {
      "Type": "Succeed",
      "Comment": "EIB Files Generated Successfully"
    },
    "Fail": {
      "Type": "Fail",
      "Error": "Didn't generate EIB files",
      "Comment": "Data not loaded Successfully"
    }
  }
}
EOF
}

output "S3_Bucket_outputs" {
    value = {
        bucket_name = module.S3_Bucket.bucket_name
        region = module.S3_Bucket.region
        lambda1= module.LoadSupplierContractData.function_arn
        lambda2= module.GeneratePurchaseItemFile.function_arn
        lambda3= module.GenerateSupplierContractFile.function_arn
        lambda4= module.GenerateSupplierContractAmendmentFile.function_arn
        # stepFunction= resource.sfn_state_machine.state_machine_arn
    }
}