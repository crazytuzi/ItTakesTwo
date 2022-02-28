enum EObjectiveStatus
{
	Removed,
	Completed,
};

struct FObjectiveData
{
	// Text to display on screen for the objective
	UPROPERTY()
	FText Text;

	// Sort order to place it in the objectives list with 
	UPROPERTY()
	float DisplayOrder = 0.f;
};