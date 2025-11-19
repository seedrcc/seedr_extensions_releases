APPNAME = seedr_roku
ZIP_EXCLUDE= -x keys\* -x *.md -x .git\* -x .DS_Store -x Thumbs.db
APPSROOT = .

# Development settings (replace with your Roku device details)
DEV_TARGET_IP = YOUR_ROKU_IP_ADDRESS
DEV_PASSWORD = justjose987

# Build the application
.PHONY: install remove deploy

install:
	@echo "Building $(APPNAME)..."
	@zip -r $(APPNAME).zip . $(ZIP_EXCLUDE)
	@echo "Built $(APPNAME).zip successfully"

remove:
	@echo "Removing existing app from Roku device..."
	@curl -d "" http://$(DEV_TARGET_IP):8060/keypress/Home
	@curl -d "" -u rokudev:$(DEV_PASSWORD) http://$(DEV_TARGET_IP)/plugin_install

deploy: install
	@echo "Deploying $(APPNAME) to Roku device at $(DEV_TARGET_IP)..."
	@curl -F "mysubmit=Delete" -F "archive=" -u rokudev:$(DEV_PASSWORD) http://$(DEV_TARGET_IP)/plugin_install
	@curl -F "mysubmit=Install" -F "archive=@$(APPNAME).zip" -u rokudev:$(DEV_PASSWORD) http://$(DEV_TARGET_IP)/plugin_install
	@echo "Deployment complete!"

clean:
	@echo "Cleaning build files..."
	@rm -f $(APPNAME).zip
	@echo "Clean complete!"

help:
	@echo "Available targets:"
	@echo "  install - Build the application ZIP file"
	@echo "  deploy  - Build and deploy to Roku device"
	@echo "  remove  - Remove app from Roku device"
	@echo "  clean   - Remove build files"
	@echo ""
	@echo "Before deploying, update DEV_TARGET_IP and DEV_PASSWORD in this Makefile" 