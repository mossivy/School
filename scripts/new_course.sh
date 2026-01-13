#!/bin/bash

# ============================================
# IMPROVED COURSE SETUP SCRIPT
# ============================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCHOOL_DIR=~/School
TEMPLATE_DIR=~/School/.templates
CONFIG_FILE=~/School/.config

# ============================================
# FUNCTIONS
# ============================================

print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  ./new_course.sh <year> <course_code> <course_name> [options]"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  ./new_course.sh 2025-2026 ANAT401 \"Human Anatomy I\""
    echo "  ./new_course.sh 2025-2026 CHEM301 \"Organic Chemistry\" --template biochem"
    echo ""
    echo -e "${BLUE}Options:${NC}"
    echo "  --template <type>    Use specific template (anatomy, biochem, pharm, general)"
    echo "  --instructor <name>  Set instructor name"
    echo "  --no-git            Skip git initialization"
    echo "  --help              Show this help message"
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
# ARGUMENT PARSING
# ============================================

if [ "$#" -lt 3 ]; then
    print_usage
    exit 1
fi

YEAR=$1
COURSE_CODE=$2
COURSE_NAME=$3
shift 3

# Default options
TEMPLATE_TYPE="general"
INSTRUCTOR="Your Name"
USE_GIT=true

# Parse optional arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --template)
            TEMPLATE_TYPE="$2"
            shift 2
            ;;
        --instructor)
            INSTRUCTOR="$2"
            shift 2
            ;;
        --no-git)
            USE_GIT=false
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            error_exit "Unknown option: $1"
            ;;
    esac
done

# ============================================
# VALIDATION
# ============================================

COURSE_DIR="$SCHOOL_DIR/$YEAR/$COURSE_CODE"

if [ -d "$COURSE_DIR" ]; then
    warning "Directory already exists: $COURSE_DIR"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
    rm -rf "$COURSE_DIR"
fi

# ============================================
# CREATE DIRECTORY STRUCTURE
# ============================================

info "Creating directory structure..."

mkdir -p "$COURSE_DIR"/{notes,figures,exams,studyGuides,UltiSnips}

# Optional directories based on template
case $TEMPLATE_TYPE in
    anatomy)
        mkdir -p "$COURSE_DIR"/{diagrams,flashcards}
        ;;
    biochem|pharm)
        mkdir -p "$COURSE_DIR"/{mechanisms,structures}
        ;;
esac

success "Directory structure created"

# ============================================
# CREATE PREAMBLE.TEX (Enhanced)
# ============================================

info "Creating preamble.tex..."

cat > "$COURSE_DIR/preamble.tex" << 'EOF'
% ============================================
% PREAMBLE - ENHANCED FOR MED SCHOOL
% ============================================

% Core packages
\usepackage[margin=1in]{geometry}
\usepackage{amsmath, amssymb, amsthm}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{hyperref}
\usepackage{xifthen}
\usepackage{fancyhdr}
\usepackage{enumitem}
\usepackage{tcolorbox}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{multicol}
\usepackage{tikz}
\usepackage{pgfplots}
\pgfplotsset{compat=1.18}

% Chemistry packages (comment out if not needed)
\usepackage{chemfig}
\usepackage[version=4]{mhchem}

% Hyperref setup
\hypersetup{
    colorlinks=true,
    linkcolor=blue,
    urlcolor=blue,
    citecolor=blue
}

% ============================================
% THEOREM ENVIRONMENTS
% ============================================

\newtheorem{theorem}{Theorem}[section]
\newtheorem{lemma}[theorem]{Lemma}
\newtheorem{proposition}[theorem]{Proposition}
\newtheorem{corollary}[theorem]{Corollary}

\theoremstyle{definition}
\newtheorem{definition}[theorem]{Definition}
\newtheorem{example}[theorem]{Example}
\newtheorem{exercise}[theorem]{Exercise}

\theoremstyle{remark}
\newtheorem{remark}[theorem]{Remark}
\newtheorem{note}[theorem]{Note}

% ============================================
% COLORED BOXES (Med School Specific)
% ============================================

\newtcolorbox{keypoint}{
    colback=yellow!10,
    colframe=orange!75!black,
    title=Key Point,
    fonttitle=\bfseries
}

\newtcolorbox{clinical}{
    colback=red!5,
    colframe=red!75!black,
    title=Clinical Correlation,
    fonttitle=\bfseries
}

\newtcolorbox{mechanism}{
    colback=green!5,
    colframe=green!75!black,
    title=Mechanism,
    fonttitle=\bfseries
}

\newtcolorbox{important}{
    colback=blue!5,
    colframe=blue!75!black,
    title=Important,
    fonttitle=\bfseries
}

\newtcolorbox{definition*}{
    colback=gray!5,
    colframe=gray!75!black,
    title=Definition,
    fonttitle=\bfseries
}

\newtcolorbox{caution}{
    colback=orange!5,
    colframe=orange!75!black,
    title=⚠ Caution,
    fonttitle=\bfseries
}

% ============================================
% LECTURE COMMAND
% ============================================

