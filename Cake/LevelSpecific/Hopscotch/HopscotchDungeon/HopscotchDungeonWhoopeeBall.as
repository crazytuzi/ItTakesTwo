import Vino.Pickups.PickupActor;
class AHopscotchDungeonWhoopeeBall : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapCollision;

	float StartZ = 0.f;
	float TargetZ = 0.f;
	float ZAddition = 750.f;
	float WeakLaunchTimer = 1.f;
	bool bShouldTickWeakLaunchTimer = false;
	
	UPROPERTY()
	UCurveFloat WeakLaunchCurve;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!HasControl())
			return;

		if (!bShouldTickWeakLaunchTimer)
			return;
		
		WeakLaunchTimer += DeltaTime;
		if (WeakLaunchTimer >= 1.f)
		{
			bShouldTickWeakLaunchTimer = false;
			WeakLaunchTimer = 1.f;
			NetSetPickupEnabled(true);
		}

		SetActorLocation(FMath::Lerp(FVector(ActorLocation.X, ActorLocation.Y, StartZ), FVector(ActorLocation.X, ActorLocation.Y, TargetZ), WeakLaunchCurve.GetFloatValue(WeakLaunchTimer)));
	}

	UFUNCTION()
	void WeakLaunchBall()
	{
		if (!HasControl())
			return;
			
		StartZ = ActorLocation.Z;
		TargetZ = ActorLocation.Z + ZAddition;
		WeakLaunchTimer = 0.f;
		bShouldTickWeakLaunchTimer = true;
		NetSetPickupEnabled(false);
	}

	UFUNCTION(NetFunction)
	void NetSetPickupEnabled(bool bEnabled)
	{
		if(bEnabled)
			for(auto Player : Game::GetPlayers())
				InteractionComponent.EnableForPlayer(Player, n"BallDisabled");
		else
			for(auto Player : Game::GetPlayers())
				InteractionComponent.DisableForPlayer(Player, n"BallDisabled");
	}
}