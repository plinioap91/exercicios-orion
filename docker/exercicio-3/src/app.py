import os
from contextlib import asynccontextmanager
from typing import Annotated

import psycopg
from fastapi import FastAPI
from psycopg.rows import dict_row
from pydantic import BaseModel, StringConstraints


def connect_db():
    return psycopg.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"],
        dbname=os.environ["DB_NAME"],
        connect_timeout=5,
        row_factory=dict_row,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    with connect_db() as connection:
        connection.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                title VARCHAR(200) NOT NULL
            )
        """)
    yield


app = FastAPI(title="Orion — API de tarefas", lifespan=lifespan)


class TaskCreate(BaseModel):
    title: Annotated[
        str, StringConstraints(strip_whitespace=True, min_length=1, max_length=200)
    ]


class Task(BaseModel):
    id: int
    title: str


@app.post("/tasks", response_model=Task, status_code=201)
def create_task(task: TaskCreate):
    with connect_db() as connection:
        return connection.execute(
            "INSERT INTO tasks (title) VALUES (%s) RETURNING id, title",
            (task.title,),
        ).fetchone()


@app.get("/tasks", response_model=list[Task])
def list_tasks():
    with connect_db() as connection:
        return connection.execute("SELECT id, title FROM tasks ORDER BY id").fetchall()
