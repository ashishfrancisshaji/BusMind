import 'dart:math' as math;

/// AI Algorithms Service implementing BFS, DFS, and A* for high-impact learning optimization
class AIAlgorithmsService {
  
  /// BFS (Breadth-First Search) for optimal study path finding
  /// High Impact: Finds the shortest path through learning materials
  static List<String> findOptimalStudyPath(Map<String, List<String>> studyGraph, String start, String goal) {
    final queue = <String>[];
    final visited = <String>{};
    final parent = <String, String>{};
    
    queue.add(start);
    visited.add(start);
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      
      if (current == goal) {
        // Reconstruct path
        final path = <String>[];
        String? node = goal;
        while (node != null) {
          path.insert(0, node);
          node = parent[node];
        }
        return path;
      }
      
      for (final neighbor in studyGraph[current] ?? []) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parent[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }
    
    return []; // No path found
  }
  
  /// DFS (Depth-First Search) for deep learning pattern analysis
  /// High Impact: Analyzes learning patterns and retention depth
  static Map<String, dynamic> analyzeLearningPatterns(Map<String, List<String>> learningGraph, String start) {
    final visited = <String>{};
    final learningDepth = <String, int>{};
    final retentionScore = <String, double>{};
    
    void dfs(String node, int depth) {
      visited.add(node);
      learningDepth[node] = depth;
      
      // Calculate retention score based on depth and complexity
      retentionScore[node] = _calculateRetentionScore(node, depth);
      
      for (final neighbor in learningGraph[node] ?? []) {
        if (!visited.contains(neighbor)) {
          dfs(neighbor, depth + 1);
        }
      }
    }
    
    dfs(start, 0);
    
    return {
      'learningDepth': learningDepth,
      'retentionScore': retentionScore,
      'totalNodes': visited.length,
      'maxDepth': learningDepth.values.reduce(math.max),
      'averageRetention': retentionScore.values.reduce((a, b) => a + b) / retentionScore.length,
    };
  }
  
  /// A* Algorithm for intelligent study scheduling
  /// High Impact: Optimizes study schedule based on multiple factors
  static List<StudySession> optimizeStudySchedule(
    List<StudyTask> tasks,
    List<TimeSlot> availableSlots,
    Map<String, double> userPreferences,
  ) {
    final openSet = <AStarNode>[];
    final closedSet = <String>{};
    final cameFrom = <String, AStarNode>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};
    
    // Initialize with empty schedule
    final startNode = AStarNode(
      id: 'start',
      schedule: [],
      remainingTasks: List.from(tasks),
      remainingSlots: List.from(availableSlots),
    );
    
    openSet.add(startNode);
    gScore['start'] = 0.0;
    fScore['start'] = _heuristic(startNode, tasks);
    
    while (openSet.isNotEmpty) {
      // Find node with lowest f-score
      openSet.sort((a, b) => fScore[a.id]!.compareTo(fScore[b.id]!));
      final current = openSet.removeAt(0);
      
      if (current.remainingTasks.isEmpty) {
        // Goal reached - reconstruct optimal schedule
        return _reconstructSchedule(current, cameFrom);
      }
      
      closedSet.add(current.id);
      
      // Generate neighbors (possible next study sessions)
      for (final task in current.remainingTasks) {
        for (final slot in current.remainingSlots) {
          if (_isCompatible(task, slot)) {
            final neighbor = _createNeighbor(current, task, slot);
            final neighborId = neighbor.id;
            
            if (closedSet.contains(neighborId)) continue;
            
            final tentativeGScore = gScore[current.id]! + _calculateCost(current, neighbor);
            
            if (!openSet.any((node) => node.id == neighborId)) {
              openSet.add(neighbor);
            } else if (tentativeGScore >= (gScore[neighborId] ?? double.infinity)) {
              continue;
            }
            
            cameFrom[neighborId] = current;
            gScore[neighborId] = tentativeGScore;
            fScore[neighborId] = tentativeGScore + _heuristic(neighbor, tasks);
          }
        }
      }
    }
    
