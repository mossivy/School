# Quick Reference Card

## Create Course
./new_course.sh 2025-2026 ANAT401 "Anatomy I" --template anatomy

## Daily Workflow
cd ~/School/2025-2026/ANAT401
./lecture.sh new 05 "Topic"      # Create
./lecture.sh watch               # Auto-compile
./lecture.sh edit 05             # Edit
./lecture.sh compile             # Final compile

## Before Exam
./studyguide.sh exam 1 01-10     # Study guide
./studyguide.sh flashcards 01-10 # Flashcards
./studyguide.sh questions        # All questions

## Snippets
beg<tab>  → \begin{}...\end{}
key<tab>  → keypoint box
clin<tab> → clinical box
sec<tab>  → \section{}

## Make Commands
make          # Compile
make watch    # Auto-compile
make clean    # Remove aux files
