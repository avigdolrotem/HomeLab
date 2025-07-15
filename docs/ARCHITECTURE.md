# HomeLab Architecture Documentation

## Overview

This document describes the architecture decisions and design principles for the HomeLab project.

## Core Architecture

### Single EC2 Instance Design
- **Rationale**: Cost optimization while maintaining full functionality
- **Instance Type**: t2.micro (free tier eligible)
- **Operating System**: Amazon Linux 2

### Hybrid Container Orchestration
- **Docker Compose**: Initial deployment for immediate results
- **K3s**: Kubernetes learning environment on the same instance
- **Migration Path**: Gradual transition from Docker Compose to Kubernetes

### Network Architecture
- **VPC**: Single VPC with public subnet
- **Security**: Security groups with minimal required ports
- **DNS**: Route53 for domain management
- **SSL**: Let's Encrypt via Traefik

## Cost Optimization Strategy

### Auto-Scheduling
- **Lambda Functions**: Start/stop EC2 instance on schedule
- **Schedule**: 8 AM - 8 PM Israel time (12 hours/day)
- **Savings**: ~66% reduction in EC2 costs

### Storage Optimization
- **S3 Lifecycle Policies**: Transition to cheaper storage classes
- **EBS Optimization**: Right-sized volumes with encryption

## Security Design

### Network Security
- **Security Groups**: Principle of least privilege
- **SSH Access**: Restricted to specific IP addresses
- **SSL/TLS**: Automatic certificate management

### Access Management
- **IAM Roles**: EC2 instance roles for AWS service access
- **Secrets Management**: AWS Secrets Manager integration
- **Key Management**: AWS KMS for encryption keys

For more details, see the implementation in the infrastructure/terraform directory.