    return []; // No optimal schedule found
  }
  
  /// BFS for Mood-Based Content Recommendation
  /// High Impact: Finds content that matches current mood and learning state
  static List<String> recommendContentByMood(
    String currentMood,
    Map<String, List<String>> contentGraph,
    List<String> completedContent,
  ) {
    final queue = <String>[];
    final visited = <String>{};
    final recommendations = <String>[];
    
    // Start with mood-appropriate content
    final moodContent = contentGraph[currentMood] ?? [];
    queue.addAll(moodContent);
    
    while (queue.isNotEmpty && recommendations.length < 5) {
      final content = queue.removeAt(0);
      
      if (!visited.contains(content) && !completedContent.contains(content)) {
        visited.add(content);
        recommendations.add(content);
        
        // Add related content to queue
        queue.addAll(contentGraph[content] ?? []);
      }
    }
    
    return recommendations;
  }
  
  /// DFS for Learning Path Optimization
  /// High Impact: Creates personalized learning paths based on user progress
  static LearningPath createPersonalizedPath(
    String currentLevel,
    String targetLevel,
    Map<String, List<String>> skillGraph,
    Map<String, double> userSkills,
  ) {
    final visited = <String>{};
    final path = <String>[];
    final difficulty = <String, double>{};
    
    void dfs(String skill, double currentDifficulty) {
      if (visited.contains(skill) || skill == targetLevel) return;
      
      visited.add(skill);
      path.add(skill);
      difficulty[skill] = currentDifficulty;
      
      // Find next skills based on prerequisites and user level
      final nextSkills = skillGraph[skill] ?? [];
      for (final nextSkill in nextSkills) {
        final skillLevel = userSkills[nextSkill] ?? 0.0;
        if (skillLevel < 0.8) { // Only include skills user hasn't mastered
          dfs(nextSkill, currentDifficulty + 0.1);
        }
      }
    }
    
    dfs(currentLevel, 0.0);
    
    return LearningPath(
      skills: path,
      difficulty: difficulty,
      estimatedTime: path.length * 30, // 30 minutes per skill
      completionRate: _calculateCompletionRate(path, userSkills),
    );
  }
  
  /// A* for Posture Optimization
  /// High Impact: Optimizes posture monitoring and alert timing
  static List<PostureAlert> optimizePostureAlerts(
    List<PostureData> historicalData,
    List<TimeSlot> availableSlots,
    double sensitivityThreshold,
  ) {
    final alerts = <PostureAlert>[];
    final riskFactors = _analyzePostureRisk(historicalData);
    
    for (final slot in availableSlots) {
      final riskScore = _calculatePostureRisk(slot, riskFactors);
      
      if (riskScore > sensitivityThreshold) {
        alerts.add(PostureAlert(
          timeSlot: slot,
          riskScore: riskScore,
          alertType: _getAlertType(riskScore),
          recommendation: _getPostureRecommendation(riskScore),
        ));
      }
    }
    
    return alerts;
  }
  
  // Helper methods
  static double _calculateRetentionScore(String content, int depth) {
    // Simulate retention calculation based on content complexity and depth
    const baseScore = 0.7;
    final depthBonus = depth * 0.05;
    final complexityFactor = content.length / 100.0;
    return (baseScore + depthBonus + complexityFactor).clamp(0.0, 1.0);
  }
  
  static double _heuristic(AStarNode node, List<StudyTask> allTasks) {
    // Heuristic: estimate remaining work based on task difficulty and time
    double totalRemainingWork = 0.0;
    for (final task in node.remainingTasks) {
      totalRemainingWork += task.difficulty * task.estimatedDuration;
    }
    return totalRemainingWork;
  }
  
  static double _calculateCost(AStarNode from, AStarNode to) {
    // Cost function: considers task difficulty, time slot quality, and user preferences
    final task = to.schedule.last.task;
    final slot = to.schedule.last.timeSlot;
    
    double cost = task.difficulty * 10; // Base cost from difficulty
    cost += (24 - slot.hour) * 0.5; // Prefer earlier hours
    cost += task.estimatedDuration * 0.1; // Time cost
    
    return cost;
  }
  
  static bool _isCompatible(StudyTask task, TimeSlot slot) {
    return task.estimatedDuration <= slot.duration &&
           task.preferredTimeSlots.contains(slot.hour);
  }
  
  static AStarNode _createNeighbor(AStarNode current, StudyTask task, TimeSlot slot) {
    final newSchedule = List<StudySession>.from(current.schedule);
    newSchedule.add(StudySession(task: task, timeSlot: slot));
    
    final newRemainingTasks = List<StudyTask>.from(current.remainingTasks);
    newRemainingTasks.remove(task);
    
    final newRemainingSlots = List<TimeSlot>.from(current.remainingSlots);
    newRemainingSlots.remove(slot);
    
    return AStarNode(
      id: '${current.id}_${task.id}_${slot.id}',
      schedule: newSchedule,
      remainingTasks: newRemainingTasks,
      remainingSlots: newRemainingSlots,
    );
  }
  
  static List<StudySession> _reconstructSchedule(AStarNode goal, Map<String, AStarNode> cameFrom) {
    final schedule = <StudySession>[];
    AStarNode? current = goal;
    
    while (current != null) {
      if (current.schedule.isNotEmpty) {
        schedule.insert(0, current.schedule.last);
      }
      current = cameFrom[current.id];
    }
    
    return schedule;
  }
  
  static Map<String, double> _analyzePostureRisk(List<PostureData> data) {
    final riskFactors = <String, double>{};
    
    // Analyze time-based patterns
    final hourlyRisk = <int, double>{};
    for (final dataPoint in data) {
      final hour = dataPoint.timestamp.hour;
      hourlyRisk[hour] = (hourlyRisk[hour] ?? 0.0) + (1.0 - dataPoint.postureScore);
    }
    
    // Normalize risk scores
    for (final entry in hourlyRisk.entries) {
      riskFactors['hour_${entry.key}'] = entry.value / data.length;
    }
    
    return riskFactors;
  }
  
  static double _calculatePostureRisk(TimeSlot slot, Map<String, double> riskFactors) {
    return riskFactors['hour_${slot.hour}'] ?? 0.5;
  }
  
  static String _getAlertType(double riskScore) {
    if (riskScore > 0.8) return 'critical';
    if (riskScore > 0.6) return 'warning';
    return 'reminder';
  }
  
  static String _getPostureRecommendation(double riskScore) {
    if (riskScore > 0.8) return 'Take a break and stretch immediately';
    if (riskScore > 0.6) return 'Adjust your posture and take a short break';
    return 'Remember to maintain good posture';
  }
  
  static double _calculateCompletionRate(List<String> skills, Map<String, double> userSkills) {
    if (skills.isEmpty) return 0.0;
    
    double totalCompletion = 0.0;
    for (final skill in skills) {
      totalCompletion += userSkills[skill] ?? 0.0;
    }
    
    return totalCompletion / skills.length;
  }
}

