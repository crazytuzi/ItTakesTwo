import Peanuts.Spline.SplineComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class AMoonBaboonLaserBomb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent FieldComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent BallComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent SplineComp;

	UPROPERTY(DefaultComponent, Attach = BallComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ShotFiredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExplosionEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ExpandTimeLike;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	float ActiveTime = 3.f;

	float CurrentDistanceAlongSpline = 0.f;
	float SpeedAlongSpline = 2600.f;

	bool bExpanding = false;
	bool bMovingAlongSpline = false;
	bool bExpired = false;

	float CurrentDamageDistance = 0.f;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ExpandTimeLike.BindUpdate(this, n"UpdateExpand");
		ExpandTimeLike.BindFinished(this, n"FinishExpand");
		HazeAkComp.SetStopWhenOwnerDestroyed(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bExpired)
			return;

		if (bMovingAlongSpline)
		{
			CurrentDistanceAlongSpline += SpeedAlongSpline * DeltaTime;
			FVector CurLoc = SplineComp.GetLocationAtDistanceAlongSpline(CurrentDistanceAlongSpline, ESplineCoordinateSpace::World);
			BallComp.SetWorldLocation(CurLoc);

			if (CurrentDistanceAlongSpline >= SplineComp.SplineLength)
				ActivateBomb();
		}
		else
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				float DistanceToPlayer = (FieldComp.WorldLocation - Player.ActorLocation).Size();
				if (DistanceToPlayer < CurrentDamageDistance && Player.HasControl())
				{
					Player.DamagePlayerHealth(0.25f, DeathEffect = DeathEffect);
				}
			}
		}
	}

	UFUNCTION()
	void LaunchBomb(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			TargetPlayer = Game::GetMay();

		TargetPlayer = Player;

		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
		FHitResult Hit;
		System::LineTraceSingle(TargetPlayer.ActorLocation, TargetPlayer.ActorLocation - FVector(0.f, 0.f, 5000.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

		FVector PlayerVelocity = TargetPlayer.ActualVelocity;
		PlayerVelocity = Math::ConstrainVectorToPlane(PlayerVelocity, FVector::UpVector);
		FVector TargetLoc = Hit.ImpactPoint + (Player.ActorForwardVector * PlayerVelocity.Size() * 2.f);

		FVector MoonBaboonGroundLoc = FVector(ActorLocation.X, ActorLocation.Y, TargetLoc.Z);
		FVector Dir = TargetLoc - MoonBaboonGroundLoc;
		Dir = Math::ConstrainVectorToPlane(Dir, FVector::UpVector);
		Dir.Normalize();

		float DistanceToTargetLoc = (MoonBaboonGroundLoc - TargetLoc).Size();
		DistanceToTargetLoc = FMath::Clamp(DistanceToTargetLoc, 0.f, 4750.f);
		TargetLoc = MoonBaboonGroundLoc + (Dir * DistanceToTargetLoc);

		FVector MidPoint = (ActorLocation/2) + (TargetLoc/2);
		MidPoint += Dir * 350.f;
		SplineComp.SetLocationAtSplinePoint(1, MidPoint + FVector(0.f, 0.f, 850.f), ESplineCoordinateSpace::World);

		SplineComp.SetLocationAtSplinePoint(2, TargetLoc, ESplineCoordinateSpace::World);
		SplineComp.SetTangentAtSplinePoint(0, FVector(0.f, 0.f, 500.f), ESplineCoordinateSpace::Local);
		SplineComp.SetTangentAtSplinePoint(2, FVector(0.f, 0.f, -500.f), ESplineCoordinateSpace::Local);

		CurrentDistanceAlongSpline = 0.f;
		bMovingAlongSpline = true;

		bExpired = false;
		SetActorTickEnabled(true);

		HazeAkComp.HazePostEvent(ShotFiredEvent);

		BP_LaunchBomb();
	}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchBomb() {}

	UFUNCTION()
	void ActivateBomb()
	{
		FieldComp.SetWorldLocation(SplineComp.GetLocationAtSplinePoint(2, ESplineCoordinateSpace::World));
		bMovingAlongSpline = false;
		bExpanding = true;
		ExpandTimeLike.PlayFromStart();
		BP_Land();
		HazeAkComp.HazePostEvent(ImpactEvent);
		HazeAkComp.HazePostEvent(ExplosionEvent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Land() 
	{
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateExpand(float CurValue)
	{
		CurrentDamageDistance = FMath::Lerp(0.f, 800.f, CurValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishExpand()
	{
		if (bExpanding)
			System::SetTimer(this, n"Shrink", ActiveTime, false);
		else
			DeactivateBomb();
	}

	UFUNCTION(NotBlueprintCallable)
	void Shrink()
	{
		bExpanding = false;
		ExpandTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void DeactivateBomb()
	{
		bExpired = true;
		SetActorTickEnabled(false);
	}
}