# FULLY IMPLEMENTED: Train the LSTM model from collected data

# Constants for the LSTM model
const INPUT_SIZE = 16   # Size of input feature vector
const HIDDEN_SIZE = 32  # Size of hidden state and cell state
const OUTPUT_SIZE = 4   # Number of possible actions
const LEARNING_RATE = 0.01  # Learning rate for gradient descent

# Weight matrices
var input_weights = []   # Weights for input gate
var forget_weights = []  # Weights for forget gate
var output_weights = []  # Weights for output gate
var cell_weights = []    # Weights for cell candidate
var fc_weights = []      # Weights for fully connected output layer

# Gradient accumulators
var input_weights_gradients = []
var forget_weights_gradients = []
var output_weights_gradients = []
var cell_weights_gradients = []
var fc_weights_gradients = []

# State variables
var hidden_state = []    # Hidden state of LSTM
var cell_state = []      # Cell state of LSTM
var is_training = false  # Flag to indicate if model is currently training
var rng = RandomNumberGenerator.new()  # Random number generator for training

# Data collector reference
var data_collector = null
func _ready():
	# Initialize the model weights and states
	_initialize_model()
	
func _initialize_model():
	# Seed the random number generator
	rng.randomize()
	
	# Initialize hidden state and cell state with zeros
	hidden_state = _create_zero_vector(HIDDEN_SIZE)
	cell_state = _create_zero_vector(HIDDEN_SIZE)
	
	# Initialize weight matrices with random values
	input_weights = _create_random_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	forget_weights = _create_random_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	output_weights = _create_random_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	cell_weights = _create_random_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	fc_weights = _create_random_matrix(OUTPUT_SIZE, HIDDEN_SIZE)
	
	# Initialize gradient accumulators
	_zero_gradients()
	
# Helper for creating a matrix with random values
func _create_random_matrix(rows, cols):
	var result = []
	for i in range(rows):
		result.append([])
		for j in range(cols):
			# Initialize with small random values
			result[i].append(rng.randf_range(-0.1, 0.1))
	return result
	if data_collector == null:
		emit_signal("prediction_error", "Data collector not set up")
		return
		
	print("Starting model training...")
	is_training = true
	
	# Get training data from collector
	var training_data = data_collector.get_lstm_training_data()
	if training_data.size() == 0:
		print("No training data available")
		is_training = false
		return
	
	# Perform mini-batch training
	var iterations = 100  # Number of training iterations
	var batch_size = min(32, training_data.size())
	
	for iter in range(iterations):
		# Reset gradients
		_zero_gradients()
		
		# Sample a mini-batch
		var batch = []
		for i in range(batch_size):
			var idx = rng.randi() % training_data.size()
			batch.append(training_data[idx])
		
		# Process each sample in the batch
		var total_loss = 0.0
		for sample in batch:
			# Extract features and target from sample
			var features = _extract_features_from_sample(sample)
			var target_idx = _get_target_action_index(sample)
			
			# Forward pass
			var forward_result = _lstm_forward_pass_with_cache(features)
			var lstm_output = forward_result[0]
			var cache = forward_result[1]
			
			# Create one-hot encoded target
			var target = _create_zero_vector(OUTPUT_SIZE)
			target[target_idx] = 1.0
			
			# Calculate cross-entropy loss
			var loss = _cross_entropy_loss(lstm_output, target)
			total_loss += loss
			
			# Backward pass
			_lstm_backward_pass(lstm_output, target, cache)
			
			# Update weights (gradient accumulation)
			_accumulate_gradients()
		
		# Apply weight updates with averaged gradients
		_update_weights(LEARNING_RATE, batch_size)
		
		# Print progress
		if iter % 10 == 0:
			print("Training iteration ", iter, ", Average loss: ", total_loss / batch_size)
	
	print("Model training completed")
	is_training = false
	emit_signal("model_trained")

