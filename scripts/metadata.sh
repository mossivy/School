#!/bin/bash

# ============================================
# ENHANCED METADATA SYSTEM
# Manage lectures with metadata, tags, chapters,
# homework, quizzes, and exam tracking
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

METADATA_DIR=".metadata"
METADATA_DB="$METADATA_DIR/lectures.db"

# ============================================
# FUNCTIONS
# ============================================

print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./metadata.sh init                              # Initialize metadata system"
    echo "  ./metadata.sh set <lec> [options]               # Set lecture metadata"
    echo "  ./metadata.sh get <lec>                         # Show lecture metadata"
    echo "  ./metadata.sh list [filter]                     # List all lectures with metadata"
    echo "  ./metadata.sh chapters                          # Show chapter mapping"
    echo "  ./metadata.sh due                               # Show upcoming due dates"
    echo "  ./metadata.sh exam <n>                      # Show what's on exam"
    echo "  ./metadata.sh tags <tag>                        # Find lectures by tag"
    echo "  ./metadata.sh sync                              # Sync metadata to calendar"
    echo ""
    echo -e "${BLUE}Metadata Options:${NC}"
    echo "  --date <YYYY-MM-DD>                            # Lecture date"
    echo "  --time <HH:MM>                                 # Lecture time"
    echo "  --chapter <n>                                  # Textbook chapter(s)"
    echo "  --reading <pages>                              # Reading assignment"
    echo "  --tags <tag1,tag2>                             # Topic tags"
    echo "  --hw <name> --hw-due <date>                    # Homework assignment"
    echo "  --quiz <date>                                  # Quiz date"
    echo "  --exam <number>                                # Which exam covers this"
    echo "  --difficulty <1-5>                             # Difficulty rating"
    echo "  --notes <text>                                 # Additional notes"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo '  ./metadata.sh set 05 --date 2025-09-15 --time 09:00 --chapter "3,4" --tags "cell,signaling"'
    echo '  ./metadata.sh set 05 --hw "Problem Set 2" --hw-due 2025-09-20 --exam 1'
    echo "  ./metadata.sh list --exam 1"
    echo "  ./metadata.sh tags cell"
    echo "  ./metadata.sh due --next-week"
}

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# ============================================
# INITIALIZE METADATA SYSTEM
# ============================================

init_metadata() {
    info "Initializing metadata system..."
    
    mkdir -p "$METADATA_DIR"
    
    # Create SQLite database
    cat > "$METADATA_DB" << 'EOF'
# Lecture Metadata Database
# Format: LECTURE_NUM|DATE|TIME|TITLE|CHAPTERS|READING|TAGS|HW_NAME|HW_DUE|QUIZ_DATE|EXAM_NUM|DIFFICULTY|NOTES
EOF
    
    success "Metadata system initialized"
    
    # Create template for metadata comments in lecture files
    cat > "$METADATA_DIR/template.txt" << 'EOF'
% METADATA
% Date: YYYY-MM-DD
% Time: HH:MM
% Chapters: 3,4,5
% Reading: pp. 120-145
% Tags: #cell #signaling #pathways
% Homework: Problem Set 2 (Due: YYYY-MM-DD)
% Quiz: YYYY-MM-DD
% Exam: 1
% Difficulty: ★★★☆☆
% Notes: Focus on receptor types
EOF
    
    echo ""
    echo -e "${BLUE}Metadata template created in:${NC} $METADATA_DIR/template.txt"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Add metadata to lectures: ./metadata.sh set 01 --date 2025-08-25 --chapter 1"
    echo "  2. View metadata: ./metadata.sh get 01"
    echo "  3. Sync to calendar: ./metadata.sh sync"
}

# ============================================
# PARSE LECTURE FILE FOR EXISTING METADATA
# ============================================

