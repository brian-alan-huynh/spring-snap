#!/bin/bash

set -euo pipefail

trap 'echo "Error on line $LINENO"; exit 1' ERR
trap 'echo "Script finished (exit code $?)"' EXIT

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/ecs-init.log
}

log "Starting EC2 user data script for ECS..."

log "Configuring ECS agent to join cluster: ${ecs_cluster_name}"
mkdir -p /etc/ecs
echo "ECS_CLUSTER=${ecs_cluster_name}" > /etc/ecs/ecs.config

log "Running system package updates..."
yum update -y

log "Ensuring Docker service is enabled to start on reboot..."
systemctl enable docker

log "Installing and configuring the CloudWatch agent for host-level metrics..."

wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f ./amazon-cloudwatch-agent.rpm

log "Creating CloudWatch agent configuration..."

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "namespace": "${cw_namespace}/ECS-Host-Metrics",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system", "cpu_usage_iowait"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/ecs-init.log",
            "log_group_name": "${cw_namespace}/ecs-init-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/ecs/ecs-agent.log.*",
            "log_group_name": "${cw_namespace}/ecs-agent-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC",
            "multi_line_start_pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}T"
          }
        ]
      }
    }
  }
}
EOF

log "Starting CloudWatch agent..."

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

log "Applying system performance optimizations..."

cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
EOF

cat >> /etc/sysctl.d/99-ecs-tuning.conf << 'EOF'
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 32768
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
EOF

sysctl -p /etc/sysctl.d/99-ecs-tuning.conf

log "Starting the ECS service..."
systemctl start ecs

log "EC2 user data script finished successfully."
