import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/reminder_provider.dart';
import '../services/google_auth_service.dart';

class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedMinutes = 30;
  bool _calendarPermissionGranted = false;
  bool _isCheckingPermission = false;

  final List<int> _reminderOptions = [15, 30, 45, 60];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _requestCalendarPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    final authService = GoogleAuthService();
    final granted = await authService.signIn();

    setState(() {
      _calendarPermissionGranted = granted;
      _isCheckingPermission = false;
    });

    if (granted) {
      // Auto advance to next page after a brief delay
      await Future.delayed(const Duration(milliseconds: 800));
      _nextPage();
    }
  }

  Future<void> _completeOnboarding() async {
    // Ensure user is actually authenticated before completing onboarding
    final authService = GoogleAuthService();
    if (!authService.isSignedIn) {
      // Try to sign in first
      final success = await authService.signIn();
      if (!success) {
        // Show error and don't complete onboarding
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in with Google to continue'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    
    await context.read<ReminderProvider>().completeOnboarding(_selectedMinutes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // Ensure all pages are scrollable to prevent overflow
                    SingleChildScrollView(child: _buildWelcomePage()),
                    SingleChildScrollView(child: _buildCalendarPermissionPage()),
                    SingleChildScrollView(child: _buildReminderTimePage()),
                    SingleChildScrollView(child: _buildReadyPage()),
                  ],
                ),
              ),
              // Navigation buttons
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentPage;
          final isCompleted = index < _currentPage;
          
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: isActive 
                    ? Colors.white 
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCompleted
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms)
                  : null,
            ),
          );
        }),
      ).animate()
        .fadeIn(duration: 400.ms),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // App Logo
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ).animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(delay: 400.ms, duration: 1500.ms),
            
            const SizedBox(height: 48),
            
            // Title
            Text(
              'Never Forget\nAnything Again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ).animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // Subtitle
            Text(
              'REM Buddy uses AI to analyze your calendar and reminds you what to bring before each event',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 48),
            
            // Features list
            _buildFeatureItem(
              Icons.calendar_month_rounded,
              'Syncs with your calendar',
              800,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.auto_awesome_rounded,
              'AI-powered suggestions',
              900,
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(
              Icons.notifications_active_rounded,
              'Smart notifications',
              1000,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, int delayMs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: delayMs.ms, duration: 400.ms)
      .slideX(begin: -0.2, end: 0, delay: delayMs.ms, duration: 400.ms);
  }

  Widget _buildCalendarPermissionPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Calendar icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                _calendarPermissionGranted 
                    ? Icons.check_circle_rounded 
                    : Icons.calendar_month_rounded,
                size: 80,
                color: _calendarPermissionGranted
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ).animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 48),
            
            // Title
            Text(
              _calendarPermissionGranted
                  ? 'Perfect! 🎉'
                  : 'Sign In with Google',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Description
            Text(
              _calendarPermissionGranted
                  ? 'Your Google Calendar is now connected. We\'ll read your upcoming events to create smart reminders.'
                  : 'Sign in with your Google account to access your calendar events.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ).animate()
              .fadeIn(delay: 500.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 500.ms),
            
            const SizedBox(height: 48),
            
            // Permission info
            if (!_calendarPermissionGranted) ...[
              _buildPermissionInfoItem(
                Icons.visibility_rounded,
                'Read-only access to events',
              ),
              const SizedBox(height: 12),
              _buildPermissionInfoItem(
                Icons.lock_rounded,
                'Secure Google OAuth',
              ),
              const SizedBox(height: 12),
              _buildPermissionInfoItem(
                Icons.block_rounded,
                'We never modify your calendar',
              ),
              const SizedBox(height: 48),
              
              // Grant permission button
              if (!_calendarPermissionGranted && !_isCheckingPermission)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _requestCalendarPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                    icon: Image.network(
                      'https://www.gstatic.com/images/branding/product/1x/googleg_48dp.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.login),
                    ),
                    label: Text(
                      'Sign In with Google',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: 800.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 800.ms, duration: 400.ms),
              
              if (_isCheckingPermission)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: -0.2, end: 0, duration: 400.ms);
  }

  Widget _buildReminderTimePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Timer icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.access_time_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 48),
            
            // Title
            Text(
              'When Should We\nRemind You?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ).animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 500.ms),
            
            const SizedBox(height: 24),
            
            // Subtitle
            Text(
              'Choose how many minutes before each event you\'d like to be reminded',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ).animate()
              .fadeIn(delay: 500.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0, delay: 500.ms, duration: 500.ms),
            
            const SizedBox(height: 60),
            
            // Time selection grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _reminderOptions.length,
              itemBuilder: (context, index) {
                final minutes = _reminderOptions[index];
                final isSelected = _selectedMinutes == minutes;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMinutes = minutes;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(isSelected ? 1.0 : 0.3),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$minutes',
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'minutes',
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate()
                  .fadeIn(delay: (700 + index * 100).ms, duration: 400.ms)
                  .scale(delay: (700 + index * 100).ms, duration: 400.ms);
              },
            ),
            
            const SizedBox(height: 32),
            
            // Info text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You can change this anytime in Settings',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate()
              .fadeIn(delay: 1200.ms, duration: 400.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Success icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Icon(
                Icons.rocket_launch_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ).animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shake(duration: 500.ms),
            
            const SizedBox(height: 48),
            
            // Title
            Text(
              'You\'re All Set!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 400.ms, duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // Subtitle
            Text(
              'REM Buddy is ready to help you never forget anything again!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, delay: 600.ms, duration: 600.ms),
            
            const SizedBox(height: 60),
            
            // Summary cards
            _buildSummaryCard(
              Icons.calendar_month_rounded,
              'Calendar Connected',
              _calendarPermissionGranted ? 'Google Calendar synced' : 'Using demo mode',
              800,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              Icons.notifications_rounded,
              'Reminders Set',
              '$_selectedMinutes minutes before events',
              900,
            ),
            const SizedBox(height: 16),
            _buildSummaryCard(
              Icons.auto_awesome_rounded,
              'AI Ready',
              'Personalized suggestions enabled',
              1000,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(IconData icon, String title, String subtitle, int delayMs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: 24,
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: delayMs.ms, duration: 400.ms)
      .slideX(begin: -0.2, end: 0, delay: delayMs.ms, duration: 400.ms);
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0)
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          // Next/Finish button
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _currentPage == 3
                    ? _completeOnboarding
                    : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _currentPage == 3 ? 'Start Using A' : _currentPage == 0 ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPage == 3 
                          ? Icons.rocket_launch_rounded 
                          : Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms),
    );
  }
}
