import Peanuts.Spline.SplineComponent;

UCLASS(Abstract)
class AClockTownTreadMillElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BottomCog;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent TopCog;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BottomPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = BottomPlatformRoot)
	UStaticMeshComponent BottomPlatform;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TopPlatformRoot;

	UPROPERTY(DefaultComponent, Attach = TopPlatformRoot)
	UStaticMeshComponent TopPlatform;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UClockTownTreadMillElevatorDisableComponent DisableComponentExtension;
	default DisableComponentExtension.RelativeLocation = FVector(0.f, 0.f, 750.f);

	UPROPERTY(BlueprintReadOnly)
	float Speed = 500.f;
	UPROPERTY(BlueprintReadOnly)
	float CogSpeed = 70.f;
	
	UPROPERTY()
	FHazeTimeLike BottomTimeLike;
	default BottomTimeLike.bLoop = true;
	default BottomTimeLike.bSyncOverNetwork = true;
	default BottomTimeLike.SyncTag = n"BottomTimeLike";

	UPROPERTY()
	FHazeTimeLike TopTimeLike;
	default TopTimeLike.bLoop = true;
	default TopTimeLike.bSyncOverNetwork = true;
	default TopTimeLike.SyncTag = n"TopTimeLike";

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BottomCog.SetCullDistance(Editor::GetDefaultCullingDistance(BottomCog) * CullDistanceMultiplier);
		TopCog.SetCullDistance(Editor::GetDefaultCullingDistance(TopCog) * CullDistanceMultiplier);
		BottomPlatform.SetCullDistance(Editor::GetDefaultCullingDistance(BottomPlatform) * CullDistanceMultiplier);
		TopPlatform.SetCullDistance(Editor::GetDefaultCullingDistance(TopPlatform) * CullDistanceMultiplier);

		if (Speed != 0.f)
		{
			float TotalDuration = FMath::Abs(SplineComp.SplineLength / Speed);
			BottomTimeLike.Duration = TotalDuration;
			TopTimeLike.Duration = TotalDuration;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (Speed != 0.f)
		{
			float TotalDuration = FMath::Abs(SplineComp.SplineLength / Speed);
			BottomTimeLike.Duration = TotalDuration;
			TopTimeLike.Duration = TotalDuration;

			BottomTimeLike.BindUpdate(this, n"UpdateBottomTimeLike");
			TopTimeLike.BindUpdate(this, n"UpdateTopTimeLike");

			if (Speed > 0.f)
			{
				BottomTimeLike.PlayFromStart();
				TopTimeLike.SetNewTime(TotalDuration / 2.f);
				TopTimeLike.Play();
			}
			else
			{
				BottomTimeLike.ReverseFromEnd();
				TopTimeLike.SetNewTime(TotalDuration / 2.f);
				TopTimeLike.Reverse();
			}
		}
	}

	UFUNCTION()
	private void UpdateBottomTimeLike(float Alpha)
	{
		SetLocation(BottomPlatformRoot, Alpha);
	}

	UFUNCTION()
	private void UpdateTopTimeLike(float Alpha)
	{
		SetLocation(TopPlatformRoot, Alpha);
	}

	void SetLocation(USceneComponent Component, float Alpha)
	{
		FVector Location = SplineComp.GetLocationAtDistanceAlongSpline(Alpha * SplineComp.SplineLength, ESplineCoordinateSpace::World);
		Component.SetWorldLocation(Location);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BottomCog.AddLocalRotation(FRotator(0.f, 0.f, -CogSpeed * DeltaTime));
		TopCog.AddLocalRotation(FRotator(0.f, 0.f, -CogSpeed * DeltaTime));
	}
}



class UClockTownTreadMillElevatorDisableComponent : UBoxComponent
{
	default SetCollisionProfileName(n"NoCollision");
	default bGenerateOverlapEvents = false;
	default SetBoxExtent(500.f);

	UPROPERTY(Category = "Disable")
	float MaxVisualRange = 14000.f;

	AClockTownTreadMillElevator ElevatorOwner;
	bool bHasDisabled = false;
	float TimeToCheckDisable = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ElevatorOwner = Cast<AClockTownTreadMillElevator>(Owner);
		TimeToCheckDisable = FMath::RandRange(0.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// Dont disable
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ShouldBeDisabled() != bHasDisabled)
		{
			if(bHasDisabled)
				ElevatorOwner.EnableActor(this);
			else
				ElevatorOwner.DisableActor(this);

			bHasDisabled = !bHasDisabled;
		}
	}

	bool ShouldBeDisabled()
	{
		const float MaxRange = FMath::Square(MaxVisualRange);
		const float MinRange = FMath::Square(GetScaledBoxExtent().Size());
		float ClosestPlayerDistSq = BIG_NUMBER;
		for(auto Player : Game::GetPlayers())
		{
			const float Dist = Player.GetActorLocation().DistSquared(GetWorldLocation());
			if(Dist >= MaxRange)
				continue;

			if(Dist < ClosestPlayerDistSq)
				ClosestPlayerDistSq = Dist;

			if(ClosestPlayerDistSq < MinRange)
			{
				TimeToCheckDisable = 1.f;
				return false;
			}

			if(SceneView::ViewFrustumBoxIntersection(Player, this))
			{
				TimeToCheckDisable = 1.f;
				return false;
			}
		}

		// The longer away we are, the longer time we need to validate again
		float TimeAlpha = FMath::Max(ClosestPlayerDistSq - MaxRange, 0.f);
		TimeAlpha =	FMath::Min(TimeAlpha / (MaxRange * 2), 1.f);
		TimeToCheckDisable = FMath::Lerp(0.1f, 1.f, TimeAlpha);
		return true;		
	}
}