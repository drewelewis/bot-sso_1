#!/bin/bash
# List all available KQL queries

echo "📊 Available KQL Queries"
echo "========================"

for category in core users performance errors advanced debugging; do
    if [ -d "$category" ]; then
        echo ""
        echo "📁 $category/"
        find "$category" -name "*.kql" | sed 's/^/   /'
    fi
done

echo ""
echo "Usage: Copy any .kql file content to Application Insights Logs"
