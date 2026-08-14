# PDF QA RAG App

An AI-powered PDF Question Answering application built using Flutter, FastAPI, LangChain, ChromaDB, and Google Gemini.

## Features

- Upload a PDF document
- Extract and split PDF content into chunks
- Generate embeddings for the document
- Store embeddings in ChromaDB
- Ask questions about the uploaded PDF
- Get AI-generated answers based on the PDF content
- Flutter mobile application for the user interface

## Technologies Used

### Frontend
- Flutter
- Dart
- HTTP
- File Picker

### Backend
- Python
- FastAPI
- LangChain
- ChromaDB
- Hugging Face Embeddings
- Google Gemini

## How It Works

```text
User
  ↓
Flutter App
  ↓
Upload PDF
  ↓
FastAPI Backend
  ↓
PDF Loader
  ↓
Split PDF into Chunks
  ↓
Generate Embeddings
  ↓
ChromaDB
  ↓
User asks a Question
  ↓
Retrieve Relevant Chunks
  ↓
Google Gemini
  ↓
Answer
  ↓
Flutter App