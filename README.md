
A comprehensive suite of bash scripts and LaTeX templates for managing course notes, lectures, and study materials. Optimized for medical school but works for any technical coursework.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Script Reference](#script-reference)
4. [Directory Structure](#directory-structure)
5. [Workflow Examples](#workflow-examples)
6. [LaTeX Features](#latex-features)
7. [Tips & Tricks](#tips--tricks)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

```bash
# 1. Create a new course
./new_course.sh 2025-2026 ANAT401 "Human Anatomy I" --template anatomy

# 2. Navigate to course directory
cd ~/School/2025-2026/ANAT401

# 3. Create your first lecture
./lecture.sh new 01 "Introduction to Anatomy"

# 4. Edit the lecture
./lecture.sh edit 01

# 5. Compile your notes
./lecture.sh compile

# 6. Before exam: generate study guide
./studyguide.sh exam 1 01-10
```

---

## 📦 Installation

### Prerequisites

```bash
# macOS
brew install mactex-no-gui
brew install vim  # or your preferred editor

# Ubuntu/Debian
sudo apt-get install texlive-full
sudo apt-get install vim

# Check installation
pdflatex --version
latexmk --version
```

### Setup Scripts

```bash
# 1. Create School directory
mkdir -p ~/School

# 2. Save all scripts to ~/School/
cd ~/School
# Place: new_course.sh, lecture.sh, studyguide.sh

# 3. Make scripts executable
chmod +x new_course.sh lecture.sh studyguide.sh

# 4. (Optional) Add to PATH
echo 'export PATH="$HOME/School:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Vim/Neovim Configuration (for UltiSnips)

Add to your `.vimrc` or `~/.config/nvim/init.vim`:

```vim
" UltiSnips configuration
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

" Look for snippets in current course directory
let g:UltiSnipsSnippetDirectories=["UltiSnips", $HOME."/.vim/UltiSnips"]

" Auto-set snippet directory when entering course folder
autocmd BufEnter */School/**/notes/*.tex 
  \ let g:UltiSnipsSnippetDirectories+=["../UltiSnips"]
```

---

## 📚 Script Reference

### `new_course.sh` - Course Creation

Creates a complete course structure with templates.

#### Usage
```bash
./new_course.sh <year> <course_code> <course_name> [options]
```

#### Options
- `--template <type>` - Use template: `anatomy`, `biochem`, `pharm`, `general`
- `--instructor <name>` - Set instructor name
- `--no-git` - Skip git initialization

#### Examples
```bash
# Basic course
./new_course.sh 2025-2026 CHEM301 "Organic Chemistry"

# With template
./new_course.sh 2025-2026 ANAT401 "Anatomy I" --template anatomy

# With instructor
./new_course.sh 2025-2026 PHARM501 "Pharmacology" --template pharm --instructor "Dr. Smith"
```

#### What it creates
```
COURSE_CODE/
├── master.tex              # Main document
├── preamble.tex            # Packages & custom commands
├── Makefile                # Compilation shortcuts
├── README.md               # Course-specific readme
├── notes/
│   └── lec_template.tex    # Template for new lectures
├── figures/                # Images, diagrams
├── exams/                  # Exam materials
├── studyGuides/            # Generated study guides
└── UltiSnips/              # Course-specific snippets
    └── tex.snippets
```

---

### `lecture.sh` - Lecture Management

Quick commands for creating, editing, and compiling lectures.

**Must run from within a course directory** (where `master.tex` exists).

#### Commands

##### Create New Lecture
```bash
./lecture.sh new <number> <title>
```
- Creates `notes/lec_XX.tex` with template
- Automatically adds to `master.tex`
- Sets today's date

**Example:**
```bash
./lecture.sh new 03 "Cell Signaling Pathways"
# Creates: notes/lec_03.tex
```

##### List All Lectures
```bash
./lecture.sh list
# or
./lecture.sh ls
```
Shows: lecture number, date, title, total count

##### Edit Lecture
```bash
./lecture.sh edit <number>
# or
./lecture.sh e <number>
```
Opens lecture in your `$EDITOR` (default: vim)

**Example:**
```bash
./lecture.sh edit 03
```

##### Compile Notes
```bash
./lecture.sh compile
# or
./lecture.sh c
```
- Compiles `master.pdf`
- Runs pdflatex twice (for TOC)
- Auto-opens PDF on macOS

##### Watch Mode
```bash
./lecture.sh watch
# or
./lecture.sh w
```
- Auto-compiles on file changes
- Great for live note-taking
- Press `Ctrl+C` to stop

##### Show Statistics
```bash
./lecture.sh stats
# or
./lecture.sh info
```
Shows:
- Total lectures
- Word count
- Line count
- Figure count
- PDF size and pages
- Most recent lecture

---

### `studyguide.sh` - Study Material Generation

Automatically extracts and organizes content for studying.

**Must run from within a course directory**.

#### Commands

##### Create Exam Study Guide
```bash
./studyguide.sh exam <number> [lecture_range]
```

Extracts:
- Learning objectives
- Key points (from `keypoint` boxes)
- Important concepts (from `important` boxes)
- Clinical correlations (from `clinical` boxes)
- Review questions
- Study checklist

**Examples:**
```bash
# Exam 1: lectures 1-10
./studyguide.sh exam 1 01-10

# Exam 2: lectures 11-20
./studyguide.sh exam 2 11-20

# Specific lectures
./studyguide.sh exam 1 01,03,05,07
```

**Output:** `studyGuides/exam1_guide.pdf`

##### Create Topic Study Guide
```bash
./studyguide.sh topic "<topic_name>" [lecture_range]
```

Groups related content by topic across lectures.

**Examples:**
```bash
./studyguide.sh topic "Cell Biology" 03-07
./studyguide.sh topic "Cardiovascular System" 15-20
```

**Output:** `studyGuides/topic_<name>.pdf`

##### Extract Flashcards
```bash
./studyguide.sh flashcards [lecture_range]
```

Creates flashcard file in format:
```
Q: question | A: answer
```

**Example:**
```bash
./studyguide.sh flashcards 01-05
```

**Output:** `studyGuides/flashcards.txt`

Can import into: Anki, Quizlet, RemNote

##### Extract All Questions
```bash
./studyguide.sh questions [lecture_range]
```

Compiles all review questions into one document.

**Output:** `studyGuides/all_questions.pdf`

---

## 📁 Directory Structure

### Overall Structure
```
~/School/
├── new_course.sh           # Course creation script
├── lecture.sh              # Lecture management (copy to each course)
├── studyguide.sh          # Study guide generator (copy to each course)
│
├── 2025-2026/
│   ├── ANAT401/
│   │   ├── master.tex
│   │   ├── preamble.tex
│   │   ├── Makefile
│   │   ├── README.md
│   │   ├── lecture.sh     # Copy of main script
│   │   ├── studyguide.sh  # Copy of main script
│   │   ├── notes/
│   │   │   ├── lec_01.tex
│   │   │   ├── lec_02.tex
│   │   │   └── lec_template.tex
│   │   ├── figures/
│   │   │   ├── heart.png
│   │   │   └── diagram.jpg
│   │   ├── exams/
│   │   │   └── midterm_practice.tex
│   │   ├── studyGuides/
│   │   │   ├── exam1_guide.pdf
│   │   │   └── flashcards.txt
│   │   └── UltiSnips/
│   │       └── tex.snippets
│   │
│   └── CHEM301/
│       └── [same structure]
│
└── 2026-2027/
    └── [future courses]
```

### File Purposes

| File | Purpose |
|------|---------|
| `master.tex` | Main document that includes all lectures |
| `preamble.tex` | LaTeX packages, custom commands, styling |
| `Makefile` | Quick compilation commands |
| `notes/lec_XX.tex` | Individual lecture files |
| `figures/` | Images, diagrams, charts |
| `exams/` | Exam materials, practice problems |
| `studyGuides/` | Auto-generated study materials |
| `UltiSnips/tex.snippets` | Course-specific LaTeX shortcuts |

---

## 🎯 Workflow Examples

### Daily Lecture Workflow

```bash
# Morning: Create lecture before class
cd ~/School/2025-2026/ANAT401
./lecture.sh new 05 "Muscular System"
./lecture.sh watch  # Start watch mode

# During class: Take notes in lec_05.tex
# - Watch mode auto-compiles as you save
# - Preview PDF updates automatically

# After class: Review and annotate
./lecture.sh edit 05
# Add: \todo{Review insertion points}
# Add: \question{Why does X happen?}

# Evening: Compile final version
./lecture.sh compile
```

### Weekly Review Workflow

```bash
# Sunday review session
cd ~/School/2025-2026/ANAT401

# Check statistics
./lecture.sh stats

# Review this week's lectures (lectures 10-14)
./studyguide.sh topic "Week 3 Review" 10-14

# Extract questions for practice
./studyguide.sh questions 10-14

# Create flashcards
./studyguide.sh flashcards 10-14
```

### Exam Preparation Workflow

```bash
# Two weeks before exam
cd ~/School/2025-2026/ANAT401

# Generate comprehensive study guide
./studyguide.sh exam 1 01-15

# Review the guide
open studyGuides/exam1_guide.pdf

# One week before: create flashcards
./studyguide.sh flashcards 01-15
# Import flashcards.txt into Anki

# Few days before: practice questions
./studyguide.sh questions 01-15
open studyGuides/all_questions.pdf
```

### Multi-Course Management

```bash
# Monday: Anatomy
cd ~/School/2025-2026/ANAT401
./lecture.sh new 12 "Nervous System"
./lecture.sh watch

# Tuesday: Chemistry  
cd ~/School/2025-2026/CHEM301
./lecture.sh new 08 "Reaction Kinetics"
./lecture.sh compile

# Check overall progress
for course in ~/School/2025-2026/*/; do
    echo "=== $(basename $course) ==="
    cd "$course"
    ./lecture.sh stats
done
```

---

## 🎨 LaTeX Features

### Colored Boxes

Use these environments to highlight different types of content:

#### Key Points
```latex
\begin{keypoint}
This is essential information you must remember.
\end{keypoint}
```

#### Clinical Correlations
```latex
\begin{clinical}
In patients with hypertension, this mechanism is disrupted...
\end{clinical}
```

#### Mechanisms
```latex
\begin{mechanism}
\begin{enumerate}[label=Step \arabic*:]
    \item Substrate binds to enzyme
    \item Conformational change occurs
    \item Product is released
\end{enumerate}
\end{mechanism}
```

#### Important Notes
```latex
\begin{important}
This will definitely be on the exam!
\end{important}
```

#### Cautions/Warnings
```latex
\begin{caution}
Common mistake: Don't confuse insertion with origin!
\end{caution}
```

#### Definitions
```latex
\begin{definition}
\textbf{Homeostasis:} The tendency toward a stable equilibrium.
\end{definition}
```

### Custom Commands

#### Note-taking helpers
```latex
\todo{Look up the actual half-life}
\review{Make sure I understand this mechanism}
\question{Why does this only occur in liver cells?}
```

#### Formatting
```latex
\term{homeostasis}          % Blue bold for key terms
\gene{BRCA1}                % Italic for genes
\protein{Hemoglobin}        % Small caps for proteins
```

#### Quick lists
```latex
\symptoms{
    \item Fever
    \item Headache
    \item Fatigue
}
```

#### Images
```latex
\fig[0.6]{figures/heart.png}{Structure of the human heart}
% Arguments: [width fraction]{path}{caption}
```

### Anatomy-Specific Templates

```latex
% Muscle information
\begin{itemize}
    \item \textbf{Origin:} Scapula
    \item \textbf{Insertion:} Humerus
    \item \textbf{Innervation:} Radial nerve (C5-C8)
    \item \textbf{Action:} Flexion
    \item \textbf{Blood supply:} Brachial artery
\end{itemize}
```

### Biochemistry-Specific Templates

```latex
% Enzyme details
\textbf{Enzyme:} Hexokinase\\
\textbf{Substrate:} Glucose\\
\textbf{Product:} Glucose-6-phosphate\\
\textbf{Cofactor:} ATP, Mg²⁺\\
\textbf{Regulation:} Inhibited by product

% Chemical equation
\ce{ATP + H2O -> ADP + Pi}
```

### Pharmacology-Specific Templates

```latex
% Drug information
\textbf{Drug:} Lisinopril\\
\textbf{Class:} ACE inhibitor\\
\textbf{MOA:} Blocks conversion of Ang I to Ang II\\
\textbf{Indications:} Hypertension, heart failure\\
\textbf{Side Effects:} Dry cough, hyperkalemia
```

---

## 💡 Tips & Tricks

### Speed Up Note-Taking

1. **Master your snippets** - Practice typing common shortcuts:
   ```
   beg<tab>    → \begin{} ... \end{}
   sec<tab>    → \section{}
   key<tab>    → \begin{keypoint}...\end{keypoint}
   ```

2. **Use watch mode during lectures**
   ```bash
   ./lecture.sh watch
   ```
   Auto-compiles as you save, so you can preview your notes

3. **Abbreviate during class, expand later**
   - Take quick notes during lecture
   - Add details/formatting during review

4. **Keep a template open** - Copy/paste common structures

### Organization Tips

1. **One lecture per file** - Easier to manage and compile selectively

2. **Descriptive lecture titles** - Makes searching easier
   - Good: "Cardiac Cycle and Heart Sounds"
   - Bad: "Lecture 15"

3. **Use consistent numbering** - Zero-padded (01, 02, ... 10, 11)

4. **Tag with metadata**
   ```latex
   % Tags: #cardiology #physiology #exam1
   % Difficulty: ★★★☆☆
   ```

### Study Tips

1. **Generate study guides weekly** - Not just before exams

2. **Review questions immediately** - Add to each lecture
   ```latex
   \section*{Review Questions}
   \begin{enumerate}
       \item What is the function of X?
       \item How does Y differ from Z?
   \end{enumerate}
   ```

3. **Link concepts across lectures**
   ```latex
   See also: Lecture 03 for related pathway
   ```

4. **Use TODO markers** to track what needs review
   ```latex
   \todo{Understand why this enzyme is rate-limiting}
   ```

### Backup Strategy

```bash
# Initialize git in each course
cd ~/School/2025-2026/ANAT401
git init
git add .
git commit -m "Initial commit"

# Daily backups
git add .
git commit -m "Lectures through $(date +%Y-%m-%d)"

# Optional: Push to GitHub
git remote add origin https://github.com/username/ANAT401-notes.git
git push -u origin main
```

### Collaboration

Share your notes:
```bash
# Export just the PDF
cp master.pdf ~/Dropbox/SharedNotes/

# Share specific lectures
./studyguide.sh topic "Shared Review" 05-10
# Send: studyGuides/topic_shared_review.pdf
```

---

## 🔧 Troubleshooting

### Common Issues

#### "Command not found: ./lecture.sh"
```bash
# Make sure script is executable
chmod +x lecture.sh

# Or run with bash explicitly
bash lecture.sh list
```

#### "master.tex not found"
You're not in a course directory. Navigate to the course:
```bash
cd ~/School/2025-2026/ANAT401
./lecture.sh list
```

#### LaTeX compilation errors
```bash
# Clean auxiliary files
make clean

# Check for syntax errors
pdflatex master.tex
# Read the error output carefully

# Common fixes:
# - Missing \end{} for \begin{}
# - Unescaped special characters: & % $ # _ { }
# - Missing packages in preamble.tex
```

#### Snippets not working in Vim

1. Check UltiSnips is installed:
   ```vim
   :echo has('python3')  " Should return 1
   ```

2. Verify snippet directory:
   ```vim
   :UltiSnipsEdit
   " Should open tex.snippets
   ```

3. Check `.vimrc` configuration (see Installation section)

#### Watch mode not auto-compiling

Requires `latexmk`:
```bash
# Install
tlmgr install latexmk

# Or use manual compilation
./lecture.sh compile
```

#### Study guide extraction incomplete

Ensure you're using the correct environments in your lectures:
- `\begin{keypoint}` ... `\end{keypoint}`
- `\begin{clinical}` ... `\end{clinical}`
- Section title: `\section*{Review Questions}`

### Getting Help

1. **Check script help**
   ```bash
   ./lecture.sh --help
   ./studyguide.sh --help
   ```

2. **View example lecture**
   ```bash
   cat notes/lec_template.tex
   ```

3. **Test with minimal file**
   ```bash
   # Create test.tex with just:
   \documentclass{article}
   \begin{document}
   Hello world
   \end{document}
   
   # Compile
   pdflatex test.tex
   ```

---

## 🚀 Advanced Usage

### Custom Templates

Create your own course template:

```bash
# 1. Create template directory
mkdir -p ~/.latex_templates/mytemplate

# 2. Add custom preamble
vim ~/.latex_templates/mytemplate/preamble.tex

# 3. Modify new_course.sh to use it
# Add to template switch statement
```

### Batch Operations

Process multiple courses:
```bash
# Compile all courses
for course in ~/School/2025-2026/*/; do
    cd "$course"
    ./lecture.sh compile
done

# Generate all exam 1 study guides
for course in ~/School/2025-2026/*/; do
    cd "$course"
    ./studyguide.sh exam 1 01-10
done
```

### Integration with Other Tools

#### Anki Integration
```bash
./studyguide.sh flashcards 01-10
# Import studyGuides/flashcards.txt into Anki
```

#### iPad/Tablet Annotation
```bash
# Sync master.pdf to tablet
cp master.pdf ~/Dropbox/TabletNotes/ANAT401_$(date +%Y%m%d).pdf
```

#### Obsidian/Notion Export
```bash
# Convert to markdown (requires pandoc)
pandoc master.tex -o notes.md
```

---

## 📖 Additional Resources

- **LaTeX Documentation**: https://www.overleaf.com/learn
- **UltiSnips Guide**: https://github.com/SirVer/ultisnips
- **Med School Note-Taking**: [Link to study strategies]
- **Vim for LaTeX**: https://castel.dev/post/lecture-notes-1/

---

## 📄 License

Free to use and modify. Share with classmates!

---

## 🤝 Contributing

Improvements welcome! If you create better templates or scripts, share them with your study group.

---

**Happy note-taking! 📝** EOF
