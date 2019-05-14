#!/bin/sh

# Proprietary
#cd Proprietary/BlitzMax/
#bmk makeapp -r Greedy.bmx
#cd ..
#cd Monkey-X
#transcc_macos -target="Desktop_Game_(Glfw3)" -config=Release +CPP_DOUBLE_PRECISION_FLOATS=1 -build greedy.monkey
#cd ..
#cd ..

# C
cd C
clang -O3 -march=native greedy.c -lm -o greedy
cd ..

# C++
cd C++
clang++ -O3 -march=native greedy.cpp -o greedy
#clang++ -O3 -march=native greedymap.cpp -o greedymap
cd ..

# C#
cd C#
cd DotNet
dotnet-sdk.dotnet build --configuration Release
cd ..
cd ..

# Clojure
cd Clojure
lein uberjar
cd ..

# Common Lisp
cd CommonLisp
sbcl --script greedy.lisp
cd ..

# Crystal
cd Crystal
crystal build --release greedy.cr 
crystal build --release greedy-concurrent.cr 
cd ..

# D
cd D
dmd -O greedy.d
cd ..

# F#
cd F#
cd DotNet
dotnet-sdk.dotnet build --configuration Release
cd ..
cd ..

# Go
cd Go
go build
cd ..
cd Go-Concurrent
go build
cd ..

# Haskell
cd Haskell
cabal build
cd ..

# Java
cd Java
javac Greedy.java -Xdiags:verbose
javac Greedy-Concurrent.java -Xdiags:verbose
cd ..

# OCaml
cd OCaml
ocamlopt -O3 str.cmxa main.ml -o main
cd ..

# Python
cd Python
python setup.py build_ext --inplace
cd ..

# Rust
cd Rust
cargo build --release
cd ..
cd Rust-Concurrent
cargo build --release
cd ..

# Scala
cd Scala
sbt assembly
cd ..
