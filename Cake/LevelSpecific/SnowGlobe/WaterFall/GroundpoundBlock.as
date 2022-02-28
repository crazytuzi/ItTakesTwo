import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Peanuts.Spline.SplineComponent;

class AWaterfallGroundpoundBlockActor : AHazeactor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComponent;

	bool bShouldPlayBackward = false;

	UPROPERTY()
	FHazeTimeLike Timelike;

	default Timelike.Duration = 2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = UHazeSplineComponent::GetOrCreate(this);
		GroundPoundComponent.OnActorGroundPounded.AddUFunction(this, n"OnPounded");
		Spline.DetachFromParent(true, true);
		Timelike.BindUpdate(this, n"TickTimelike");
	}

	UFUNCTION()
	void TickTimelike(float CurrentValue)
	{
		float CurDistance = Spline.SplineLength * (CurrentValue);

		if(bShouldPlayBackward)
		{
			CurDistance = Spline.SplineLength * (1 - CurrentValue);
		}
		FVector Worldlocation = Spline.GetLocationAtDistanceAlongSpline(CurDistance, ESplineCoordinateSpace::World);
		Mesh.SetWorldLocation(Worldlocation);
	}

	UFUNCTION()
	void OnPounded(AHazePlayerCharacter PlayerGroundPoundingActor)
	{
		if (ShouldPlayAtAll(PlayerGroundPoundingActor))
		{
			if(!Timelike.IsPlaying())
			{
				bShouldPlayBackward = GetShouldPlayBackward(PlayerGroundPoundingActor);

				if (bShouldPlayBackward)
				{
					Timelike.PlayFromStart();
				}
				else
				{
					Timelike.PlayFromStart();
				}
			}
		}
	}

	bool ShouldPlayAtAll(AHazePlayerCharacter PlayerGroundPoundingActor)
	{
		if (PlayerGroundPoundingActor.ActorUpVector.Equals(Arrow.ForwardVector, 1) ||
			PlayerGroundPoundingActor.ActorUpVector.Equals(Arrow.ForwardVector * -1, 1))
		{
			return true;
		}
		return false;
	}

	bool GetShouldPlayBackward(AHazePlayerCharacter PlayerGroundPoundingActor)
	{
		if(PlayerGroundPoundingActor.ActorUpVector.Equals(Arrow.ForwardVector, 1))
		{
			return true;
		}
		else 
		{
			return false;
		}
	}
}