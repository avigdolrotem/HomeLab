import boto3 # type: ignore
import json
import os

def handler(event, context):
    """
    Lambda function to start/stop EC2 instances
    """
    
    # Initialize EC2 client
    ec2 = boto3.client('ec2')
    
    # Get instance ID from environment variable
    instance_id = os.environ['INSTANCE_ID']
    
    # Get action from event
    action = event.get('action', 'start')
    
    try:
        if action == 'start':
            response = ec2.start_instances(InstanceIds=[instance_id])
            print(f"Starting instance {instance_id}")
        elif action == 'stop':
            response = ec2.stop_instances(InstanceIds=[instance_id])
            print(f"Stopping instance {instance_id}")
        else:
            raise ValueError(f"Invalid action: {action}")
            
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully {action}ed instance {instance_id}',
                'response': response
            })
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error {action}ing instance {instance_id}: {str(e)}'
            })
        }
