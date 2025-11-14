# sprint 3 resubmission

live demo addressing missing objectives 3C-3G using concepts & synchronizations pattern.

## run it

```bash
git clone -b sprint3-v2 https://github.com/FaustoRosado/AIER-alerts.git
cd AIER-alerts/tech-execution/sprint3/live-demo
docker-compose up
```

opens at `localhost:8501`

## what's included

- step functions state machine (3C)
- eventbridge rules (3D)
- lambda remediation code (3E)
- automation testing (3F)
- error handling (3G)
- local llm for healthcare alerts

all real aws, no mocks. 72hr read-only credentials included.

see `demo_guide.md` for details.

