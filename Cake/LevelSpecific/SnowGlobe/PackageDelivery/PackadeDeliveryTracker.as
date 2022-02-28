
UCLASS(Abstract)
class APackadeDeliveryTracker : AHazeActor
{
	UPROPERTY()
	int NumberOfPackagesToDeliver = 0;
	int Progress = 0;

	UFUNCTION()
	void SetCurrentPackageProgress(int progress)
	{
		Progress = progress;
	}

	UFUNCTION()
	void IncrementPackageProgress()
	{
		Progress++;
	}

	UFUNCTION(NetFunction)
	void CompletePackage()
	{
		Progress++;
	}

	UFUNCTION()
	bool HasDeliveredAllPackages()
	{
		return Progress >= NumberOfPackagesToDeliver;
	}
}