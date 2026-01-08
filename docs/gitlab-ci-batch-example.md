# GitLab CI/CD Example: Using inventoryctl batch command

This example shows how to use the native `inventoryctl batch` command instead of
`jq` for JSON batch operations.

## Simplified Pipeline Input

```yaml
spec:
    inputs:
        action:
            description: "Action to perform (add, update, delete, get, list, sync, validate, format) 🎯"
            options: [
                "add",
                "update",
                "delete",
                "get",
                "list",
                "sync",
                "validate",
                "format",
            ]
            type: string
            default: "add"
        resource:
            description: "Resource type (host, hosts, group, groups) 📦"
            options: ["host", "hosts", "group", "groups"]
            type: string
            default: "host"
        target_names:
            description: "Comma-separated names (e.g. web-01,web-02) for traditional batch 🏷️"
            type: string
            default: ""
        opts:
            description: "Additional flags (e.g. --group prod --ansible-host 10.0.0.1) 🚩"
            type: string
            default: ""
        batch_json:
            description: "JSON array of host configurations for native batch processing 📋"
            type: string
            default: ""
```

## Updated Job (No jq required!)

```yaml
update_inventory:
    stage: manage
    image:
        name: ghcr.io/aabichou/inventoryctl:latest
        entrypoint: [""]
    rules:
        - if: '$CI_PIPELINE_SOURCE == "api" || $CI_PIPELINE_SOURCE == "trigger" || $CI_PIPELINE_SOURCE == "web"'
    extends: .git_setup_with_pull
    resource_group: inventory_updates
    script:
        - ACTION="$[[ inputs.action ]]"
        - RESOURCE="$[[ inputs.resource ]]"
        - TARGET_NAMES="$[[ inputs.target_names ]]"
        - OPTS="$[[ inputs.opts ]]"
        - BATCH_JSON="$[[ inputs.batch_json ]]"

        - |
              case "$ACTION" in
                validate|format)
                  echo "🚀 Running $ACTION on $INVENTORY_FILE"
                  inventoryctl "$ACTION" "$INVENTORY_FILE" $OPTS
                  ;;

                list|sync)
                  if [ -z "$RESOURCE" ]; then
                    echo "❌ Missing 'resource' for action $ACTION"
                    exit 1
                  fi
                  echo "🚀 Running $ACTION $RESOURCE on $INVENTORY_FILE"
                  inventoryctl "$ACTION" "$RESOURCE" "$INVENTORY_FILE" $OPTS
                  ;;

                *)
                  if [ -z "$RESOURCE" ]; then
                    echo "❌ Missing 'resource' for action $ACTION"
                    exit 1
                  fi

                  # ✨ Native JSON Batch Processing (No jq needed!)
                  if [ -n "$BATCH_JSON" ]; then
                    echo "🔄 Processing JSON batch: $ACTION $RESOURCE"
                    echo "$BATCH_JSON" | inventoryctl batch "$RESOURCE" "$ACTION" "$INVENTORY_FILE"

                  # Traditional comma-separated batch
                  elif [[ "$TARGET_NAMES" == *","* ]]; then
                    echo "🔄 Processing traditional batch: $ACTION $RESOURCE"
                    IFS=',' read -ra NAMES <<< "$TARGET_NAMES"
                    TOTAL=${#NAMES[@]}
                    SUCCESS_COUNT=0
                    FAILED_NAMES=()

                    echo "📦 Processing $TOTAL items..."
                    for NAME in "${NAMES[@]}"; do
                      NAME=$(echo "$NAME" | xargs)
                      echo "  ↳ Processing: $NAME"

                      if inventoryctl "$ACTION" "$RESOURCE" "$NAME" "$INVENTORY_FILE" $OPTS; then
                        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                        echo "    ✅ Success"
                      else
                        FAILED_NAMES+=("$NAME")
                        echo "    ⚠️  Failed"
                      fi
                    done

                    echo ""
                    echo "📊 Batch Summary:"
                    echo "   Total: $TOTAL"
                    echo "   Success: $SUCCESS_COUNT"
                    echo "   Failed: ${#FAILED_NAMES[@]}"

                    if [ ${#FAILED_NAMES[@]} -gt 0 ]; then
                      echo "   Failed items: ${FAILED_NAMES[*]}"
                      if [ $SUCCESS_COUNT -eq 0 ]; then
                        echo "❌ All operations failed"
                        exit 1
                      fi
                    fi

                  # Single operation
                  else
                    if [ -z "$TARGET_NAMES" ]; then
                      echo "❌ Missing 'target_names' or 'batch_json'"
                      exit 1
                    fi
                    echo "🚀 Running $ACTION $RESOURCE $TARGET_NAMES"
                    inventoryctl "$ACTION" "$RESOURCE" "$TARGET_NAMES" "$INVENTORY_FILE" $OPTS
                  fi
                  ;;
              esac

        # Commit and push
        - git add $INVENTORY_FILE
        - |
              if git diff --cached --quiet; then
                echo "✅ No changes to inventory file."
              else
                COMMIT_MSG="chore(inventory): $ACTION $RESOURCE"
                [ -n "$TARGET_NAMES" ] && COMMIT_MSG="$COMMIT_MSG $TARGET_NAMES"
                [ -n "$BATCH_JSON" ] && COMMIT_MSG="$COMMIT_MSG (JSON batch)"

                git commit -m "$COMMIT_MSG via API"
                git push origin $CI_COMMIT_REF_NAME
              fi
```

## Benefits of Native Batch Command

✅ **No external dependencies** - No need to install `jq` in the Docker image ✅
**Simpler pipeline** - One command instead of parsing JSON with shell loops ✅
**Better error handling** - Built-in validation and detailed error messages ✅
**Consistent output** - Formatted batch summary with success/failure counts ✅
**Exit codes** - Proper exit codes for CI/CD integration (0=success, 1=failure,
2=partial)

## Example API Calls

### Add Multiple Hosts (JSON Batch)

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/ref/$BRANCH/trigger/pipeline" \
  --data '{
    "token": "$TRIGGER_TOKEN",
    "variables": {
      "action": "add",
      "resource": "host",
      "batch_json": "[{\"hostname\":\"web-01\",\"ansible_host\":\"10.0.0.1\",\"groups\":[\"webservers\"]},{\"hostname\":\"web-02\",\"ansible_host\":\"10.0.0.2\",\"groups\":[\"webservers\"]}]"
    }
  }'
```

### Update Hosts (Traditional Batch)

```bash
curl --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.example.com/api/v4/projects/$PROJECT_ID/ref/$BRANCH/trigger/pipeline" \
  --data "token=$TRIGGER_TOKEN" \
  --data "variables[action]=update" \
  --data "variables[resource]=host" \
  --data "variables[target_names]=web-01,web-02" \
  --data "variables[opts]=--ansible-user ubuntu"
```

## Performance Comparison

| Method           | Dependencies | Lines of Code | Performance                 |
| ---------------- | ------------ | ------------- | --------------------------- |
| **jq parsing**   | jq, bash     | ~50 lines     | Slower (multiple CLI calls) |
| **Native batch** | None         | ~5 lines      | Faster (single CLI call)    |

## Migration Guide

1. **Update Docker image**: Ensure you're using the latest version with batch
   support
2. **Simplify CI script**: Replace jq parsing logic with `inventoryctl batch`
   command
3. **Test**: Verify batch operations work as expected
4. **Remove jq**: Remove `jq` installation from `.git_setup_with_pull` template
