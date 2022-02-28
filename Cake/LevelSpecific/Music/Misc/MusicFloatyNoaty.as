

class UMusicFloatyNoatyDisable : UActorComponent
{
	UPROPERTY(Category = "Disabling")
	FHazeMinMax DisableRange = FHazeMinMax(2000.f, 40000.f);

	UPROPERTY(Category = "Disabling")
	float ViewRadius = 900.f;

	UPROPERTY(Category = "Disabling")
	float DontDisableWhileVisibleTime = 1.f;

	UStaticMeshComponent TargetMesh;
	AMusicFloatyNoaty FloatyOwner;
	float UpdateSpeed = 1.f;
	float CurveLength = 1.f;
	private float InternalTime = 0;
	bool bIsAutoDisabled = false;
	float LastTime = 0;
	float ClosestPlayerDistSq = BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// This component never disables
		return true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LastTime = InternalTime;
		InternalTime += DeltaSeconds * UpdateSpeed;
		InternalTime = Math::FWrap(InternalTime, 0.f, CurveLength);

		const bool bHasRestarted = InternalTime < LastTime;
		if(bHasRestarted)
			FloatyOwner.OnPlayFromStart();

		const bool bShouldBeAutoDisabled = ShouldAutoDisable();
		if(bIsAutoDisabled != bShouldBeAutoDisabled)
		{
			bIsAutoDisabled = bShouldBeAutoDisabled;
			SetActorDisabledInternal(bIsAutoDisabled);
		}
	}

	float GetTime() const property
	{
		return InternalTime;
	}

	private bool ShouldAutoDisable()
	{
		const FVector WorldLocation = FloatyOwner.GetActorLocation();
		if(bIsAutoDisabled && ClosestPlayerDistSq >= FMath::Square(DisableRange.Max))
		{
			ClosestPlayerDistSq = BIG_NUMBER;
			for(auto Player : Game::GetPlayers())
			{
				const float Dist = Player.GetActorLocation().DistSquared(WorldLocation);
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist;
			}
		}
		else
		{
			ClosestPlayerDistSq = BIG_NUMBER;
			for(auto Player : Game::GetPlayers())
			{
				const float Dist = Player.GetActorLocation().DistSquared(WorldLocation);
				if(Dist < ClosestPlayerDistSq)
					ClosestPlayerDistSq = Dist;

				if(TargetMesh.WasRecentlyRendered(DontDisableWhileVisibleTime))
					return false;

				if(Dist < FMath::Square(DisableRange.Min))
					return false;

				if(SceneView::ViewFrustumPointRadiusIntersection(Player, WorldLocation, ViewRadius))
					return false;
			}
		}

		return true;
	}

	private void SetActorDisabledInternal(bool bStatus)
	{
		if(bStatus)
			FloatyOwner.DisableActor(this);
		else
			FloatyOwner.EnableActor(this);
	}
}

class AMusicFloatyNoaty : AHazeActor
{
	UPROPERTY(EditDefaultsOnly)
	UCurveFloat Curve;

	FVector InitalLocation;
	FVector TargetLocation;

	UPROPERTY(DefaultComponent)
	UMusicFloatyNoatyDisable FloatyDisable;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisable;

	UFUNCTION(BlueprintCallable)
	void Setup(float ZOffset, float Speed, UStaticMeshComponent Mesh)
	{
		FloatyDisable.FloatyOwner = this;
		FloatyDisable.TargetMesh = Mesh;
		FloatyDisable.UpdateSpeed = Speed;
		float Min;
		Curve.GetTimeRange(Min, FloatyDisable.CurveLength);
		InitalLocation = GetActorLocation();
		TargetLocation = InitalLocation;
		TargetLocation.Z += ZOffset;

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float OffsetAlpha = Curve.GetFloatValue(FloatyDisable.Time);
		FVector NewLocation = FMath::Lerp(InitalLocation, TargetLocation, OffsetAlpha);
		SetActorLocation(NewLocation);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayFromStart(){}
}