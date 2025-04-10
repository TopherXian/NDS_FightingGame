# AI Testing Framework for Fighting Game

This testing framework provides a comprehensive suite of tests for validating the LSTM-based AI system used in the fighting game.

## Setting Up the Test Scene

1. **Open the Godot Project**
   - Launch the Godot Engine
   - Open your fighting game project

2. **Load the Test Scene**
   - Open the `Scenes/ai_test_suite.tscn` scene

3. **Running Tests**
   - To run the test scene, click the play button in the Godot editor
   - Alternatively, you can run the test scene in the context of your game by adding the test scene to your main scene temporarily

## Test Process

The AI test suite evaluates the following components:

1. **Data Collection**
   - Initialization
   - Data storage
   - Action logging
   - Combat metrics tracking

2. **AI Controller**
   - LSTM initialization
   - Feature extraction
   - Prediction generation
   - Action execution

3. **Difficulty Adjuster**
   - Initialization
   - Difficulty calculation
   - Skill metrics
   - Dynamic adjustment

4. **Integration**
   - Animation syncing
   - Hitbox activation
   - Signal connections
   - Performance testing

## Interpreting Results

- **Green checkmarks** (✅) indicate passing tests
- **Red X marks** (❌) indicate failing tests
- Detailed logs of each test are displayed in the main panel
- A summary of results is shown at the end of testing

## Common Issues and Solutions

### No AI Controller Found
- Make sure the `dummy_ryu_ai.gd` script is properly loaded
- Verify that the AIController node is created in the scene

### Prediction Timeouts
- Check that the LSTM network is correctly initialized
- Ensure the thread implementation is working properly

### Animation Test Failures
- Verify that animation names match exactly with the ones used in the code
- Check that the animation player node is correctly referenced

## Extending the Test Suite

To add new tests to the framework:

1. Add a new test function to `ai_test_suite.gd`
2. Register your test in the `test_sequence` array 
3. Make sure to call either `test_passed()` or `test_failed()` at the end of your test

Example:

```gdscript
func test_my_new_feature():
    if some_condition:
        test_passed("My feature works!")
    else:
        test_failed("My feature is broken!")
```

## Integration with CI/CD

For automated testing, you can:

1. Run tests via Godot's command-line interface
2. Parse the output logs for pass/fail status
3. Generate reports based on test results

## Performance Considerations

- The LSTM prediction tests might be slower than other tests
- The performance test measures average prediction time
- Target performance: < 500ms per prediction on average hardware