parse_lecture_metadata() {
    local lec_num=$1
    local lec_file="notes/lec_$(printf '%02d' $lec_num).tex"
    
    if [ ! -f "$lec_file" ]; then
        return 1
    fi
    
    # Extract metadata from lecture file comments
    local date=$(grep "^% Date:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local time=$(grep "^% Time:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local title=$(grep "\\lecture{" "$lec_file" | sed 's/.*{\([^}]*\)}/\1/' | tail -1)
    local chapters=$(grep "^% Chapters:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local reading=$(grep "^% Reading:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local tags=$(grep "^% Tags:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local hw=$(grep "^% Homework:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local quiz=$(grep "^% Quiz:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local exam=$(grep "^% Exam:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local difficulty=$(grep "^% Difficulty:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    local notes=$(grep "^% Notes:" "$lec_file" 2>/dev/null | cut -d: -f2- | xargs)
    
    echo "$lec_num|$date|$time|$title|$chapters|$reading|$tags|$hw|$quiz|$exam|$difficulty|$notes"
}

# ============================================
# SET LECTURE METADATA
# ============================================

set_metadata() {
    local lec_num=$1
    shift
    
    if [ -z "$lec_num" ]; then
        error_exit "Usage: ./metadata.sh set <lec_num> [options]"
    fi
    
    lec_num=$(printf "%02d" $lec_num)
    local lec_file="notes/lec_${lec_num}.tex"
    
    if [ ! -f "$lec_file" ]; then
        error_exit "Lecture $lec_num not found"
    fi
    
    # Parse existing metadata
    local existing=$(parse_lecture_metadata $lec_num)
    IFS='|' read -r _ old_date old_time old_title old_chapters old_reading old_tags old_hw old_quiz old_exam old_difficulty old_notes <<< "$existing"
    
    # Parse new options
    local date="$old_date"
    local time="$old_time"
    local chapters="$old_chapters"
    local reading="$old_reading"
    local tags="$old_tags"
    local hw_name=""
    local hw_due=""
    local quiz_date="$old_quiz"
    local exam_num="$old_exam"
    local difficulty="$old_difficulty"
    local notes="$old_notes"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --date)
                date="$2"
                shift 2
                ;;
            --time)
                time="$2"
                shift 2
                ;;
            --chapter|--chapters)
                chapters="$2"
                shift 2
                ;;
            --reading)
                reading="$2"
                shift 2
                ;;
            --tags)
                tags="$2"
                shift 2
                ;;
            --hw)
                hw_name="$2"
                shift 2
                ;;
            --hw-due)
                hw_due="$2"
                shift 2
                ;;
            --quiz)
                quiz_date="$2"
                shift 2
                ;;
            --exam)
                exam_num="$2"
                shift 2
                ;;
            --difficulty)
                difficulty="$2"
                shift 2
                ;;
            --notes)
                notes="$2"
                shift 2
                ;;
            *)
                error_exit "Unknown option: $1"
                ;;
        esac
    done
    
    # Combine homework info
    local hw_info=""
    if [ -n "$hw_name" ]; then
        hw_info="$hw_name"
        if [ -n "$hw_due" ]; then
            hw_info="$hw_info (Due: $hw_due)"
        fi
    fi
    
    # Remove old metadata from lecture file
    sed -i.bak '/^% METADATA$/,/^$/d' "$lec_file"
    
    # Add new metadata at top of file (after \lecture command)
    local metadata_block=""
    metadata_block+="% METADATA\n"
    [ -n "$date" ] && metadata_block+="% Date: $date\n"
    [ -n "$time" ] && metadata_block+="% Time: $time\n"
    [ -n "$chapters" ] && metadata_block+="% Chapters: $chapters\n"
    [ -n "$reading" ] && metadata_block+="% Reading: $reading\n"
    [ -n "$tags" ] && metadata_block+="% Tags: $tags\n"
    [ -n "$hw_info" ] && metadata_block+="% Homework: $hw_info\n"
    [ -n "$quiz_date" ] && metadata_block+="% Quiz: $quiz_date\n"
    [ -n "$exam_num" ] && metadata_block+="% Exam: $exam_num\n"
    [ -n "$difficulty" ] && metadata_block+="% Difficulty: $difficulty\n"
    [ -n "$notes" ] && metadata_block+="% Notes: $notes\n"
    metadata_block+="\n"
    
    # Insert after \lecture command
    awk -v meta="$metadata_block" '
        /\\lecture\{/ { print; printf meta; next }
        { print }
    ' "$lec_file" > "$lec_file.tmp"
    mv "$lec_file.tmp" "$lec_file"
    rm "${lec_file}.bak"
    
    # Update lecture date/time in \lecture command if provided
    if [ -n "$date" ]; then
        sed -i.bak "s/\\\\lecture{${lec_num}}{[^}]*}/\\\\lecture{${lec_num}}{${date}}/" "$lec_file"
        rm "${lec_file}.bak"
    fi
    
    # Save to database
    local title=$(grep "\\lecture{" "$lec_file" | sed 's/.*{\([^}]*\)}/\1/' | tail -1)
    echo "$lec_num|$date|$time|$title|$chapters|$reading|$tags|$hw_info|$quiz_date|$exam_num|$difficulty|$notes" >> "$METADATA_DB"
    
    success "Updated metadata for Lecture $lec_num"
    
    # Show what was set
    echo ""
    echo -e "${BLUE}Metadata:${NC}"
    [ -n "$date" ] && echo "  Date: $date"
    [ -n "$time" ] && echo "  Time: $time"
    [ -n "$chapters" ] && echo "  Chapters: $chapters"
    [ -n "$reading" ] && echo "  Reading: $reading"
    [ -n "$tags" ] && echo "  Tags: $tags"
    [ -n "$hw_info" ] && echo "  Homework: $hw_info"
    [ -n "$quiz_date" ] && echo "  Quiz: $quiz_date"
    [ -n "$exam_num" ] && echo "  Exam: $exam_num"
    [ -n "$difficulty" ] && echo "  Difficulty: $difficulty"
    [ -n "$notes" ] && echo "  Notes: $notes"
}

