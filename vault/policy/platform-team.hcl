# Enable and manage the key/value secrets engine at `concourse/` path

# List, create, update, and delete key/value secrets
path "concourse/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
