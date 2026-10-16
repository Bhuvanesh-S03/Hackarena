# Hackathon Submission Arena (Phase 1)

Each team adds a folder `teams/team-NN/` with a `Dockerfile` (app must listen on port 8080 and return 200 on `/`).
Push to `main` -> build, scan, push to ECR -> Terraform deploys each team to ECS Fargate behind one ALB (host-based routing).

## Setup
1. `aws configure` then `./scripts/bootstrap.sh <unique-bucket-name>`
2. Add GitHub repo secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, TF_STATE_BUCKET,
   ARENA_DOMAIN (e.g. arena.example.com, optional), ZONE_ID (Route53 zone id, optional)
3. Push to `main` (or Actions -> arena -> Run workflow -> deploy)
4. Teardown: Actions -> arena -> Run workflow -> destroy (then delete ECR repo `arena` + state bucket)

No domain? Test with: `curl -H "Host: team-01.local" http://<alb_dns>/`
