package com.example.todolist

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.todolist.databinding.FragmentTodoBinding

class TodoFragment : Fragment() {

    private var _binding: FragmentTodoBinding? = null
    private val binding get() = _binding!!
    private val viewModel: TodoViewModel by activityViewModels()
    private lateinit var todoAdapter: TodoAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentTodoBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        todoAdapter = TodoAdapter(
            todos = emptyList(),
            onCheckChanged = { todo, isChecked ->
                viewModel.toggleTodo(todo, isChecked)
            }
        )
        binding.rvTodoItems.adapter = todoAdapter
        binding.rvTodoItems.layoutManager = LinearLayoutManager(requireContext())

        viewModel.todos.observe(viewLifecycleOwner) { todos ->
            todoAdapter.updateTodos(todos.toList())
            updateEmptyState(todos.isEmpty())
        }

        binding.btnAddTodo.setOnClickListener {
            val todoTitle = binding.etTodoTitle.text.toString()
            if (todoTitle.isNotEmpty()) {
                val todo = Todo(todoTitle)
                viewModel.addTodo(todo)
                binding.etTodoTitle.text.clear()
            }
        }

        binding.btnDeleteDoneTodos.setOnClickListener {
            viewModel.deleteDoneTodos()
        }
    }

    private fun updateEmptyState(isEmpty: Boolean) {
        if (isEmpty) {
            binding.llEmptyState.visibility = View.VISIBLE
            binding.rvTodoItems.visibility = View.GONE
        } else {
            binding.llEmptyState.visibility = View.GONE
            binding.rvTodoItems.visibility = View.VISIBLE
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}