#!/bin/bash

# Get current month costs
echo "=== AWS Cost Report ==="
echo "Current month costs:"

# Get cost for current month
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text

echo "Previous month costs:"
# Get cost for previous month
PREV_MONTH=$(date -d "$(date +%Y-%m-01) -1 month" +%Y-%m)
aws ce get-cost-and-usage \
    --time-period Start=${PREV_MONTH}-01,End=$(date +%Y-%m-01) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text

echo "=== Service Breakdown ==="
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[0].Groups[?Total.UnblendedCost.Amount!=`0`].[Keys[0],Total.UnblendedCost.Amount]' \
    --output table
