import Vino.Camera.Components.CameraKeepInViewComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleCamera.CastleCameraComponent;
import Peanuts.Spline.SplineComponent;

class ACastleCamera : AHazeCameraActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UHazeCameraRootComponent CameraRootComponent;

    UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
    UCastleCameraComponent CastleSplineComponent;
	default CastleSplineComponent.CameraSpline = CameraSpline;

    UPROPERTY(DefaultComponent, Attach = CastleSplineComponent)
	UCameraKeepInViewComponent KeepInViewComponent;
	default KeepInViewComponent.SetRelativeRotation(FRotator(-50, 0, 0));
	default KeepInViewComponent.MinDistance = 2100;
	default KeepInViewComponent.MaxDistance = 2500;
	default KeepInViewComponent.BufferDistance = 1000;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;
	default Camera.Settings.bUseFOV = true;
	default Camera.Settings.FOV = 50.f;

	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;

#if EDITOR

	//UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (InlineEditConditionToggle), Category = "Editor Visualization")
	bool bUsePreviewSplineFraction = false;

	//UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (ClampMin=0, ClampMax=1, EditCondition = "bUsePreviewSplineFraction"), Category = "Editor Visualization")
	float PreviewSplineFraction = 0.f;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Editor Visualization")
	TArray<FVector> PreviewFocusLocations;
	default if (PreviewFocusLocations.Num() == 0) PreviewFocusLocations.Add(GetActorLocation() + GetActorForwardVector() * 1000.f);
#endif

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {

#if EDITOR // Should be superflous, but just to be sure...
		// Adjust visualized FOV (we should really do this for all focustrackcamera actors)
		if (Camera.Settings.bUseFOV)
			Camera.FieldOfView = Camera.Settings.FOV;			
#endif // EDITOR

    }

	UFUNCTION()
	void AddTarget(FExtraFocusTarget Target)
	{
		if (CastleSplineComponent.ExtraFocusTargets.Contains(Target))
		{
			for (int Index = 0; Index < CastleSplineComponent.ExtraFocusTargets.Num(); Index ++)
			{
				if (CastleSplineComponent.ExtraFocusTargets[Index] == Target)
				{
					CastleSplineComponent.ExtraFocusTargets[Index].Weight = Target.Weight;
					return;
				}
			}
		}
		else
			CastleSplineComponent.ExtraFocusTargets.AddUnique(Target);
	}

	UFUNCTION()
	void RemoveTarget(AHazeActor Target)
	{
		for (int Index = 0; Index < CastleSplineComponent.ExtraFocusTargets.Num(); Index ++)
		{
			if (CastleSplineComponent.ExtraFocusTargets[Index] == Target)
			{	
				CastleSplineComponent.ExtraFocusTargets.RemoveAt(0);
				return;
			}
		}		
	}
}