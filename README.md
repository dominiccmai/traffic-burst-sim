# Scalable Web Service on AWS

## Architecture diagram
<img width="1653" height="429" alt="image" src="https://github.com/user-attachments/assets/5ab29382-1c15-4eb8-8c7d-796f0d4d1120" />

## What scales and what triggers it

The ECS Fargate service task count scales via Application Auto Scaling. The primary trigger is the `ALBRequestCountPerTarget` metric. When requests per task exceed 1,000/min, new tasks are added (with a scale out cooldown: 30s). Request count is chosen over CPU because it can react to a traffic burst immediately. It takes time for a CPU to climb after traffic arrives, and at that point requests have likely already been dropped. I added a secondary CPU policy (target: 60%) that acts as a safety net if the app becomes CPU bound for reasons unrelated to traffic volume. Scale-in cooldown is 300s to avoid thrashing.

## How resilience works

Tasks are spread across two Availability Zones (AZ) at all times (minimum 2 tasks). The ALB health-checks `/health` every 30 seconds and routes traffic only to passing targets. This way losing one task or one AZ is invisible to users. ECS will automatically replaces any failed task.

## Observability

The CloudWatch dashboard shows request count, p95 latency, healthy host count, running task count, and CPU/memory. The metric to page on is the `UnhealthyHostCount` alarm: if any task fails its health check, the endpoint is degraded and the alarm fires within 2 minutes.

## What I'd add next with another week

- **EC2 with ECS or EKS** — Fargate is well suited for a small exercise (no fleet to manage, fast to deploy), but for a production workload at scale it limits control over scheduling, instance types, and cost. EC2 with Savings Plans is cheaper under sustained load, and EKS's HPA and Cluster Autoscaler give more control than Application Auto Scaling.
- **Task warm pool** — (assuming we stick with Fargate) Fargate tasks take 30-60 seconds to start (image pull, health check). For a sudden burst you're exposed for that window. A warm pool keeps tasks on standby ready to absorb traffic immediately.
- **Scheduled / predictive scaling** — if traffic bursts follow a known pattern, we can pre scale before the metric climbs rather than reacting after requests are already queueing

## One thing I cut for time, and why

Autoscaling from the app's `/metrics` Prometheus endpoint. The app exposes request rate and latency at the application level which is probably a more precise scaling signal than the ALB request counter, which is one layer removed from what the app is actually experiencing. Implementing it would have required a metrics collector to scrape `/metrics`, push the results as CloudWatch custom metrics, and build a scaling policy against them. `ALBRequestCountPerTarget` is a predefined metric that requires zero setup, so I used that instead. At production scale, autoscaling from an application-level signal is the right answer.
