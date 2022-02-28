import Vino.Movement.Grinding.GrindingReasons;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Grinding.GrindingBaseRegionComponent;

enum EJumpToVelocityType
{
	// Will adapt your velocity to reach specified height
	SpecifyHeight,

	// Will adapt the to keep your current velocity
	KeepCurrentVelocity
}

class UGrindJumpToLocationRegionComponent : UGrindingBaseRegionComponent
{
	UPROPERTY(Meta = (MakeEditWidget))
	FTransform JumpToTransform;

	UPROPERTY()
	EJumpToVelocityType VelocityType = EJumpToVelocityType::KeepCurrentVelocity;

	UPROPERTY(Meta = (EditCondition="VelocityType == EJumpToVelocityType::SpecifyHeight", EditConditionHides))
	float JumpHeight = 500.f;

	FTransform GetWorldJumpToTransform() const property
	{
		return JumpToTransform * WorldTransform;
	}

	FVector GetJumpToLocation() const property
	{
		return WorldTransform.TransformPosition(JumpToTransform.Location);
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const property
	{
		return FLinearColor::Blue;
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
		JumpToTransform.Location = WorldTransform.InverseTransformPosition(EndPointLocation) + FVector::UpVector * 250.f;
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	void ResetTargetLocationToStart()
	{
		JumpToTransform.Location = WorldTransform.InverseTransformPosition((StartPointLocation)) + FVector::UpVector * 250.f;
		Editor::RedrawAllViewports();
	}

	UFUNCTION(CallInEditor)
	void ResetTargetLocationToEnd()
	{
		JumpToTransform.Location = WorldTransform.InverseTransformPosition((EndPointLocation)) + FVector::UpVector * 250.f;
		Editor::RedrawAllViewports();
	}
#endif
}

class UGrindJumpToLocationRegionComponentVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGrindJumpToLocationRegionComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		UGrindJumpToLocationRegionComponent JumpOffComponent = Cast<UGrindJumpToLocationRegionComponent>(Component);
		if (JumpOffComponent == nullptr)
			return;

		FVector RegionStartPos = JumpOffComponent.GetStartPointLocation();
		FVector RegionEndPos = JumpOffComponent.GetEndPointLocation();

		float Gravity = 980.f * 6.1f;
		float ActorMaxFallSpeed = 1800.f;
		float CurveHeight = JumpOffComponent.JumpHeight;

		FVector Velocity;
		if (JumpOffComponent.VelocityType == EJumpToVelocityType::SpecifyHeight)
			Velocity = CalculateParamsForPathWithHeight(RegionEndPos, JumpOffComponent.JumpToLocation, Gravity, CurveHeight, ActorMaxFallSpeed).Velocity;
		else
		{
			FVector HorizontalVelocity = ((JumpOffComponent.JumpToLocation - RegionEndPos).GetSafeNormal() * GrindSettings::Speed.BasicSettings.DesiredMiddle).ConstrainToPlane(FVector::UpVector);
			Velocity = CalculateVelocityForPathWithHorizontalSpeed(RegionEndPos, JumpOffComponent.JumpToLocation, Gravity, HorizontalVelocity.Size());
			Velocity += HorizontalVelocity;
		}

		FTrajectoryPoints TrajectoryPoints = CalculateTrajectory(RegionEndPos, 7000.f, Velocity, Gravity, 1.f, ActorMaxFallSpeed);
		
		FVector LineStartPos = RegionEndPos;
		FVector LineEndPos = JumpOffComponent.JumpToLocation;

		FVector PrevPoint = RegionEndPos;
		int IPoint = 0;
		for (FVector Point : TrajectoryPoints.Positions)
		{
			if (IPoint++ == 0)
				continue;
			
			DrawDashedLine(PrevPoint, Point, FLinearColor::Green);
			PrevPoint = Point;
		}
	}
}
