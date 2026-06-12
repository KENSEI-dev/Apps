package com.example.todolist

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

class TodoViewModel : ViewModel() {
    private val _todos = MutableLiveData<MutableList<Todo>>(mutableListOf())
    val todos: LiveData<MutableList<Todo>> = _todos

    private val _deletedTodos = MutableLiveData<MutableList<Todo>>(mutableListOf())
    val deletedTodos: LiveData<MutableList<Todo>> = _deletedTodos

    fun addTodo(todo: Todo) {
        val currentList = _todos.value ?: mutableListOf()
        currentList.add(todo)
        _todos.value = currentList
    }

    fun deleteDoneTodos() {
        val currentList = _todos.value ?: mutableListOf()
        val deletedList = _deletedTodos.value ?: mutableListOf()
        
        val doneTodos = currentList.filter { it.isChecked }
        currentList.removeAll(doneTodos)
        
        // Add to deleted list and mark as deleted
        doneTodos.forEach { it.isDeleted = true }
        deletedList.addAll(doneTodos)
        
        _todos.value = currentList
        _deletedTodos.value = deletedList
    }
    
    fun toggleTodo(todo: Todo, isChecked: Boolean) {
        val currentList = _todos.value ?: return
        val index = currentList.indexOf(todo)
        if (index != -1) {
            currentList[index].isChecked = isChecked
            _todos.value = currentList
        }
    }
}