# Forward pass specifically for training (returns cache for backprop)
func _lstm_forward_pass_with_cache(features):
	# This is similar to _lstm_forward_pass but returns the complete cache
	var cache = {}
	
	# Add hidden state to input
	var combined_input = features + hidden_state
	cache["combined_input"] = combined_input
	cache["features"] = features.duplicate()
	
	# Calculate input gate
	var input_gate_net = _matrix_vector_multiply(input_weights, combined_input)
	var input_gate = _sigmoid_vector(input_gate_net)
	cache["input_gate_net"] = input_gate_net
	cache["input_gate"] = input_gate
	
	# Calculate forget gate
	var forget_gate_net = _matrix_vector_multiply(forget_weights, combined_input)
	var forget_gate = _sigmoid_vector(forget_gate_net)
	cache["forget_gate_net"] = forget_gate_net
	cache["forget_gate"] = forget_gate
	
	# Calculate output gate
	var output_gate_net = _matrix_vector_multiply(output_weights, combined_input)
	var output_gate = _sigmoid_vector(output_gate_net)
	cache["output_gate_net"] = output_gate_net
	cache["output_gate"] = output_gate
	
	# Calculate cell candidate
	var cell_candidate_net = _matrix_vector_multiply(cell_weights, combined_input)
	var cell_candidate = _tanh_vector(cell_candidate_net)
	cache["cell_candidate_net"] = cell_candidate_net
	cache["cell_candidate"] = cell_candidate
	
	# Previous cell state for backpropagation
	cache["prev_cell_state"] = cell_state.duplicate()
	
	# Update cell state
	var new_cell_state = []
	for i in range(cell_state.size()):
		new_cell_state.append(forget_gate[i] * cell_state[i] + input_gate[i] * cell_candidate[i])
	cell_state = new_cell_state
	cache["cell_state"] = cell_state.duplicate()
	
	# Calculate cell state activation
	var cell_state_act = _tanh_vector(cell_state)
	cache["cell_state_act"] = cell_state_act
	
	# Update hidden state
	var new_hidden_state = []
	for i in range(hidden_state.size()):
		new_hidden_state.append(output_gate[i] * cell_state_act[i])
	
	# Previous hidden state for backpropagation
	cache["prev_hidden_state"] = hidden_state.duplicate()
	hidden_state = new_hidden_state
	cache["hidden_state"] = hidden_state.duplicate()
	
	# Final output layer (fully connected)
	var final_output = _matrix_vector_multiply(fc_weights, hidden_state)
	var softmax_output = _softmax_vector(final_output)
	cache["final_output"] = final_output
	cache["softmax_output"] = softmax_output
	
	return [softmax_output, cache]

