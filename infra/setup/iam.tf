resource "aws_iam_user" "cd" {
  name = "${var.project_name}-cd"
  path = "/service/"
}

# you don't need to name `aws_iam_access_key` sth like `cd_user_key` it's redundant
resource "aws_iam_access_key" "cd" {
  user = aws_iam_user.cd.name
}

# for now we'll go with admin access;
# later on, we'll obey the "principle of least privilege" by having "fine-grained permission"
resource "aws_iam_user_policy_attachment" "cd_user_admin" {
  user       = aws_iam_user.cd.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
