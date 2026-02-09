Day 1 Architecture (Text Diagram)

Region: ap-southeast-4

+------------------------------------------------------------+
| Region: ap-southeast-4                                     |
|                                                            |
|  +----------------------+      +----------------------+    |
|  | AZ-a                |      | AZ-b                |    |
|  |                      |      |                      |    |
|  | Public Subnet        |      | Public Subnet        |    |
|  | - ALB                |      | - ALB                |    |
|  | - NAT Gateway        |      | - (optional future)  |    |
|  |                      |      |                      |    |
|  | Private Subnet       |      | Private Subnet       |    |
|  | - ECS tasks (later)  |      | - ECS tasks (later)  |    |
|  +----------------------+      +----------------------+    |
|                                                            |
|  Internet Gateway (IGW)                                    |
+------------------------------------------------------------+

Outbound path:
private -> NAT -> IGW