# Backward pass for LSTM with cross-entropy loss
func _lstm_backward_pass(output, target, cache):
	# Calculate output layer gradients (cross-entropy with softmax)
	var output_grad = []
	for i in range(output.size()):
		output_grad.append(output[i] - target[i])  # Derivative of softmax + cross-entropy
	
	# Gradient for fully connected layer
	var hidden_state_grad = _matrix_transpose_vector_multiply(fc_weights, output_grad)
	var fc_weights_grad = _outer_product(output_grad, cache["hidden_state"])
	
	# Accumulate fc_weights gradients
	for i in range(fc_weights_grad.size()):
		for j in range(fc_weights_grad[i].size()):
			fc_weights_gradients[i][j] += fc_weights_grad[i][j]
	
	# Initialize gradients for LSTM components
	var next_hidden_grad = hidden_state_grad
	var next_cell_grad = _create_zero_vector(HIDDEN_SIZE)
	
	# LSTM backward pass
	# Gradient for output gate
	var cell_state_act = cache["cell_state_act"]
	var output_gate = cache["output_gate"]
	var output_gate_grad = []
	
	for i in range(HIDDEN_SIZE):
		output_gate_grad.append(next_hidden_grad[i] * cell_state_act[i] * output_gate[i] * (1.0 - output_gate[i]))
	
	# Gradient for cell state (from hidden state and next cell grad)
	var cell_state_grad = []
	for i in range(HIDDEN_SIZE):
		var tanh_deriv = 1.0 - cell_state_act[i] * cell_state_act[i]  # Derivative of tanh
		cell_state_grad.append(next_hidden_grad[i] * cache["output_gate"][i] * tanh_deriv + next_cell_grad[i])
	
	# Gradient for forget gate
	var forget_gate = cache["forget_gate"]
	var forget_gate_grad = []
	for i in range(HIDDEN_SIZE):
		forget_gate_grad.append(cell_state_grad[i] * cache["prev_cell_state"][i] * forget_gate[i] * (1.0 - forget_gate[i]))
	
	# Gradient for input gate
	var input_gate = cache["input_gate"]
	var input_gate_grad = []
	for i in range(HIDDEN_SIZE):
		input_gate_grad.append(cell_state_grad[i] * cache["cell_candidate"][i] * input_gate[i] * (1.0 - input_gate[i]))
	
	# Gradient for cell candidate
	var cell_candidate = cache["cell_candidate"]
	var cell_candidate_grad = []
	for i in range(HIDDEN_SIZE):
		cell_candidate_grad.append(cell_state_grad[i] * cache["input_gate"][i] * (1.0 - cell_candidate[i] * cell_candidate[i]))
	
	# Gradient for previous cell state (for next timestep's backprop)
	var prev_cell_grad = []
	for i in range(HIDDEN_SIZE):
		prev_cell_grad.append(cell_state_grad[i] * cache["forget_gate"][i])
	
	# Compute gradients for combined input
	var combined_input_grad = _create_zero_vector(HIDDEN_SIZE + INPUT_SIZE)
	
	# Add gradients from each gate
	var input_grad = _matrix_transpose_vector_multiply(input_weights, input_gate_grad)
	var forget_grad = _matrix_transpose_vector_multiply(forget_weights, forget_gate_grad)
	var output_gate_combined_grad = _matrix_transpose_vector_multiply(output_weights, output_gate_grad)
	var cell_grad = _matrix_transpose_vector_multiply(cell_weights, cell_candidate_grad)
	
	for i in range(combined_input_grad.size()):
		combined_input_grad[i] = input_grad[i] + forget_grad[i] + output_gate_combined_grad[i] + cell_grad[i]
	
	# Split combined input gradient into features and hidden state gradients
	var features_grad = []
	var hidden_grad = []
	
	for i in range(INPUT_SIZE):
		features_grad.append(combined_input_grad[i])
	
	for i in range(HIDDEN_SIZE):
		hidden_grad.append(combined_input_grad[i + INPUT_SIZE])
	
	# Calculate weight gradients
	var input_weights_grad = _outer_product(input_gate_grad, cache["combined_input"])
	var forget_weights_grad = _outer_product(forget_gate_grad, cache["combined_input"])
	var output_weights_grad = _outer_product(output_gate_grad, cache["combined_input"])
	var cell_weights_grad = _outer_product(cell_candidate_grad, cache["combined_input"])
	
	# Accumulate weight gradients
	for i in range(HIDDEN_SIZE):
		for j in range(HIDDEN_SIZE + INPUT_SIZE):
			input_weights_gradients[i][j] += input_weights_grad[i][j]
			forget_weights_gradients[i][j] += forget_weights_grad[i][j]
			output_weights_gradients[i][j] += output_weights_grad[i][j]
			cell_weights_gradients[i][j] += cell_weights_grad[i][j]

# Helper functions for backpropagation
func _zero_gradients():
	# Reset all gradient accumulators to zero
	input_weights_gradients = _create_zero_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	forget_weights_gradients = _create_zero_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	output_weights_gradients = _create_zero_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	cell_weights_gradients = _create_zero_matrix(HIDDEN_SIZE, HIDDEN_SIZE + INPUT_SIZE)
	fc_weights_gradients = _create_zero_matrix(OUTPUT_SIZE, HIDDEN_SIZE)