\makeatletter
\def\@lecture{}%
\def\@lecturedate{}%
\newcommand{\lecture}[3]{
    \ifthenelse{\isempty{#3}}{%
        \def\@lecture{Lecture #1}%
    }{%
        \def\@lecture{Lecture #1: #3}%
    }%
    \def\@lecturedate{#2}%
    \subsection*{\@lecture}
    \addcontentsline{toc}{subsection}{Lecture #1: #3}
    \marginpar{\small\textsf{\mbox{#2}}}
}
\makeatother

% ============================================
% HEADERS AND FOOTERS
% ============================================

\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\leftmark}
\fancyhead[R]{\@lecture}
\fancyfoot[C]{\thepage}
\fancyfoot[R]{\@lecturedate}

\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\footrulewidth}{0.4pt}

% ============================================
% CUSTOM COMMANDS
% ============================================

% Math shortcuts
\newcommand{\R}{\mathbb{R}}
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\Q}{\mathbb{Q}}
\newcommand{\C}{\mathbb{C}}

% Quick formatting
\newcommand{\term}[1]{\textbf{\textcolor{blue}{#1}}}
\newcommand{\gene}[1]{\textit{#1}}
\newcommand{\protein}[1]{\textsc{#1}}

% Note-taking helpers
\newcommand{\todo}[1]{\textcolor{red}{\textbf{TODO: #1}}}
\newcommand{\review}[1]{\textcolor{orange}{\textbf{REVIEW: #1}}}
\newcommand{\question}[1]{\textcolor{purple}{\textbf{Q: #1}}}

% Quick lists
\newcommand{\symptoms}[1]{
    \begin{itemize}[leftmargin=*, label=$\triangleright$]
        #1
    \end{itemize}
}

% Image helper
\newcommand{\fig}[3][0.5]{
    \begin{figure}[htbp]
        \centering
        \includegraphics[width=#1\textwidth]{#2}
        \caption{#3}
    \end{figure}
}
EOF

success "preamble.tex created"

# ============================================
# CREATE MASTER.TEX (Enhanced)
# ============================================

info "Creating master.tex..."

cat > "$COURSE_DIR/master.tex" << EOF
\documentclass[11pt]{report}
\input{preamble.tex}

% ============================================
% COURSE INFORMATION
% ============================================
\title{$COURSE_CODE: $COURSE_NAME}
\author{$INSTRUCTOR}
\date{Academic Year $YEAR}

\begin{document}

\maketitle
\tableofcontents
\newpage

% ============================================
% COURSE OVERVIEW
% ============================================
\chapter*{Course Overview}
\addcontentsline{toc}{chapter}{Course Overview}

\section*{Course Goals}
% Add your course goals here

\section*{Key Topics}
% List main topics covered

\section*{Resources}
% Textbooks, websites, etc.

\newpage

% ============================================
% LECTURES
% ============================================
\chapter{Lectures}

% start lectures
% end lectures

% ============================================
% STUDY GUIDES
% ============================================
\chapter{Study Guides}
% Add exam study guides here

% ============================================
% QUICK REFERENCE
% ============================================
\chapter{Quick Reference}
% Tables, formulas, key concepts

\end{document}
EOF

success "master.tex created"

# ============================================
# CREATE LECTURE TEMPLATE
# ============================================

info "Creating lecture template..."

cat > "$COURSE_DIR/notes/lec_template.tex" << 'EOF'
\lecture{XX}{YYYY-MM-DD}{Lecture Title}

% Learning Objectives
\begin{keypoint}
By the end of this lecture, you should be able to:
\begin{enumerate}
    \item 
    \item 
\end{enumerate}
\end{keypoint}

% Main Content
\section{Topic 1}

\subsection{Subtopic}

% Use these boxes as needed:
% \begin{clinical} ... \end{clinical}
% \begin{mechanism} ... \end{mechanism}
% \begin{important} ... \end{important}
% \begin{caution} ... \end{caution}

% Summary
\section*{Summary}
\begin{itemize}
    \item 
\end{itemize}

% Questions for review
\section*{Review Questions}
\begin{enumerate}
    \item 
\end{enumerate}
EOF

success "Lecture template created"

# ============================================
# CREATE TEMPLATE-SPECIFIC SNIPPETS
# ============================================

info "Creating UltiSnips..."

case $TEMPLATE_TYPE in
    anatomy)
        cat > "$COURSE_DIR/UltiSnips/tex.snippets" << 'EOF'
# Anatomy-specific snippets
snippet muscle "muscle info"
\begin{itemize}
    \item \textbf{Origin:} ${1}
    \item \textbf{Insertion:} ${2}
    \item \textbf{Innervation:} ${3}
    \item \textbf{Action:} ${4}
    \item \textbf{Blood supply:} ${5}
\end{itemize}

snippet nerve "nerve pathway"
\begin{itemize}
    \item \textbf{Origin:} ${1}
    \item \textbf{Course:} ${2}
    \item \textbf{Branches:} ${3}
    \item \textbf{Innervation:} ${4}
\end{itemize}

snippet artery "artery info"
\begin{itemize}
    \item \textbf{Origin:} ${1}
    \item \textbf{Course:} ${2}
    \item \textbf{Branches:} ${3}
    \item \textbf{Supply:} ${4}
\end{itemize}
EOF
        ;;
    
    biochem)
        cat > "$COURSE_DIR/UltiSnips/tex.snippets" << 'EOF'
# Biochemistry-specific snippets
snippet pathway "metabolic pathway"
\begin{mechanism}
\begin{enumerate}[label=Step \arabic*:]
    \item ${1:substrate} $\rightarrow$ ${2:product}
    \item ${3}
\end{enumerate}
\end{mechanism}

snippet enzyme "enzyme details"
\textbf{Enzyme:} ${1:name}\\
\textbf{Substrate:} ${2}\\
\textbf{Product:} ${3}\\
\textbf{Cofactor:} ${4}\\
\textbf{Regulation:} ${5}

snippet rxn "chemical reaction"
\ce{${1:reactant} -> ${2:product}}
EOF
        ;;
    
    pharm)
        cat > "$COURSE_DIR/UltiSnips/tex.snippets" << 'EOF'
# Pharmacology-specific snippets
snippet drug "drug information"
\textbf{Drug:} ${1:name}\\
\textbf{Class:} ${2}\\
\textbf{MOA:} ${3}\\
\textbf{Indications:} ${4}\\
\textbf{Side Effects:} ${5}

snippet pk "pharmacokinetics"
\begin{itemize}
    \item \textbf{Absorption:} ${1}
    \item \textbf{Distribution:} ${2}
    \item \textbf{Metabolism:} ${3}
    \item \textbf{Excretion:} ${4}
    \item \textbf{Half-life:} ${5}
\end{itemize}
EOF
        ;;
    
    *)
        cat > "$COURSE_DIR/UltiSnips/tex.snippets" << 'EOF'
# General course snippets
snippet lec "new lecture"
\lecture{${1:number}}{${2:date}}{${3:title}}
EOF
        ;;
esac

success "UltiSnips created"

# ============================================
# CREATE MAKEFILE
# ============================================

info "Creating Makefile..."

cat > "$COURSE_DIR/Makefile" << 'EOF'
# Makefile for LaTeX course notes

MASTER = master
LATEX = pdflatex
BIBTEX = bibtex

.PHONY: all clean watch edit

all: $(MASTER).pdf

$(MASTER).pdf: $(MASTER).tex $(wildcard notes/*.tex)
	$(LATEX) $(MASTER)
	$(LATEX) $(MASTER)

clean:
	rm -f *.aux *.log *.out *.toc *.synctex.gz *.fdb_latexmk *.fls
	rm -f notes/*.aux
	find . -name "*.aux" -delete

watch:
	latexmk -pdf -pvc $(MASTER).tex

edit:
	nvim $(MASTER).tex

quick:
	$(LATEX) $(MASTER)
EOF

success "Makefile created"

# ============================================
# COPY SCRIPTS
# ============================================

info "Copying scripts..."

cp "$SCHOOL_DIR/scripts/lecture.sh" "$COURSE_DIR/"
cp "$SCHOOL_DIR/scripts/studyguide.sh" "$COURSE_DIR/"
cp "$SCHOOL_DIR/scripts/metadata.sh" "$COURSE_DIR/"
chmod +x "$COURSE_DIR"/*.sh

success "Scripts copied"

# ============================================
# CREATE README
# ============================================

info "Creating README..."

cat > "$COURSE_DIR/README.md" << EOF
# $COURSE_CODE: $COURSE_NAME

**Academic Year:** $YEAR  
**Instructor:** $INSTRUCTOR  
**Template Type:** $TEMPLATE_TYPE

## Quick Start

### Create new lecture
\`\`\`bash
./lecture.sh new 01 "Introduction"
\`\`\`

### Compile notes
\`\`\`bash
make
\`\`\`

### Watch mode (auto-compile on save)
\`\`\`bash
make watch
\`\`\`

### Clean auxiliary files
\`\`\`bash
make clean
\`\`\`

EOF

success "README.md created"

# ============================================
# GIT INITIALIZATION
# ============================================

if [ "$USE_GIT" = true ]; then
    info "Initializing git repository..."
    
    cd "$COURSE_DIR"
    git init
    
    cat > .gitignore << 'EOF'
# LaTeX auxiliary files
*.aux
*.log
*.out
*.toc
*.synctex.gz
*.fdb_latexmk
*.fls
*.dvi
*.bbl
*.blg
*.bcf
*.run.xml

# macOS
.DS_Store

# Editor files
*.swp
*.swo
*~
EOF
    
    git add .
    git commit -m "Initial course setup: $COURSE_CODE - $COURSE_NAME"
    
    success "Git repository initialized"
fi

# ============================================
# SUMMARY
# ============================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Course setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Course:${NC}      $COURSE_CODE - $COURSE_NAME"
echo -e "${BLUE}Location:${NC}    $COURSE_DIR"
echo -e "${BLUE}Template:${NC}    $TEMPLATE_TYPE"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. cd $COURSE_DIR"
echo "  2. ./lecture.sh new 01 \"Introduction\""
echo "  3. make"
echo ""
