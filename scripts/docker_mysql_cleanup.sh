#!/usr/bin/env bash
set -euo pipefail

# Cleanup OpenCart tables in the docker-compose MySQL db service
# Credentials can be overridden via env vars
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-example}"
MYSQL_DB="${MYSQL_DATABASE:-opencart}"

docker compose exec -T db sh -lc 'mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DB"' <<'SQL'
SET FOREIGN_KEY_CHECKS=0;
TRUNCATE oc_product_option_value;
TRUNCATE oc_product_option;
TRUNCATE oc_option_value_description;
TRUNCATE oc_option_value;
TRUNCATE oc_option_description;
TRUNCATE oc_option;
TRUNCATE oc_product_attribute;
TRUNCATE oc_attribute_description;
TRUNCATE oc_attribute;
TRUNCATE oc_attribute_group_description;
TRUNCATE oc_attribute_group;
TRUNCATE oc_product_image;
TRUNCATE oc_product_to_category;
TRUNCATE oc_product_description;
TRUNCATE oc_product;
TRUNCATE oc_category_description;
TRUNCATE oc_category;
SET FOREIGN_KEY_CHECKS=1;
SQL