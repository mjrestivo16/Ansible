#!/bin/bash

# Reload the Nginx service
echo "Reloading Nginx to apply updated SSL certificates..."
if systemctl reload nginx; then
  echo "Nginx reloaded successfully."
else
  echo "Failed to reload Nginx. Please check the Nginx configuration and logs."
  exit 1
fi
