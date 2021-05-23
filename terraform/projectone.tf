provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAXJMYKKOJNCKYCU52"
  secret_key = "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"
}


resource "aws_instance" "DeeServer" {
  ami           = "ami-0747bdcabd34c712a"
  instance_type = "t2.micro"

}