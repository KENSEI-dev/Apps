package com.example.todolist

import android.os.Bundle
import android.util.TypedValue
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.GravityCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
import androidx.fragment.app.Fragment
import com.example.todolist.databinding.ActivityMainBinding
import com.google.android.material.snackbar.Snackbar

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable Edge-to-Edge
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Ensure status bar icons are dark (for light pink toolbar) 
        // and navigation bar icons are dark (for light pink background)
        WindowCompat.getInsetsController(window, window.decorView).apply {
            isAppearanceLightStatusBars = true
            isAppearanceLightNavigationBars = true
        }

        setSupportActionBar(binding.toolbar)
        binding.toolbar.setNavigationOnClickListener {
            binding.drawerLayout.openDrawer(GravityCompat.START)
        }

        // Adjust toolbar to account for the status bar height
        ViewCompat.setOnApplyWindowInsetsListener(binding.toolbar) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            
            val tv = TypedValue()
            val actionBarHeight = if (theme.resolveAttribute(android.R.attr.actionBarSize, tv, true)) {
                TypedValue.complexToDimensionPixelSize(tv.data, resources.displayMetrics)
            } else 0
            
            v.updateLayoutParams {
                height = actionBarHeight + systemBars.top
            }
            v.setPadding(0, systemBars.top, 0, 0)
            insets
        }

        // Adjust Drawer content to avoid overlapping system bars
        ViewCompat.setOnApplyWindowInsetsListener(binding.navView) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(0, systemBars.top, 0, systemBars.bottom)
            insets
        }

        binding.navView.setNavigationItemSelectedListener { menuItem ->
            when (menuItem.itemId) {
                R.id.nav_tasks -> replaceFragment(TodoFragment())
                R.id.nav_deleted -> replaceFragment(DeletedFragment())
            }
            true
        }

        if (savedInstanceState == null) {
            replaceFragment(TodoFragment())
            binding.navView.setCheckedItem(R.id.nav_tasks)
            Snackbar.make(binding.root, "Welcome to Todo Master!", Snackbar.LENGTH_LONG).show()
        }
    }

    private fun replaceFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.fragment_container, fragment)
            .setReorderingAllowed(true)
            .commit()
        binding.drawerLayout.closeDrawer(GravityCompat.START)
    }
}
