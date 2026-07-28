.PHONY: help setup api mobile test lint fresh apk

help:
	@echo "setup   Install dependencies for both sides"
	@echo "api     Serve the Laravel API on :8000"
	@echo "mobile  Run the Flutter app on a connected device"
	@echo "test    Run Pest + Flutter tests"
	@echo "lint    Run Pint + dart analyze"
	@echo "fresh   Rebuild and reseed the database (destroys local data)"
	@echo "apk     Build a debug APK"

setup:
	cd api && composer install && cp -n .env.example .env && php artisan key:generate
	cd mobile && flutter pub get

api:
	cd api && php artisan serve

mobile:
	cd mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1

test:
	cd api && php artisan test
	cd mobile && flutter test

lint:
	cd api && ./vendor/bin/pint
	cd mobile && dart format . && flutter analyze

fresh:
	cd api && php artisan migrate:fresh --seed

apk:
	cd mobile && flutter build apk --release --dart-define=API_BASE_URL=$(API_URL)