# ============================================
# GET LECTURE METADATA
# ============================================

get_metadata() {
    local lec_num=$1
    
    if [ -z "$lec_num" ]; then
        error_exit "Usage: ./metadata.sh get <lec_num>"
    fi
    
    lec_num=$(printf "%02d" $lec_num)
    local metadata=$(parse_lecture_metadata $lec_num)
    
    if [ -z "$metadata" ]; then
        error_exit "Lecture $lec_num not found"
    fi
    
    IFS='|' read -r num date time title chapters reading tags hw quiz exam difficulty notes <<< "$metadata"
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Lecture $num: $title${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    [ -n "$date" ] && echo -e "${BLUE}Date:${NC}       $date"
    [ -n "$time" ] && echo -e "${BLUE}Time:${NC}       $time"
    [ -n "$chapters" ] && echo -e "${BLUE}Chapters:${NC}   $chapters"
    [ -n "$reading" ] && echo -e "${BLUE}Reading:${NC}    $reading"
    [ -n "$tags" ] && echo -e "${BLUE}Tags:${NC}       $tags"
    [ -n "$hw" ] && echo -e "${BLUE}Homework:${NC}   $hw"
    [ -n "$quiz" ] && echo -e "${BLUE}Quiz:${NC}       $quiz"
    [ -n "$exam" ] && echo -e "${BLUE}Exam:${NC}       $exam"
    [ -n "$difficulty" ] && echo -e "${BLUE}Difficulty:${NC} $difficulty"
    [ -n "$notes" ] && echo -e "${BLUE}Notes:${NC}      $notes"
    echo ""
}

# ============================================
# LIST ALL LECTURES WITH METADATA
# ============================================

list_metadata() {
    local filter=$1
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}All Lectures${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    printf "%-4s %-12s %-8s %-30s %-10s %-6s\n" "Lec" "Date" "Time" "Title" "Chapters" "Exam"
    echo "$(printf '%.0s-' {1..80})"
    
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ date time title chapters _ _ _ _ exam _ _ <<< "$metadata"
            
            # Apply filter if specified
            if [ -n "$filter" ]; then
                case $filter in
                    --exam)
                        [ "$exam" != "$2" ] && continue
                        ;;
                    --chapter)
                        [[ ! "$chapters" =~ $2 ]] && continue
                        ;;
                esac
            fi
            
            printf "%-4s %-12s %-8s %-30s %-10s %-6s\n" "$num" "$date" "$time" "${title:0:30}" "$chapters" "$exam"
        fi
    done
    
    echo ""
}

# ============================================
# SHOW CHAPTER MAPPING
# ============================================

show_chapters() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Chapter to Lecture Mapping${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    # Collect all unique chapters
    declare -A chapter_map
    
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ _ _ title chapters _ _ _ _ _ _ _ <<< "$metadata"
            
            if [ -n "$chapters" ]; then
                # Split chapters by comma
                IFS=',' read -ra CHAPS <<< "$chapters"
                for chap in "${CHAPS[@]}"; do
                    chap=$(echo "$chap" | xargs)  # trim whitespace
                    if [ -n "${chapter_map[$chap]}" ]; then
                        chapter_map[$chap]+=" $num"
                    else
                        chapter_map[$chap]="$num"
                    fi
                done
            fi
        fi
    done
    
    # Sort and display
    for chap in $(echo "${!chapter_map[@]}" | tr ' ' '\n' | sort -n); do
        echo -e "${BLUE}Chapter $chap:${NC} Lectures ${chapter_map[$chap]}"
    done
    
    echo ""
}

# ============================================
# SHOW UPCOMING DUE DATES
# ============================================

