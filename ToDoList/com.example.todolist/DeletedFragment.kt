package com.example.todolist

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.todolist.databinding.FragmentDeletedBinding

class DeletedFragment : Fragment() {

    private var _binding: FragmentDeletedBinding? = null
    private val binding get() = _binding!!
    private val viewModel: TodoViewModel by activityViewModels()
    private lateinit var deletedAdapter: TodoAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentDeletedBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Adjust spacing for navigation bar
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            binding.rvDeletedItems.setPadding(0, 0, 0, systemBars.bottom)
            insets
        }

        deletedAdapter = TodoAdapter(emptyList())
        binding.rvDeletedItems.adapter = deletedAdapter
        binding.rvDeletedItems.layoutManager = LinearLayoutManager(requireContext())

        viewModel.deletedTodos.observe(viewLifecycleOwner) { deletedTodos ->
            deletedAdapter.updateTodos(deletedTodos.toList())
            updateEmptyState(deletedTodos.isEmpty())
        }
    }

    private fun updateEmptyState(isEmpty: Boolean) {
        if (isEmpty) {
            binding.llEmptyState.visibility = View.VISIBLE
            binding.rvDeletedItems.visibility = View.GONE
        } else {
            binding.llEmptyState.visibility = View.GONE
            binding.rvDeletedItems.visibility = View.VISIBLE
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
