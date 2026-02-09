ALB 502 Runbook

Checklist:

- Check target group health first (unhealthy targets usually cause 502).
- Check ECS tasks are running and healthy.
- Check security groups allow ALB -> ECS traffic on the app port.
- Check container port mapping matches the target group port.
- Check the /health path matches the container's health endpoint.