func _accumulate_gradients():
	# This function is called in the training loop to accumulate gradients
	# But in our implementation, gradients are already accumulated in _lstm_backward_pass
	pass

func _update_weights(learning_rate, batch_size):
	# Apply gradients to weights, with normalization by batch size
	var lr = learning_rate / batch_size
	
	# Update input gate weights
	for i in range(HIDDEN_SIZE):
		for j in range(HIDDEN_SIZE + INPUT_SIZE):
			input_weights[i][j] -= lr * input_weights_gradients[i][j]
	
	# Update forget gate weights
	for i in range(HIDDEN_SIZE):
		for j in range(HIDDEN_SIZE + INPUT_SIZE):
			forget_weights[i][j] -= lr * forget_weights_gradients[i][j]
	
	# Update output gate weights
	for i in range(HIDDEN_SIZE):
		for j in range(HIDDEN_SIZE + INPUT_SIZE):
			output_weights[i][j] -= lr * output_weights_gradients[i][j]
	
	# Update cell candidate weights
	for i in range(HIDDEN_SIZE):
		for j in range(HIDDEN_SIZE + INPUT_SIZE):
			cell_weights[i][j] -= lr * cell_weights_gradients[i][j]
	
	# Update fully connected weights
	for i in range(OUTPUT_SIZE):
		for j in range(HIDDEN_SIZE):
			fc_weights[i][j] -= lr * fc_weights_gradients[i][j]

# Helper for matrix-vector multiplication
func _matrix_vector_multiply(matrix, vector):
	var result = []
	for i in range(matrix.size()):
		var sum = 0.0
		for j in range(vector.size()):
			sum += matrix[i][j] * vector[j]
		result.append(sum)
	return result

# Helper for matrix-transpose-vector multiplication
func _matrix_transpose_vector_multiply(matrix, vector):
	var result = _create_zero_vector(matrix[0].size())
	for i in range(matrix.size()):
		for j in range(matrix[0].size()):
			result[j] += matrix[i][j] * vector[i]
	return result

# Helper for outer product
func _outer_product(vec_a, vec_b):
	var result = []
	for i in range(vec_a.size()):
		result.append([])
		for j in range(vec_b.size()):
			result[i].append(vec_a[i] * vec_b[j])
	return result

# Helper for creating a zero vector
func _create_zero_vector(size):
	var result = []
	for i in range(size):
		result.append(0.0)
	return result

# Helper for creating a zero matrix
func _create_zero_matrix(rows, cols):
	var result = []
	for i in range(rows):
		result.append([])
		for j in range(cols):
			result[i].append(0.0)
	return result

# Activation functions and their derivatives
func _sigmoid_vector(vec):
	var result = []
	for i in range(vec.size()):
		result.append(1.0 / (1.0 + exp(-vec[i])))
	return result

func _tanh_vector(vec):
	var result = []
	for i in range(vec.size()):
		result.append(tanh(vec[i]))
	return result

func _softmax_vector(vec):
	var result = []
	var max_val = vec[0]
	for i in range(1, vec.size()):
		max_val = max(max_val, vec[i])
	
	var sum_exp = 0.0
	for i in range(vec.size()):
		sum_exp += exp(vec[i] - max_val)  # Subtract max for numerical stability
	
	for i in range(vec.size()):
		result.append(exp(vec[i] - max_val) / sum_exp)
	
	return result

# Calculate cross-entropy loss
func _cross_entropy_loss(output, target):
	var loss = 0.0
	var epsilon = 0.0000001  # Small constant to avoid log(0)
	
	for i in range(output.size()):
		if target[i] > 0:
			loss -= target[i] * log(output[i] + epsilon)
	
	return loss

func _extract_features_from_sample(sample):
	# Extract and normalize features from a training sample
	var features = []
	
	# Game state features
	for feature in sample["game_state"]:
		features.append(feature)
	
	# Normalize features if needed
	# ...
	
	return features

func _get_target_action_index(sample):
	# Get the index of the action taken in this sample
	return sample["action"]