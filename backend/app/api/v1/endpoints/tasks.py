import uuid
from typing import List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_

from app.models.database import get_db
from app.models.productivity import Task
from app.schemas.productivity import TaskCreate, TaskUpdate, TaskResponse
from app.core.security import get_current_user_id

router = APIRouter()

@router.get("", response_model=List[TaskResponse])
async def list_tasks(
    status_filter: Optional[str] = Query(None, alias="status"),
    category: Optional[str] = None,
    priority: Optional[str] = None,
    due_before: Optional[datetime] = None,
    search: Optional[str] = None,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    List tasks for current authenticated user with optional status, category, priority, and keyword filters.
    """
    query = select(Task).where(Task.user_id == current_user_id)

    if status_filter:
        query = query.where(Task.status == status_filter)
    if category:
        query = query.where(Task.category == category)
    if priority:
        query = query.where(Task.priority == priority)
    if due_before:
        query = query.where(Task.due_date <= due_before)
    if search:
        search_fmt = f"%{search.strip().lower()}%"
        query = query.where(
            or_(
                Task.title.ilike(search_fmt),
                Task.description.ilike(search_fmt)
            )
        )

    query = query.order_by(Task.due_date.asc().nullslast(), Task.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()

@router.post("", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
async def create_task(
    task_in: TaskCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new task for current authenticated user.
    """
    new_id = f"tsk_{uuid.uuid4().hex[:16]}"
    task_data = task_in.model_dump()
    task_data["id"] = new_id
    task_data["user_id"] = current_user_id

    if task_data.get("status") == "Completed" and not task_data.get("completed_at"):
        task_data["completed_at"] = datetime.utcnow()

    task = Task(**task_data)
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return task

@router.get("/{task_id}", response_model=TaskResponse)
async def get_task(
    task_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Get single task by ID with strict ownership verification.
    """
    query = select(Task).where(and_(Task.id == task_id, Task.user_id == current_user_id))
    result = await db.execute(query)
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found."
        )
    return task

@router.put("/{task_id}", response_model=TaskResponse)
async def update_task(
    task_id: str,
    task_update: TaskUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Update a task with strict ownership verification.
    """
    query = select(Task).where(and_(Task.id == task_id, Task.user_id == current_user_id))
    result = await db.execute(query)
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found."
        )

    update_data = task_update.model_dump(exclude_unset=True)
    if "status" in update_data:
        if update_data["status"] == "Completed" and task.status != "Completed":
            task.completed_at = datetime.utcnow()
        elif update_data["status"] != "Completed":
            task.completed_at = None

    for field, value in update_data.items():
        setattr(task, field, value)

    task.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(task)
    return task

@router.post("/{task_id}/complete", response_model=TaskResponse)
async def toggle_task_completion(
    task_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Toggle task completion status with strict ownership verification.
    """
    query = select(Task).where(and_(Task.id == task_id, Task.user_id == current_user_id))
    result = await db.execute(query)
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found."
        )

    if task.status == "Completed":
        task.status = "Todo"
        task.completed_at = None
    else:
        task.status = "Completed"
        task.completed_at = datetime.utcnow()

    task.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(task)
    return task

@router.delete("/{task_id}", status_code=status.HTTP_200_OK)
async def delete_task(
    task_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete a task with strict ownership verification.
    """
    query = select(Task).where(and_(Task.id == task_id, Task.user_id == current_user_id))
    result = await db.execute(query)
    task = result.scalar_one_or_none()
    if not task:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Task not found."
        )

    await db.delete(task)
    await db.commit()
    return {"message": "Task deleted successfully.", "id": task_id}
