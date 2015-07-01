local alpha = {
	beta = {
		gamma = 42
	}
}
local test = alpha.beta.gamma + 16
alpha.beta.gamma = test
