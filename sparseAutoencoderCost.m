function [cost,grad] = sparseAutoencoderCost(theta, visibleSize, hiddenSize, ...
                                             lambda, sparsityParam, beta, data)

% visibleSize: the number of input units (probably 64) 
% hiddenSize: the number of hidden units (probably 25) 
% lambda: weight decay parameter
% sparsityParam: The desired average activation for the hidden units (denoted in the lecture
%                           notes by the greek alphabet rho, which looks like a lower-case "p").
% beta: weight of sparsity penalty term
% data: Our 64x10000 matrix containing the training data.  So, data(:,i) is the i-th training example. 
  
% The input theta is a vector (because minFunc expects the parameters to be a vector). 
% We first convert theta to the (W1, W2, b1, b2) matrix/vector format, so that this 
% follows the notation convention of the lecture notes. 

W1 = reshape(theta(1:hiddenSize*visibleSize), hiddenSize, visibleSize);
W2 = reshape(theta(hiddenSize*visibleSize+1:2*hiddenSize*visibleSize), visibleSize, hiddenSize);
b1 = theta(2*hiddenSize*visibleSize+1:2*hiddenSize*visibleSize+hiddenSize);
b2 = theta(2*hiddenSize*visibleSize+hiddenSize+1:end);

% Cost and gradient variables (your code needs to compute these values). 
% Here, we initialize them to zeros. 
cost = 0;
W1grad = zeros(size(W1));
W2grad = zeros(size(W2));
b1grad = zeros(size(b1));
b2grad = zeros(size(b2));

%% ---------- YOUR CODE HERE --------------------------------------
%  Instructions: Compute the cost/optimization objective J_sparse(W,b) for the Sparse Autoencoder,
%                and the corresponding gradients W1grad, W2grad, b1grad, b2grad.
%
% W1grad, W2grad, b1grad and b2grad should be computed using backpropagation.
% Note that W1grad has the same dimensions as W1, b1grad has the same dimensions
% as b1, etc.  Your code should set W1grad to be the partial derivative of J_sparse(W,b) with
% respect to W1.  I.e., W1grad(i,j) should be the partial derivative of J_sparse(W,b) 
% with respect to the input parameter W1(i,j).  Thus, W1grad should be equal to the term 
% [(1/m) \Delta W^{(1)} + \lambda W^{(1)}] in the last block of pseudo-code in Section 2.2 
% of the lecture notes (and similarly for W2grad, b1grad, b2grad).
% 
% Stated differently, if we were using batch gradient descent to optimize the parameters,
% the gradient descent update to W1 would be W1 := W1 - alpha * W1grad, and similarly for W2, b1, b2. 
% 

% 1.
weight_diff2 = zeros(size(W2));
bias_diff2 = zeros(size(b2));
weight_diff1 = zeros(size(W1));
bias_diff1 = zeros(size(b1));

m = size(data,2);
% 2.
for i = 1:m
    % Could pack some operations into a single SIMD instruction (vectorial)
    
    % 2.a
    % FORWARD
    a1 = data(:,i);
    z2 = W1*data(:,i) + b1;
    a2 = sigmoid(z2);
    z3 = W2*a2 + b2;
    a3 = sigmoid(z3);
    % BACKWARDS
    delta3 = -(data(:,i) - a3) .* (a3.*(1 - a3));
    delta2 = (transpose(W2)*delta3) .* (a2.*(1-a2));
    
    weight_par_der2 = delta3 * transpose(a2);
    bias_par_der2 = delta3;
    weight_par_der1 = delta2 * transpose(a1);
    bias_par_der1 = delta2;
    
    % 2.b & 2.c
    weight_diff2 = weight_diff2 + weight_par_der2;
    bias_diff2 = bias_diff2 + bias_par_der2;
    weight_diff1 = weight_diff1 + weight_par_der1;
    bias_diff1 = bias_diff1 + bias_par_der1;
    
    % Sum cost for each measure
    cost = cost + (sum((a3 - data(:,i)).^2) / 2);
end

% Get the mean
cost = cost / m;
% Regularization
reg_term = (sum(sum(W1.^2)) + sum(sum(W2.^2))) / 2;
reg_term = reg_term * lambda;
cost = cost + reg_term;

% 3.
W2grad = ((1/m) * weight_diff2 + lambda * W2);
b2grad = ((1/m) * bias_diff2);
W1grad = ((1/m) * weight_diff1 + lambda * W1);
b1grad = ((1/m) * bias_diff1);

%-------------------------------------------------------------------
% After computing the cost and gradient, we will convert the gradients back
% to a vector format (suitable for minFunc).  Specifically, we will unroll
% your gradient matrices into a vector.

grad = [W1grad(:) ; W2grad(:) ; b1grad(:) ; b2grad(:)];

end

%-------------------------------------------------------------------
% Here's an implementation of the sigmoid function, which you may find useful
% in your computation of the costs and the gradients.  This inputs a (row or
% column) vector (say (z1, z2, z3)) and returns (f(z1), f(z2), f(z3)). 

function sigm = sigmoid(x)
  
    sigm = 1 ./ (1 + exp(-x));
end

