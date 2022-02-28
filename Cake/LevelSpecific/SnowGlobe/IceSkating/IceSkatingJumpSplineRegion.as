import Vino.Movement.Grinding.GrindSpline;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;

class UIceSkatingJumpSplineRegionVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIceSkatingJumpSplineRegionComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		FIceSkatingAirSettings AirSettings;
		FIceSkatingGrindSettings GrindSettings;

		auto Region = Cast<UIceSkatingJumpSplineRegionComponent>(Component);
		auto GrindSpline = Cast<AGrindspline>(Component.Owner);
		FHazeSplineSystemPosition SplinePosition = Region.GetLaunchPosition();

		FVector Velocity = SplinePosition.WorldForwardVector * GrindSpline.CustomSpeed.DesiredMiddle;
		Velocity += FVector::UpVector * GrindSettings.JumpUpImpulse;

		// Get points
		FTrajectoryPoints VisPoints = CalculateTrajectory(SplinePosition.WorldLocation, Region.VisLength, Velocity, AirSettings.Gravity, 1.f, AirSettings.MaxFallSpeed); 

		// Draw lines and stars!
		for(int i=0; i<VisPoints.Num(); ++i)
		{
			// If this is the last point, we cant draw a line to the next one
			if (i < VisPoints.Num() - 1)
			{
				FVector Position = VisPoints.Positions[i];
				FVector NextPosition = VisPoints.Positions[i + 1];
				DrawLine(Position, NextPosition, FLinearColor::Green, 10.f);
			}
		}
	}
}

class UIceSkatingJumpSplineRegionComponent : UHazeSplineRegionComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Jumping")
	bool bReverseDirection = false;

	UPROPERTY(EditInstanceOnly, Category = "Visualization")
	float VisLength = 5000.f;

	UPROPERTY(EditInstanceOnly, Category = "Visualization")
	bool bLockInputAfterJump = false;

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const
	{
		return FLinearColor::Red;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor Actor)
	{
		auto SkateComp = UIceSkatingComponent::Get(Actor);
		if (SkateComp == nullptr)
			return;

		Actor.BlockCapabilities(IceSkatingTags::Jump, this);
		Actor.BlockCapabilities(GrindingCapabilityTags::Jump, this);

		if (bLockInputAfterJump)
			SkateComp.bGrindJumpShouldBlockInput = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionExit(AHazeActor Actor, ERegionExitReason ExitReason)
	{
		auto SkateComp = UIceSkatingComponent::Get(Actor);
		if (SkateComp == nullptr)
			return;

		Actor.UnblockCapabilities(IceSkatingTags::Jump, this);
		Actor.UnblockCapabilities(GrindingCapabilityTags::Jump, this);

		SkateComp.ForceJumpPosition = GetLaunchPosition();
	}

	FHazeSplineSystemPosition GetLaunchPosition()
	{
		if (bReverseDirection)
			return GetStartPosition(false);
		else
			return GetEndPosition(true);
	}
}