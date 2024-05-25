
resource "tencentcloud_security_group" "sg" {
  name = var.name
}


resource "tencentcloud_security_group_lite_rule" "foo" {
  security_group_id = tencentcloud_security_group.sg.id
  ingress = var.ingress
  egress = var.egress
}