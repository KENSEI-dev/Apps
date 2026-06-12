package com.example.todolist

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
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

        // Adjust spacing for keyboard and navigation bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            val ime = insets.getInsets(WindowInsetsCompat.Type.ime())
            
            val density = resources.displayMetrics.density
            val margin16 = (16 * density).toInt()
            
            // Calculate total bottom inset (keyboard or nav bar)
            val bottomInset = if (ime.bottom > 0) ime.bottom else systemBars.bottom
            
            // Apply bottom margin to the input card to lift it above nav bar/keyboard
            binding.cvInputTodo.updateLayoutParams<ViewGroup.MarginLayoutParams> {
                bottomMargin = margin16 + bottomInset
            }
            
            // Add padding to RecyclerView so items are not hidden behind the card
            // Input card height is roughly 80dp + margins
            val rvBottomPadding = (100 * density).toInt() + bottomInset
            binding.rvTodoItems.setPadding(0, 0, 0, rvBottomPadding)
            
            insets
        }

        todoAdapter = TodoAdapter(
            todos = emptyList(),
            onCheckChanged = { todo, isChecked ->
                viewModel.toggleTodo(todo, isChecked)
            }
        )
        binding.rvTodoItems.adapter = todoAdapter
        binding.rvTodoItems.layoutManager = LinearLayoutManager(requireContext())

        viewModel.todos.observe(viewLifecycleOwner) { todos ->
            todoAdapter.updateTodos(todos)
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
        
        binding.etTodoTitle.setOnEditorActionListener { _, _, _ ->
            binding.btnAddTodo.performClick()
            true
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
