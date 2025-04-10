# AI System Structure and Components

This document explains the organization of the AI system in the fighting game.

## Overview

The AI system consists of three main components:

1. **Data Collection System** (training_data_collector.gd)
2. **LSTM AI Controller** (dummy_ryu_ai.gd)
3. **Difficulty Adjustment System** (difficulty_adjuster.gd)

These components work together to create an adaptive AI opponent that can respond to player actions and adjust its difficulty over time.

## Core Components

### 1. Data Collection System

**File: training_data_collector.gd**

This component:
- Records player and AI actions during gameplay
- Tracks health, positioning, and combat metrics
- Stores data for analysis and training
- Provides feedback to the difficulty adjuster

Key functionality:
- Session tracking with unique session IDs
- Action logging with timestamps and spatial data
- Combat metrics (hits, combos, damage)
- Data storage and retrieval

### 2. LSTM AI Controller

**File: dummy_ryu_ai.gd**

This component:
- Contains the LSTM neural network model
- Processes game state into feature vectors
- Predicts the next optimal action
- Executes actions on the character

Key functionality:
- Feature extraction from game state
- LSTM state management
- Action prediction with confidence scores
- Threading for performance optimization
- Action execution via signals

### 3. Difficulty Adjustment System

**File: difficulty_adjuster.gd**

This component:
- Analyzes player performance
- Adjusts AI difficulty dynamically
- Balances challenge level for optimal player experience
- Provides feedback on difficulty changes

Key functionality:
- Player skill assessment
- Win/loss analysis
- Combat metrics evaluation
- Difficulty scaling algorithms
- Adaptive response to player improvement

## Integration in the Game

The AI components are integrated into the game through:

1. **AIController Node** in dummy_ryu.tscn
   - Manages the AI components
   - Initializes the LSTM model
   - Routes signals between components

2. **Signal Connections** in game_scene_manager.gd
   - Connects AI actions to UI updates
   - Monitors difficulty changes
   - Tracks match outcomes

3. **Testing Framework** in ai_test_suite.gd
   - Validates AI component functionality
   - Tests integration between systems
   - Measures performance metrics

## Data Flow

1. Game state → Feature extraction → LSTM input
2. LSTM output → Action selection → Character movement/attacks
3. Action results → Data collection → Skill assessment → Difficulty adjustment

## Extending the AI System

To extend the AI capabilities:

1. **Add New Actions**
   - Implement new action types in dummy_ryu.tscn
   - Add corresponding entries in the LSTM output layer
   - Update action execution handlers

2. **Improve Feature Extraction**
   - Add new features to capture more game state information
   - Normalize and scale features appropriately
   - Update the input layer dimensions

3. **Enhance Difficulty Adjustment**
   - Implement more sophisticated player skill metrics
   - Add dynamic difficulty curves
   - Create difficulty presets for different player levels

## Debugging Tools

The AI system includes debugging tools:

1. **AI Test Suite** (ai_test_suite.tscn)
   - Component validation tests
   - Integration tests
   - Performance benchmarks

2. **Runtime Debugging**
   - AIStatusPanel in the game UI
   - Console logging for AI decisions
   - Difficulty change notifications