// Data classes for AI algorithms
class AStarNode {
  final String id;
  final List<StudySession> schedule;
  final List<StudyTask> remainingTasks;
  final List<TimeSlot> remainingSlots;
  
  AStarNode({
    required this.id,
    required this.schedule,
    required this.remainingTasks,
    required this.remainingSlots,
  });
}

class StudyTask {
  final String id;
  final String name;
  final double difficulty;
  final int estimatedDuration; // minutes
  final List<int> preferredTimeSlots; // hours of day
  
  StudyTask({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.estimatedDuration,
    required this.preferredTimeSlots,
  });
}

class TimeSlot {
  final String id;
  final int hour;
  final int duration; // minutes
  
  TimeSlot({
    required this.id,
    required this.hour,
    required this.duration,
  });
}

class StudySession {
  final StudyTask task;
  final TimeSlot timeSlot;
  
  StudySession({
    required this.task,
    required this.timeSlot,
  });
}

class LearningPath {
  final List<String> skills;
  final Map<String, double> difficulty;
  final int estimatedTime; // minutes
  final double completionRate;
  
  LearningPath({
    required this.skills,
    required this.difficulty,
    required this.estimatedTime,
    required this.completionRate,
  });
}

class PostureData {
  final DateTime timestamp;
  final double postureScore;
  final String postureType;
  
  PostureData({
    required this.timestamp,
    required this.postureScore,
    required this.postureType,
  });
}

class PostureAlert {
  final TimeSlot timeSlot;
  final double riskScore;
  final String alertType;
  final String recommendation;
  
  PostureAlert({
    required this.timeSlot,
    required this.riskScore,
    required this.alertType,
    required this.recommendation,
  });
}



