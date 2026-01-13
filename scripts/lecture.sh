#!/bin/bash

# ============================================
# LECTURE MANAGER
# Quickly create, list, and compile lectures
# ============================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================
# FUNCTIONS
# ============================================

print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./lecture.sh new <number> <title>    # Create new lecture"
    echo "  ./lecture.sh list                     # List all lectures"
    echo "  ./lecture.sh edit <number>            # Edit specific lecture"
    echo "  ./lecture.sh compile                  # Compile master document"
    echo "  ./lecture.sh watch                    # Watch mode"
    echo "  ./lecture.sh stats                    # Show course statistics"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./lecture.sh new 03 \"Cell Signaling\""
    echo "  ./lecture.sh edit 03"
    echo "  ./lecture.sh list"
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

# Get current directory info
get_course_info() {
    if [ ! -f "master.tex" ]; then
        error_exit "Not in a course directory (master.tex not found)"
    fi
    
    COURSE_NAME=$(grep "\\\\title{" master.tex | sed 's/.*{\(.*\)}/\1/')
}

# ============================================
# CREATE NEW LECTURE
# ============================================

create_lecture() {
    local num=$1
    local title=$2
    
    if [ -z "$num" ] || [ -z "$title" ]; then
        error_exit "Usage: lecture.sh new <number> <title>"
    fi
    
    # Pad number with zeros
    num=$(printf "%02d" $num)
    
    local filename="notes/lec_${num}.tex"
    
    if [ -f "$filename" ]; then
        echo -e "${YELLOW}!${NC} Lecture $num already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Get today's date
    local date=$(date +%Y-%m-%d)
    
    info "Creating lecture $num: $title"
    
    # Create lecture file
    cat > "$filename" << EOF
\lecture{$num}{$date}{$title}

% ============================================
% LEARNING OBJECTIVES
% ============================================
\begin{keypoint}
By the end of this lecture, you should be able to:
\begin{enumerate}
    \item 
    \item 
    \item 
\end{enumerate}
\end{keypoint}

% ============================================
% MAIN CONTENT
% ============================================

\section{Introduction}



\section{Key Concepts}

\subsection{Concept 1}



\subsection{Concept 2}



% ============================================
% CLINICAL APPLICATIONS
% ============================================

\section{Clinical Correlations}

\begin{clinical}
% Add clinical relevance here
\end{clinical}


% ============================================
% SUMMARY
% ============================================

\section*{Summary}
\begin{itemize}
    \item 
    \item 
    \item 
\end{itemize}

% ============================================
% REVIEW QUESTIONS
% ============================================

\section*{Review Questions}
\begin{enumerate}
    \item 
    \item 
    \item 
\end{enumerate}

% ============================================
% NOTES & CLARIFICATIONS
% ============================================

\section*{Questions to Review}
\begin{itemize}
    \item 
\end{itemize}
EOF

    success "Created $filename"
    
    # Add to master.tex if not already there
    if ! grep -q "\\\\input{notes/lec_${num}.tex}" master.tex; then
        info "Adding to master.tex..."
        
        # Insert before "% end lectures"
        sed -i.bak "/% end lectures/i\\
\\\\input{notes/lec_${num}.tex}
" master.tex
        
        rm master.tex.bak
        success "Added to master.tex"
    else
        info "Already in master.tex"
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. vim $filename"
    echo "  2. ./lecture.sh compile"
}

# ============================================
# LIST LECTURES
# ============================================

