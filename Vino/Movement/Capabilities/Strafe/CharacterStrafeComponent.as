import Peanuts.Spline.SplineComponent;

class UCharacterStrafeComponent : UActorComponent
{
	UPROPERTY()
	bool bIsStrafing = false;

	UPROPERTY()
	UBlendSpace StrafeBlendSpace;

	UPROPERTY()
	UHazeSplineComponent CurrentSpline;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		bIsStrafing = false;
		StrafeBlendSpace = nullptr;
		CurrentSpline = nullptr;
	}
}