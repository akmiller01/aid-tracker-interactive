# aid-tracker-interactive

## Docker for DDW
```
docker build -t aid-tracker-interactive-image .
docker run -t -d --name aid-tracker-container --network ddw-analyst-ui_ddw_net aid-tracker-interactive-image
docker exec -it aid-tracker-container bash
```