list_lectures() {
    get_course_info
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$COURSE_NAME${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    if [ ! -d "notes" ] || [ -z "$(ls -A notes/*.tex 2>/dev/null)" ]; then
        echo "No lectures found."
        return
    fi
    
    local count=0
    
    for file in notes/lec_*.tex; do
        if [ -f "$file" ]; then
            local num=$(basename "$file" .tex | sed 's/lec_//')
            local title=$(grep "\\\\lecture{" "$file" | sed 's/.*{\([^}]*\)}/\1/' | tail -1)
            local date=$(grep "\\\\lecture{" "$file" | sed 's/.*{\([^}]*\)}.*/\1/' | head -1 | tail -1)
            
            printf "${GREEN}%3s${NC}  %-12s  %s\n" "$num" "$date" "$title"
            ((count++))
        fi
    done
    
    echo ""
    echo -e "${BLUE}Total lectures:${NC} $count"
    echo ""
}

# ============================================
# EDIT LECTURE
# ============================================

edit_lecture() {
    local num=$1
    
    if [ -z "$num" ]; then
        error_exit "Usage: lecture.sh edit <number>"
    fi
    
    num=$(printf "%02d" $num)
    local filename="notes/lec_${num}.tex"
    
    if [ ! -f "$filename" ]; then
        error_exit "Lecture $num not found"
    fi
    
    ${EDITOR:-vim} "$filename"
}

# ============================================
# COMPILE
# ============================================

compile_notes() {
    info "Compiling master document..."
    
    if command -v latexmk &> /dev/null; then
        latexmk -pdf -interaction=nonstopmode master.tex
    else
        pdflatex master.tex
        pdflatex master.tex  # Run twice for TOC
    fi
    
    success "Compiled master.pdf"
    
    # Open PDF if on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open master.pdf
    fi
}

# ============================================
# WATCH MODE
# ============================================

watch_mode() {
    if ! command -v latexmk &> /dev/null; then
        error_exit "latexmk not found. Install with: tlmgr install latexmk"
    fi
    
    info "Starting watch mode (Ctrl+C to stop)..."
    latexmk -pdf -pvc -interaction=nonstopmode master.tex
}

# ============================================
# STATISTICS
# ============================================

show_stats() {
    get_course_info
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Course Statistics${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    local lecture_count=$(ls notes/lec_*.tex 2>/dev/null | wc -l)
    local total_words=$(find notes -name "lec_*.tex" -exec wc -w {} + 2>/dev/null | tail -1 | awk '{print $1}')
    local total_lines=$(find notes -name "lec_*.tex" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')
    local figure_count=$(ls figures/* 2>/dev/null | wc -l)
    
    printf "%-20s %s\n" "Total lectures:" "$lecture_count"
    printf "%-20s %s\n" "Total words:" "$total_words"
    printf "%-20s %s\n" "Total lines:" "$total_lines"
    printf "%-20s %s\n" "Figures:" "$figure_count"
    
    if [ -f "master.pdf" ]; then
        local pdf_size=$(du -h master.pdf | cut -f1)
        local pdf_pages=$(pdfinfo master.pdf 2>/dev/null | grep Pages | awk '{print $2}')
        printf "%-20s %s\n" "PDF size:" "$pdf_size"
        printf "%-20s %s\n" "PDF pages:" "$pdf_pages"
    fi
    
    echo ""
    
    # Most recent lecture
    if [ $lecture_count -gt 0 ]; then
        local latest=$(ls -t notes/lec_*.tex | head -1)
        local latest_num=$(basename "$latest" .tex | sed 's/lec_//')
        local latest_title=$(grep "\\\\lecture{" "$latest" | sed 's/.*{\([^}]*\)}/\1/' | tail -1)
        
        echo -e "${BLUE}Most recent:${NC} Lecture $latest_num - $latest_title"
    fi
    
    echo ""
}

# ============================================
# MAIN
# ============================================

if [ $# -eq 0 ]; then
    print_usage
    exit 0
fi

command=$1
shift

case $command in
    new)
        create_lecture "$@"
        ;;
    list|ls)
        list_lectures
        ;;
    edit|e)
        edit_lecture "$@"
        ;;
    compile|c)
        compile_notes
        ;;
    watch|w)
        watch_mode
        ;;
    stats|info)
        show_stats
        ;;
    help|--help|-h)
        print_usage
        ;;
    *)
        error_exit "Unknown command: $command"
        ;;
esac
