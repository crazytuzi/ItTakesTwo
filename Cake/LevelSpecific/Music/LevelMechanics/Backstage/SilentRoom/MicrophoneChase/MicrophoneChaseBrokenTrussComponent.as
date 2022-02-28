import Peanuts.Spline.SplineComponent;
namespace Backstage
{
	UFUNCTION()
	void SetNewBrokenTrussSpline(AHazePlayerCharacter TargetPlayer, AHazeSplineActor NewSplineActor)
	{
		UMicrophoneChaseBrokenTrussComponent Comp = UMicrophoneChaseBrokenTrussComponent::Get(TargetPlayer);

		if (Comp != nullptr)
		{
			Comp.SplineComp = UHazeSplineComponent::Get(NewSplineActor);
		}
	}
}

event void FBrokenTrussGrapple(AHazePlayerCharacter Player);

class UMicrophoneChaseBrokenTrussComponent : UActorComponent
{
	UHazeSplineComponent SplineComp;

	UPROPERTY()
	FBrokenTrussGrapple BrokenTrussGrappleEvent;

	void PlayerUsedGrappleDuringBrokenTruss(AHazePlayerCharacter Player)
	{
		SplineComp = nullptr;
		BrokenTrussGrappleEvent.Broadcast(Player);
	}
}