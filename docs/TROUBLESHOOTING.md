# HomeLab Troubleshooting Guide

## Infrastructure Issues

### Terraform Errors

**Issue**: State file locked
```bash
# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

**Issue**: Resource already exists
```bash
# Solution: Import existing resource
terraform import aws_instance.main i-1234567890abcdef0
```

### EC2 Issues

**Issue**: Instance won't start
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids YOUR_INSTANCE_ID

# View console output
aws ec2 get-console-output --instance-id YOUR_INSTANCE_ID
```

## Application Issues

### Docker Compose Problems

**Issue**: Service fails to start
```bash
# Check specific service logs
docker compose logs SERVICE_NAME

# Restart specific service
docker compose restart SERVICE_NAME

# Rebuild and restart
docker compose up -d --build SERVICE_NAME
```

**Issue**: Port conflicts
```bash
# Check what's using the port
sudo netstat -tulpn | grep :PORT_NUMBER

# Stop conflicting service
sudo systemctl stop SERVICE_NAME
```

### SSL Certificate Issues

**Issue**: Certificate not generating
```bash
# Check Traefik logs
docker logs traefik

# Manually trigger certificate request
docker exec traefik traefik version
```

## Performance Issues

### High Memory Usage
```bash
# Check memory usage
free -h
docker stats

# Clean up unused containers/images
docker system prune -a
```

### High Disk Usage
```bash
# Check disk usage
df -h

# Clean Docker volumes
docker volume prune

# Clean logs
sudo journalctl --vacuum-time=3d
```

## Cost Issues

### Unexpected Charges
```bash
# Check current costs
./scripts/cost-report.sh

# Review EC2 usage
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]'
```

## Recovery Procedures

### Complete System Recovery
1. **Backup current state** (if possible)
2. **Run disaster recovery script**: `./scripts/restore.sh`
3. **Verify all services**: Check each application endpoint
4. **Update DNS** if IP changed

### Partial Service Recovery
1. **Identify failed service**: `docker compose ps`
2. **Check logs**: `docker compose logs SERVICE_NAME`
3. **Restart service**: `docker compose restart SERVICE_NAME`
4. **If persistent, rebuild**: `docker compose up -d --build SERVICE_NAME`

For additional help, check the logs in CloudWatch or contact support.
