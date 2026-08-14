
from fastapi import FastAPI, UploadFile, File
from pydantic import BaseModel
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_chroma import Chroma
from  langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_google_genai import ChatGoogleGenerativeAI
from dotenv import load_dotenv

import os
import shutil


load_dotenv()

app = FastAPI()


embeddings = HuggingFaceEmbeddings(
    model_name="sentence-transformers/all-mpnet-base-v2"
)

llm = ChatGoogleGenerativeAI(
    model="gemini-2.5-flash",
    temperature=0
)

vectorstore = None


class Question(BaseModel):
    question: str


@app.get("/")
def home():
    return {
        "message": "PDF QA API is running"
    }


@app.post("/upload-pdf")
async def upload_pdf(file: UploadFile = File(...)):

    global vectorstore

    if not file.filename.lower().endswith(".pdf"):
        return {
            "error": "Please upload a PDF file"
        }

    file_path = f"uploaded_{file.filename}"

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    loader = PyPDFLoader(file_path)

    documents = loader.load()


    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200
    )

    chunks = text_splitter.split_documents(documents)

    print("Number of chunks:", len(chunks))

    
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        collection_name="pdf_qa"
    )

    print("Chroma vector store created successfully")

    return {
        "message": "PDF uploaded successfully",
        "filename": file.filename,
        "chunks": len(chunks)
    }




@app.post("/ask")
async def ask_question(data: Question):

    global vectorstore

    
    if vectorstore is None:
        return {
            "answer": "Please upload a PDF first."
        }

    question = data.question


    documents = vectorstore.similarity_search(
        question,
        k=4
    )

    context = "\n\n".join(
        document.page_content
        for document in documents
    )


    prompt = f"""
You are a PDF question-answering assistant.

Answer the user's question using only the information
from the PDF context below.

If the answer is not available in the PDF, say:
"I couldn't find the answer in the PDF."

PDF CONTEXT:
{context}

USER QUESTION:
{question}

ANSWER:
"""
    response = llm.invoke(prompt)

    return {
        "answer": response.content
    }