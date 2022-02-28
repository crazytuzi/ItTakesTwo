import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Grinding.GrindSpline;
import Vino.Movement.Grinding.GrindStatics;

class AGrindingForceGrapplePlayerTrigger : APlayerTrigger
{	
	UPROPERTY(DefaultComponent)
	UNewGrindingForceGrapplePlayerTriggerComponent ForceGrapplePlayerTriggerComp;

	UPROPERTY()
	AGrindspline TargetGrindSpline;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	default bRunConstructionScriptOnDrag = true;

	UPROPERTY()
	float DistanceAlongSpline = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (TargetGrindSpline == nullptr)
		{
			DistanceAlongSpline = 0.f;
			return;
		}

		DistanceAlongSpline = TargetGrindSpline.Spline.GetDistanceAlongSplineAtWorldLocation(TargetLocationWorldLocation);
		FVector NearestPointOnSpline = TargetGrindSpline.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		SetTargetLocationFromWorldLocation(NearestPointOnSpline);
	}

	void EnterTrigger(AActor Actor) override
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		OnPlayerEnter.Broadcast(Player);

		if (TargetGrindSpline != nullptr)
			ForceGrappleToDistanceAlongGrindSpline(Player, TargetGrindSpline, DistanceAlongSpline);
    }

	FVector GetTargetLocationWorldLocation() property
	{
		return ActorTransform.TransformPosition(TargetLocation);
	}

	void SetTargetLocationFromWorldLocation(FVector WorldLocation)
	{
		FVector RelativeLocation = ActorTransform.InverseTransformPosition(WorldLocation);
		TargetLocation = RelativeLocation;
	}
}

class UNewGrindingForceGrapplePlayerTriggerComponent : UActorComponent {}

class UNewGrindingForceGrapplePlayerTriggerVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UNewGrindingForceGrapplePlayerTriggerComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UNewGrindingForceGrapplePlayerTriggerComponent Comp = Cast<UNewGrindingForceGrapplePlayerTriggerComponent>(Component);
        if (Comp == nullptr)
            return;

		AGrindingForceGrapplePlayerTrigger ForceGrapplePlayerTrigger = Cast<AGrindingForceGrapplePlayerTrigger>(Comp.Owner);
		if (ForceGrapplePlayerTrigger == nullptr)
			return;

		if (ForceGrapplePlayerTrigger.TargetGrindSpline == nullptr)
			return;

		FVector GrappleLocation = ForceGrapplePlayerTrigger.TargetGrindSpline.Spline.GetLocationAtDistanceAlongSpline(ForceGrapplePlayerTrigger.DistanceAlongSpline, ESplineCoordinateSpace::World);

		DrawLine(ForceGrapplePlayerTrigger.ActorLocation, GrappleLocation, FLinearColor::Green, 8.f);
    }
}
