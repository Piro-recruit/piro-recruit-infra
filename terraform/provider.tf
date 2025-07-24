# terraform/provider.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}
 
provider "google" {
  # 방법 1: 서비스 계정 키 파일 사용
  credentials = file("C:/Users/rlarb/aws-key/piro-recruit/service-account-key.json")  # 다운로드한 JSON 파일 경로
  
  # 방법 2: 환경변수 사용 (추천)
  # export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account-key.json"
  
  project = var.project_id
  region  = var.region
  zone    = var.zone
}
