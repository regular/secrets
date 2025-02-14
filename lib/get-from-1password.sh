VAULT="$1"
ITEM="$2"
FIELDS="$3"
$op item get "$ITEM" --vault "$VAULT" --reveal --format json --fields "$FIELDS"

