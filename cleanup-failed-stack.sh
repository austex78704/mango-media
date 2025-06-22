#!/bin/bash

echo "=== CloudFormation Stack Cleanup Script ==="
echo "This script will help clean up the DELETE_FAILED stack"

# Configure AWS region
export AWS_REGION=us-east-1

# Stack name
STACK_NAME="MangoMediaStack"

echo ""
echo "1. Checking current stack status..."
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DOES_NOT_EXIST")
echo "Current status: $STACK_STATUS"

if [[ "$STACK_STATUS" == "DELETE_FAILED" ]]; then
    echo ""
    echo "2. Listing resources that failed to delete..."
    aws cloudformation list-stack-resources --stack-name $STACK_NAME \
        --query 'StackResourceSummaries[?ResourceStatus!=`DELETE_COMPLETE`].[LogicalResourceId,PhysicalResourceId,ResourceType,ResourceStatus]' \
        --output table

    echo ""
    echo "3. Attempting to identify and clean up S3 buckets..."
    # Get S3 bucket names from the stack
    BUCKETS=$(aws cloudformation list-stack-resources --stack-name $STACK_NAME \
        --query 'StackResourceSummaries[?ResourceType==`AWS::S3::Bucket`].PhysicalResourceId' \
        --output text)

    for BUCKET in $BUCKETS; do
        if [[ ! -z "$BUCKET" ]] && [[ "$BUCKET" != "None" ]]; then
            echo "   Found bucket: $BUCKET"
            
            # Check if bucket exists
            if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
                echo "   - Removing all objects from bucket..."
                aws s3 rm s3://$BUCKET --recursive 2>/dev/null || true
                
                echo "   - Removing all versions and delete markers..."
                aws s3api list-object-versions --bucket "$BUCKET" --output json | \
                    jq -r '.Versions[]?, .DeleteMarkers[]? | select(.Key != null) | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | \
                    xargs -I {} aws s3api delete-object --bucket "$BUCKET" {} 2>/dev/null || true
                
                echo "   - Deleting bucket..."
                aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null || true
            fi
        fi
    done

    echo ""
    echo "4. Attempting to delete the stack again..."
    aws cloudformation delete-stack --stack-name $STACK_NAME

    echo ""
    echo "5. Waiting for stack deletion (this may take a few minutes)..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --no-paginate 2>/dev/null || {
        echo "   Stack deletion is taking longer than expected."
        echo "   Current status:"
        aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DELETED"
    }

    echo ""
    echo "6. Final status check..."
    FINAL_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DELETED")
    
    if [[ "$FINAL_STATUS" == "DELETED" ]]; then
        echo "✅ Stack successfully deleted!"
    else
        echo "⚠️  Stack is in status: $FINAL_STATUS"
        echo ""
        echo "If still in DELETE_FAILED, you may need to:"
        echo "1. Go to AWS Console > CloudFormation"
        echo "2. Select the stack"
        echo "3. Click 'Delete' and check 'Retain' for any problematic resources"
        echo "4. Manually delete retained resources from their respective services"
    fi
else
    echo "Stack is not in DELETE_FAILED state. Current status: $STACK_STATUS"
fi

echo ""
echo "=== Cleanup script completed ==="