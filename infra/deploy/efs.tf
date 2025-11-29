# EFS for media storage
# EFS is used to store user-uploaded media files persistently
# and share them across multiple ECS tasks.

# NFS protocol uses port 2049
# NFS: Network File System, a distributed file system protocol

resource "aws_efs_file_system" "media" {
  encrypted = true
  tags = {
    Name = "${local.prefix}-media"
  }

}

resource "aws_security_group" "efs" {
  name   = "${local.prefix}-efs"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"

    security_groups = [aws_security_group.ecs_tasks.id]
    description     = "Allow NFS access from ECS tasks"
  }
}


# In Amazon EFS, a mount target is essentially a network endpoint in a specific subnet
# that allows resources in that Availability Zone to mount (connect to) your EFS file system.
# EFS is a regional service (one file system spans multiple AZs),
# but EC2 instances connect to it through mount targets, which are AZ-specific Elastic Network Interfaces (ENIs).
resource "aws_efs_mount_target" "this" {
  for_each        = toset(local.private_subnet_ids)
  file_system_id  = aws_efs_file_system.media.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "media_ap" {
  file_system_id = aws_efs_file_system.media.id
  root_directory {
    path = "/api/media" # directory inside EFS where media files are stored

    creation_info {
      owner_gid   = 1001 # comes from the ecs user inside the container (see Dockerfile)
      owner_uid   = 1001
      permissions = "755"
    }
  }
}
