#!/bin/bash

# ============================================
# STUDY GUIDE GENERATOR
# Extracts key points, review questions, and 
# important content from lecture notes
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================
# FUNCTIONS
# ============================================

print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./studyguide.sh exam <number> [lectures]  # Create exam study guide"
    echo "  ./studyguide.sh topic <name> [lectures]   # Create topic study guide"
    echo "  ./studyguide.sh flashcards [lectures]     # Extract flashcard content"
    echo "  ./studyguide.sh questions [lectures]      # Extract all questions"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./studyguide.sh exam 1 01-10              # Exam 1 covering lectures 1-10"
    echo "  ./studyguide.sh topic \"Cell Biology\" 03-07"
    echo "  ./studyguide.sh flashcards 01-05"
    echo "  ./studyguide.sh questions                 # All questions from all lectures"
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

# Parse lecture range (e.g., "01-05" or "03,05,07")
parse_lecture_range() {
    local range=$1
    local lectures=()
    
    if [[ $range =~ ^([0-9]+)-([0-9]+)$ ]]; then
        # Range format: 01-05
        local start=${BASH_REMATCH[1]}
        local end=${BASH_REMATCH[2]}
        
        for i in $(seq $start $end); do
            local num=$(printf "%02d" $i)
            if [ -f "notes/lec_${num}.tex" ]; then
                lectures+=("notes/lec_${num}.tex")
            fi
        done
    elif [[ $range =~ , ]]; then
        # Comma-separated: 01,03,05
        IFS=',' read -ra nums <<< "$range"
        for num in "${nums[@]}"; do
            num=$(printf "%02d" $num)
            if [ -f "notes/lec_${num}.tex" ]; then
                lectures+=("notes/lec_${num}.tex")
            fi
        done
    else
        # All lectures
        lectures=(notes/lec_*.tex)
    fi
    
    echo "${lectures[@]}"
}

# Extract content between LaTeX environments
extract_environment() {
    local file=$1
    local env=$2
    
    awk "/\\\\begin{$env}/,/\\\\end{$env}/" "$file" | \
        sed '/\\begin{'"$env"'}/d' | \
        sed '/\\end{'"$env"'}/d' | \
        sed 's/^[[:space:]]*//'
}

# Get lecture title
get_lecture_title() {
    local file=$1
    grep "\\lecture{" "$file" | sed 's/.*{\([^}]*\)}/\1/' | tail -1
}

# Get lecture number
get_lecture_number() {
    local file=$1
    basename "$file" .tex | sed 's/lec_//'
}

# ============================================
# CREATE EXAM STUDY GUIDE
# ============================================

