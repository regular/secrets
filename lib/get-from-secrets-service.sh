VAULT="$1"
ITEM="$2"
FIELD="$3"
sudo secretsctl decrypt "$VAULT/$ITEM/$FIELD"

