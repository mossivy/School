#!/bin/bash
if [ "$#" -ne 2 ]; then
    echo "Usage: ./new_course.sh <year> <course_name>"
    echo "Example: ./new_course.sh 2025-2026 Physics1"
    exit 1
fi

YEAR=$1
COURSE=$2
COURSE_DIR=~/School/$YEAR/$COURSE

# Create directory structure
mkdir -p "$COURSE_DIR"/{notes,UltiSnips}

# Create preamble.tex
cat > "$COURSE_DIR/preamble.tex" << 'EOF'
% Course Preamble
% Essential packages
\usepackage{amsmath, amssymb, amsthm}
\usepackage{graphicx}
\usepackage{hyperref}
\usepackage{xifthen}
\usepackage{fancyhdr}
\usepackage[margin=1in]{geometry}
\usepackage{enumitem}
\usepackage{tcolorbox}

% Theorem environments
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

% Lecture command - Optimized for lecture_manager.lua
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
    \chapter*{\@lecture}
    \addcontentsline{toc}{chapter}{Lecture #1: #3}
    \marginpar{\small\textsf{\mbox{#2}}}
}

% Fancy headers
\pagestyle{fancy}
\fancyhead[R]{\@lecture}
\fancyhead[L]{\@lecturedate}
\fancyfoot[R]{\thepage}
\fancyfoot[L]{}
\fancyfoot[C]{\leftmark}
\makeatother

% Course-specific macros (add your own here)
% Common math shortcuts
\newcommand{\R}{\mathbb{R}}
\newcommand{\N}{\mathbb{N}}
\newcommand{\Z}{\mathbb{Z}}
\newcommand{\Q}{\mathbb{Q}}
\newcommand{\C}{\mathbb{C}}
EOF

# Create master.tex
cat > "$COURSE_DIR/master.tex" << EOF
\documentclass[a4paper]{report}
\input{preamble.tex}

\title{$COURSE}
\author{Your Name}
\date{Academic Year $YEAR}

\begin{document}
    \maketitle
    \tableofcontents
    
    % start lectures
    % end lectures
\end{document}
EOF

# Create empty snippets file
cat > "$COURSE_DIR/UltiSnips/tex.snippets" << EOF
# $COURSE Snippets
# Add course-specific snippets here
EOF

echo "✓ Created course structure for $YEAR/$COURSE"
echo "  - $COURSE_DIR/preamble.tex"
echo "  - $COURSE_DIR/master.tex"
echo "  - $COURSE_DIR/notes/"
echo "  - $COURSE_DIR/UltiSnips/"
