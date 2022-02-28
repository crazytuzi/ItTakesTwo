import Peanuts.Spline.SplineActor;

class AMagnetFishSpline : ASplineActor
{
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;
}

class AMagnetFishSplineManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent VisualBoarder;
	default VisualBoarder.SphereRadius = 1500.f;

	UPROPERTY(EditInstanceOnly)
	TArray<AMagnetFishSpline> ControlledFishes;

	float DisableRange = 10000.f;
	bool bHasDisabled = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const bool bWantToDisable = ShouldAutoDisable();
		if(bHasDisabled != bWantToDisable)
		{
			bHasDisabled = bWantToDisable;
			if(bHasDisabled)
			{
				for(auto Fish : ControlledFishes)
				{
					Fish.DisableActor(this);
				}
			}
			else
			{
				for(auto Fish : ControlledFishes)
				{
					Fish.EnableActor(this);
				}
			}
		}
	}

	private bool ShouldAutoDisable() const
	{
		float ClosestPlayerDistSq = BIG_NUMBER;
		for(auto Player : Game::GetPlayers())
		{
			const float Dist = Player.GetActorLocation().DistSquared(GetActorLocation());
			if(Dist < ClosestPlayerDistSq)
				ClosestPlayerDistSq = Dist;
		}

		if(ClosestPlayerDistSq < FMath::Square(VisualBoarder.GetScaledSphereRadius()))
			return false;

		if(ClosestPlayerDistSq > FMath::Square(DisableRange))
			return true;
			
		for(auto Player : Game::GetPlayers())
		{
			if(SceneView::ViewFrustumSphereIntersection(Player, VisualBoarder))
				return false;
		}

		return true;
	}
}

