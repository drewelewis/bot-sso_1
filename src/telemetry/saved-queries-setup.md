# Application Insights Saved Queries Setup

This script helps you save all your KQL queries as saved queries in Application Insights.

## Prerequisites

1. Install Azure CLI: `az login`
2. Set your subscription: `az account set --subscription "your-subscription-id"`
3. Get your Application Insights resource details

## Required Information

Before running the script, you'll need:
- **Resource Group Name**: Where your Application Insights is located
- **Application Insights Name**: The name of your App Insights resource
- **Subscription ID**: Your Azure subscription

## Usage

1. Update the variables in `save-queries.ps1` with your details
2. Run: `.\save-queries.ps1`

The script will create saved queries for:
- Core Bot Metrics (5 queries)
- User Analytics (4 queries) 
- Error Analysis (3 queries)
- Performance Monitoring (4 queries)
- Advanced Analytics (12 queries)
- Health Dashboards (2 queries)

## Query Categories

All queries will be organized into these categories:
- **Bot-Core**: Essential bot monitoring
- **Bot-Users**: User engagement analytics
- **Bot-Performance**: Performance and optimization
- **Bot-Errors**: Error tracking and debugging
- **Bot-Advanced**: Business intelligence queries
- **Bot-Health**: System health dashboards