create_exam_guide() {
    local exam_num=$1
    local range=$2
    
    if [ -z "$exam_num" ]; then
        error_exit "Usage: studyguide.sh exam <number> [lectures]"
    fi
    
    info "Creating study guide for Exam $exam_num..."
    
    local lectures=($(parse_lecture_range "$range"))
    
    if [ ${#lectures[@]} -eq 0 ]; then
        error_exit "No lectures found in range"
    fi
    
    local output="studyGuides/exam${exam_num}_guide.tex"
    mkdir -p studyGuides
    
    # Create study guide document
    cat > "$output" << EOF
\documentclass[11pt]{article}
\input{preamble.tex}

\title{Exam $exam_num Study Guide}
\author{Generated $(date +%Y-%m-%d)}
\date{}

\begin{document}
\maketitle
\tableofcontents
\newpage

\section{Overview}

This study guide covers lectures ${lectures[0]##*/lec_} through ${lectures[-1]##*/lec_}.

\section{Key Points by Lecture}

EOF
    
    # Extract key points from each lecture
    for lec in "${lectures[@]}"; do
        local num=$(get_lecture_number "$lec")
        local title=$(get_lecture_title "$lec")
        
        echo "\subsection{Lecture $num: $title}" >> "$output"
        echo "" >> "$output"
        
        # Extract learning objectives
        if grep -q "\\begin{keypoint}" "$lec"; then
            echo "\subsubsection*{Learning Objectives}" >> "$output"
            extract_environment "$lec" "keypoint" >> "$output"
            echo "" >> "$output"
        fi
        
        # Extract important boxes
        if grep -q "\\begin{important}" "$lec"; then
            echo "\subsubsection*{Important Concepts}" >> "$output"
            extract_environment "$lec" "important" >> "$output"
            echo "" >> "$output"
        fi
        
        # Extract clinical correlations
        if grep -q "\\begin{clinical}" "$lec"; then
            echo "\subsubsection*{Clinical Correlations}" >> "$output"
            extract_environment "$lec" "clinical" >> "$output"
            echo "" >> "$output"
        fi
    done
    
    # Extract all review questions
    echo "\section{Review Questions}" >> "$output"
    echo "" >> "$output"
    
    for lec in "${lectures[@]}"; do
        local num=$(get_lecture_number "$lec")
        
        if grep -q "Review Questions" "$lec"; then
            echo "\subsection*{From Lecture $num}" >> "$output"
            
            # Extract questions section
            awk '/Review Questions/,/\\section/' "$lec" | \
                grep -v "Review Questions" | \
                grep -v "\\\\section" >> "$output"
            
            echo "" >> "$output"
        fi
    done
    
    # Add practice problems section
    cat >> "$output" << 'EOF'

\section{Practice Problems}

% Add your own practice problems here
\begin{enumerate}
    \item 
    \item 
    \item 
\end{enumerate}

\section{Key Terms}

% List important terms to know
\begin{itemize}
    \item 
\end{itemize}

\section{Study Checklist}

\begin{enumerate}[label=$\square$]
    \item Review all learning objectives
    \item Complete practice problems
    \item Review clinical correlations
    \item Create concept maps
    \item Test yourself on key terms
    \item Review previous exam questions
\end{enumerate}

\end{document}
EOF
    
    success "Created $output"
    
    # Compile
    info "Compiling study guide..."
    cd studyGuides
    pdflatex -interaction=nonstopmode "exam${exam_num}_guide.tex" > /dev/null 2>&1
    pdflatex -interaction=nonstopmode "exam${exam_num}_guide.tex" > /dev/null 2>&1
    cd ..
    
    success "Compiled studyGuides/exam${exam_num}_guide.pdf"
    
    echo ""
    echo -e "${BLUE}Study guide includes:${NC}"
    echo "  - Key points from ${#lectures[@]} lectures"
    echo "  - Learning objectives"
    echo "  - Clinical correlations"
    echo "  - Review questions"
    echo "  - Study checklist"
}

# ============================================
# CREATE TOPIC STUDY GUIDE
# ============================================

create_topic_guide() {
    local topic=$1
    local range=$2
    
    if [ -z "$topic" ]; then
        error_exit "Usage: studyguide.sh topic <name> [lectures]"
    fi
    
    info "Creating topic guide: $topic..."
    
    local lectures=($(parse_lecture_range "$range"))
    local safe_topic=$(echo "$topic" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
    local output="studyGuides/topic_${safe_topic}.tex"
    
    mkdir -p studyGuides
    
    cat > "$output" << EOF
\documentclass[11pt]{article}
\input{preamble.tex}

\title{Topic Review: $topic}
\author{Generated $(date +%Y-%m-%d)}
\date{}

\begin{document}
\maketitle

\section{Overview}
% Add your overview here

\section{Key Concepts}

EOF
    
    # Extract content from lectures
    for lec in "${lectures[@]}"; do
        local num=$(get_lecture_number "$lec")
        local title=$(get_lecture_title "$lec")
        
        echo "\subsection{From Lecture $num: $title}" >> "$output"
        
        # Extract mechanisms
        if grep -q "\\begin{mechanism}" "$lec"; then
            extract_environment "$lec" "mechanism" >> "$output"
        fi
        
        echo "" >> "$output"
    done
    
    cat >> "$output" << 'EOF'

\section{Summary}
% Add your summary here

\section{Practice Questions}
\begin{enumerate}
    \item 
\end{enumerate}

\end{document}
EOF
    
    success "Created $output"
}

# ============================================
# EXTRACT FLASHCARD CONTENT
# ============================================

create_flashcards() {
    local range=$1
    
    info "Extracting flashcard content..."
    
    local lectures=($(parse_lecture_range "$range"))
    local output="studyGuides/flashcards.txt"
    
    mkdir -p studyGuides
    
    echo "# Flashcards" > "$output"
    echo "# Format: Q: question | A: answer" >> "$output"
    echo "# Generated $(date +%Y-%m-%d)" >> "$output"
    echo "" >> "$output"
    
    for lec in "${lectures[@]}"; do
        local num=$(get_lecture_number "$lec")
        local title=$(get_lecture_title "$lec")
        
        echo "## Lecture $num: $title" >> "$output"
        echo "" >> "$output"
        
        # Extract definitions
        if grep -q "\\begin{definition" "$lec"; then
            awk '/\\begin{definition/,/\\end{definition}/' "$lec" | \
                grep -v "\\\\begin\\|\\\\end" | \
                while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        echo "Q: Define: $line | A: [Add answer]" >> "$output"
                    fi
                done
        fi
        
        echo "" >> "$output"
    done
    
    success "Created $output"
    echo ""
    echo -e "${BLUE}Import this file into:${NC}"
    echo "  - Anki (with CSV import)"
    echo "  - Quizlet"
    echo "  - RemNote"
}

# ============================================
# EXTRACT ALL QUESTIONS
# ============================================

extract_questions() {
    local range=$1
    
    info "Extracting all review questions..."
    
    local lectures=($(parse_lecture_range "$range"))
    local output="studyGuides/all_questions.tex"
    
    mkdir -p studyGuides
    
    cat > "$output" << EOF
\documentclass[11pt]{article}
\input{preamble.tex}

\title{All Review Questions}
\author{Generated $(date +%Y-%m-%d)}
\date{}

\begin{document}
\maketitle

\section{Questions by Lecture}

EOF
    
    for lec in "${lectures[@]}"; do
        local num=$(get_lecture_number "$lec")
        local title=$(get_lecture_title "$lec")
        
        if grep -q "Review Questions" "$lec"; then
            echo "\subsection{Lecture $num: $title}" >> "$output"
            
            awk '/Review Questions/,/\\section/' "$lec" | \
                grep -v "Review Questions" | \
                grep -v "\\\\section" >> "$output"
            
            echo "" >> "$output"
        fi
    done
    
    echo "\end{document}" >> "$output"
    
    success "Created $output"
    
    # Compile
    cd studyGuides
    pdflatex -interaction=nonstopmode "all_questions.tex" > /dev/null 2>&1
    cd ..
    
    success "Compiled studyGuides/all_questions.pdf"
}

# ============================================
# MAIN
# ============================================

if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

if [ ! -f "master.tex" ]; then
    error_exit "Not in a course directory (master.tex not found)"
fi

command=$1
shift

case $command in
    exam|e)
        create_exam_guide "$@"
        ;;
    topic|t)
        create_topic_guide "$@"
        ;;
    flashcards|flash|f)
        create_flashcards "$@"
        ;;
    questions|q)
        extract_questions "$@"
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        error_exit "Unknown command: $command"
        ;;
esac
