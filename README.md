# aid-tracker-interactive

## Docker for DDW
```
docker build -t aid-tracker-interactive-image .
docker run -d --name aid-tracker-container --network ddw-analyst-ui_ddw_net aid-tracker-image
docker exec -it aid-tracker-container bash
```