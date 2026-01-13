# Makefile for the whole repository

.PHONY: help new-course

help:
	@echo "Commands:"
	@echo "  make new-course YEAR=2025-2026 COURSE_CODE=ANAT401 COURSE_NAME=\"Anatomy I\""

new-course:
	@if [ -z "$(YEAR)" ] || [ -z "$(COURSE_CODE)" ] || [ -z "$(COURSE_NAME)" ]; then \
		echo "Usage: make new-course YEAR=<year> COURSE_CODE=<code> COURSE_NAME=<name>"; \
		exit 1; \
	fi
	./scripts/new_course.sh $(YEAR) $(COURSE_CODE) "$(COURSE_NAME)" $(ARGS)


