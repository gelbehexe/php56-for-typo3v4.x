#!/bin/bash
# Test script for typo3-php56-fpm image
set -e

IMAGE=$1
if [ -z "$IMAGE" ]; then
    echo "Usage: $0 <image_name>"
    exit 1
fi

echo "Running tests for $IMAGE..."

# 1. PHP Version
echo -n "Checking PHP version... "
docker run --rm "$IMAGE" php -v | grep -q "PHP 5.6" && echo "OK" || (echo "FAIL"; exit 1)

# 2. PHP Extensions
echo "Checking PHP extensions:"
for ext in gd mysql mbstring; do
    echo -n "  - $ext... "
    docker run --rm "$IMAGE" php -m | grep -qi "$ext" && echo "OK" || (echo "FAIL"; exit 1)
done

# 3. Tidy Binary
echo -n "Checking Tidy binary... "
docker run --rm "$IMAGE" tidy --version | grep -qi "tidy" && echo "OK" || (echo "FAIL"; exit 1)

# 4. GraphicsMagick
echo -n "Checking GraphicsMagick... "
docker run --rm "$IMAGE" gm version | grep -q "GraphicsMagick" && echo "OK" || (echo "FAIL"; exit 1)

# 4. Entrypoint (UID mapping)
echo -n "Checking UID mapping... "
TEST_UID=1234
RESULT=$(docker run --rm -e APPLICATION_UID=$TEST_UID "$IMAGE" id -u www-data | tail -n 1)
if [ "$RESULT" == "$TEST_UID" ]; then
    echo "OK"
else
    echo "FAIL (Expected $TEST_UID, got $RESULT)"
    exit 1
fi

echo "All tests passed successfully!"
