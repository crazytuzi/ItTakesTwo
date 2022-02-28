import Peanuts.Spline.SplineComponent;

class USawPlatformSplineComponent : UHazeSplineComponent

{
	UPROPERTY(Category = SawPlatform)
	TArray<USawPlatformSplineComponent> DependencySplines;

	UFUNCTION()
	void ClearDependencies()
	{
		DependencySplines.Empty();
	}


	UFUNCTION()
	void AddDependency(USawPlatformSplineComponent Spline)
	{
		DependencySplines.Add(Spline);
	}

	UFUNCTION()
	void AddDependencies(TArray<USawPlatformSplineComponent> Splines)
	{
		DependencySplines.Append(Splines);
	}


	UFUNCTION()
	void RemoveDependency(USawPlatformSplineComponent Spline)
	{
		DependencySplines.Remove(Spline);
	}

	UFUNCTION(BlueprintPure)
	bool HasAnyDependencies()
	{
		return DependencySplines.Num() > 0;
	}	
}