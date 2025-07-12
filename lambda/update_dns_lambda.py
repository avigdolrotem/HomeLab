import boto3  # type: ignore
import json
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Lambda function to update Route53 DNS record when EC2 instance starts running
    Triggered by EC2 State Change events via CloudWatch Events/EventBridge
    """
    
    try:
        # Log the incoming event for debugging
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Check if this is an EC2 state change event and if the state is 'running'
        if event.get('detail', {}).get('state') != 'running':
            logger.info(f"Instance state is not 'running', current state: {event.get('detail', {}).get('state')}")
            return {'statusCode': 200, 'body': 'Instance not in running state, no action taken'}

        # Extract instance ID from the event
        instance_id = event['detail']['instance-id']
        logger.info(f"Processing EC2 instance: {instance_id}")

        # Initialize AWS clients
        ec2 = boto3.client('ec2')
        route53 = boto3.client('route53')

        # Configuration - consider moving these to environment variables
        hosted_zone_id = "Z03200893DL2ZD0J62J86"
        record_name = "passwords.avigdol.com"

        # Get instance details
        try:
            reservations = ec2.describe_instances(InstanceIds=[instance_id])['Reservations']
            if not reservations or not reservations[0]['Instances']:
                logger.error(f"No instance found with ID: {instance_id}")
                return {'statusCode': 404, 'body': 'Instance not found'}
                
            instance = reservations[0]['Instances'][0]
            public_ip = instance.get('PublicIpAddress')
            
            if not public_ip:
                logger.warning(f"Instance {instance_id} has no public IP address")
                return {'statusCode': 200, 'body': 'Instance has no public IP, no DNS update needed'}
                
            logger.info(f"Instance {instance_id} has public IP: {public_ip}")
            
        except Exception as e:
            logger.error(f"Error describing EC2 instance {instance_id}: {str(e)}")
            return {'statusCode': 500, 'body': f'Error retrieving instance details: {str(e)}'}

        # Update Route53 DNS record
        try:
            response = route53.change_resource_record_sets(
                HostedZoneId=hosted_zone_id,
                ChangeBatch={
                    'Comment': f'Updated by Lambda for EC2 instance {instance_id}',
                    'Changes': [{
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record_name,
                            'Type': 'A',
                            'TTL': 300,
                            'ResourceRecords': [{'Value': public_ip}]
                        }
                    }]
                }
            )
            
            change_id = response['ChangeInfo']['Id']
            logger.info(f"Successfully updated DNS record {record_name} to {public_ip}. Change ID: {change_id}")
            
            return {
                'statusCode': 200,
                'body': {
                    'status': 'success',
                    'message': 'DNS record updated successfully',
                    'instance_id': instance_id,
                    'public_ip': public_ip,
                    'record_name': record_name,
                    'change_id': change_id
                }
            }
            
        except Exception as e:
            logger.error(f"Error updating Route53 record: {str(e)}")
            return {'statusCode': 500, 'body': f'Error updating DNS record: {str(e)}'}

    except Exception as e:
        logger.error(f"Unexpected error in lambda_handler: {str(e)}")
        return {'statusCode': 500, 'body': f'Unexpected error: {str(e)}'}