show_due_dates() {
    local filter=$1
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Upcoming Due Dates${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local today=$(date +%Y-%m-%d)
    local upcoming=()
    
    # Collect all due dates
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ _ _ title _ _ _ hw quiz _ _ _ <<< "$metadata"
            
            # Extract homework due date
            if [[ "$hw" =~ Due:\ ([0-9-]+) ]]; then
                local hw_due="${BASH_REMATCH[1]}"
                if [[ "$hw_due" > "$today" ]]; then
                    local hw_name=$(echo "$hw" | sed 's/ (Due:.*//')
                    upcoming+=("$hw_due|HW|Lec $num: $hw_name")
                fi
            fi
            
            # Quiz dates
            if [ -n "$quiz" ] && [[ "$quiz" > "$today" ]]; then
                upcoming+=("$quiz|Quiz|Lec $num: $title")
            fi
        fi
    done
    
    # Sort by date
    IFS=$'\n' sorted=($(sort <<<"${upcoming[*]}"))
    unset IFS
    
    printf "%-12s %-8s %-50s\n" "Date" "Type" "Item"
    echo "$(printf '%.0s-' {1..70})"
    
    for item in "${sorted[@]}"; do
        IFS='|' read -r date type desc <<< "$item"
        printf "%-12s %-8s %-50s\n" "$date" "$type" "$desc"
    done
    
    echo ""
}

# ============================================
# SHOW EXAM COVERAGE
# ============================================

show_exam_coverage() {
    local exam_num=$1
    
    if [ -z "$exam_num" ]; then
        error_exit "Usage: ./metadata.sh exam <number>"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Exam $exam_num Coverage${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local covered_lectures=()
    local covered_chapters=()
    
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ date _ title chapters _ tags _ _ exam _ _ <<< "$metadata"
            
            if [ "$exam" == "$exam_num" ]; then
                covered_lectures+=("$num: $title (Ch $chapters)")
                
                # Collect chapters
                if [ -n "$chapters" ]; then
                    IFS=',' read -ra CHAPS <<< "$chapters"
                    for chap in "${CHAPS[@]}"; do
                        chap=$(echo "$chap" | xargs)
                        covered_chapters+=("$chap")
                    done
                fi
            fi
        fi
    done
    
    echo -e "${BLUE}Lectures:${NC}"
    for lec in "${covered_lectures[@]}"; do
        echo "  • $lec"
    done
    
    echo ""
    echo -e "${BLUE}Chapters:${NC}"
    printf '%s\n' "${covered_chapters[@]}" | sort -u | while read chap; do
        echo "  • Chapter $chap"
    done
    
    echo ""
    echo -e "${BLUE}Generate study guide:${NC}"
    echo "  ./studyguide.sh exam $exam_num"
    echo ""
}

# ============================================
# FIND BY TAG
# ============================================

find_by_tag() {
    local search_tag=$1
    
    if [ -z "$search_tag" ]; then
        error_exit "Usage: ./metadata.sh tags <tag>"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Lectures tagged: $search_tag${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local found=0
    
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ date _ title _ _ tags _ _ _ _ _ <<< "$metadata"
            
            if [[ "$tags" =~ $search_tag ]]; then
                echo -e "${GREEN}Lecture $num${NC} ($date): $title"
                echo "  Tags: $tags"
                echo ""
                ((found++))
            fi
        fi
    done
    
    if [ $found -eq 0 ]; then
        echo "No lectures found with tag: $search_tag"
    else
        echo "Found $found lecture(s)"
    fi
    
    echo ""
}

# ============================================
# SYNC TO CALENDAR
# ============================================

sync_to_calendar() {
    info "Syncing metadata to calendar..."
    
    # Check if calendar.sh exists
    if [ ! -f "calendar.sh" ]; then
        warning "calendar.sh not found in current directory"
        echo "  Copy it here or run from course directory"
        return 1
    fi
    
    # Update each lecture's date/time in calendar
    for lec_file in notes/lec_*.tex; do
        if [ -f "$lec_file" ]; then
            local num=$(basename "$lec_file" .tex | sed 's/lec_//')
            local metadata=$(parse_lecture_metadata $num)
            IFS='|' read -r _ date time _ _ _ _ _ _ _ _ _ <<< "$metadata"
            
            if [ -n "$date" ] && [ -n "$time" ]; then
                info "Syncing Lecture $num: $date $time"
                ./calendar.sh add $num $date $time 2>/dev/null || true
            fi
        fi
    done
    
    # Regenerate calendar with metadata
    ./calendar.sh generate
    
    success "Calendar synced with lecture metadata"
}

# ============================================
# MAIN
# ============================================

if [ ! -f "master.tex" ]; then
    error_exit "Not in a course directory (master.tex not found)"
fi

if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

# Initialize if needed
if [ ! -d "$METADATA_DIR" ] && [ "$1" != "init" ]; then
    warning "Metadata system not initialized"
    read -p "Initialize now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        init_metadata
    else
        exit 1
    fi
fi

command=$1
shift

case $command in
    init)
        init_metadata
        ;;
    set|update)
        set_metadata "$@"
        ;;
    get|show)
        get_metadata "$@"
        ;;
    list|ls)
        list_metadata "$@"
        ;;
    chapters|ch)
        show_chapters
        ;;
    due|deadlines)
        show_due_dates "$@"
        ;;
    exam|e)
        show_exam_coverage "$@"
        ;;
    tags|tag|find)
        find_by_tag "$@"
        ;;
    sync)
        sync_to_calendar
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        error_exit "Unknown command: $command"
        ;;
esac
