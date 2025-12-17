# EFS for media storage
# N.B. EFS is a regional service, so we create mount targets in each private subnet
# to ensure availability across AZs
resource "aws_efs_file_system" "media" {
  #   creation_token = "${var.prefix}-efs-media"

  encrypted = true # Enable encryption at rest
  tags = {
    Name = "${var.prefix}-efs-media"
  }

}

# EFS uses NFS protocol, so ensure that security groups allow NFS traffic (port 2049)
resource "aws_security_group" "efs" {
  name   = "${var.prefix}-efs-sg"
  vpc_id = var.vpc_id

  # N.B. do NOT forget to allow NFS traffic from ECS tasks security group
  ingress {
    description = "Allow NFS traffic from ECS tasks"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [
      var.ecs_task_sg_id
    ]
  }
}

# resource "aws_efs_mount_target" "media" {
#   for_each = toset(var.private_subnets)

#   file_system_id  = aws_efs_file_system.media.id
#   subnet_id       = each.value
#   security_groups = [aws_security_group.efs.id]
# }

resource "aws_efs_mount_target" "media" {
  for_each = var.private_subnet_ids

  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}



# access point is a way to define specific directory with specific permissions
# this is how we can have multiple apps share the same EFS with different directories
# here we define an access point for media files
# N.B. how does ECS task know to use this access point? It must be defined in the ECS task definition volume
resource "aws_efs_access_point" "media" {
  file_system_id = aws_efs_file_system.media.id
  root_directory {
    path = "/api/media"
    creation_info {
      # the id matches those used in the Dockerfile for the app user
      owner_gid   = 1001
      owner_uid   = 1001
      permissions = "755"
    }
  }

  tags = {
    Name = "${var.prefix}-efs-media-ap"
  }
}
