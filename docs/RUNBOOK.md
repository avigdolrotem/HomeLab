# HomeLab Operations Runbook

## Daily Operations

### Starting Your Lab
```bash
# Manual start (if auto-scheduling is disabled)
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# Check status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

### Accessing Services
- **SSH**: `ssh -i ~/.ssh/homelab-key.pem ec2-user@$(terraform output -raw instance_public_ip)`
- **Applications**: All accessible via HTTPS at their respective subdomains

### Monitoring
```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f [service_name]

# Check resource usage
docker stats
```

## Backup and Recovery

### Manual Backup
```bash
# Run backup script
./scripts/backup.sh

# Verify backup in S3
aws s3 ls s3://your-backup-bucket/
```

### Disaster Recovery
```bash
# Restore from backup
./scripts/restore.sh
```

## Troubleshooting

### Common Issues
1. **Service won't start**: Check logs with `docker compose logs [service]`
2. **SSL certificate issues**: Check Traefik logs
3. **High resource usage**: Check with `docker stats`

For detailed troubleshooting, see TROUBLESHOOTING.md
