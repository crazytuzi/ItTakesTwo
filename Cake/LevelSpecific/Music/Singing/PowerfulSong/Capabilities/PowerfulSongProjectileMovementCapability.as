import Cake.LevelSpecific.Music.Singing.PowerfulSong.Capabilities.PowerfulSongProjectileBaseCapability;

class UPowerfulSongProjectileMovementCapability : UHazeCapability
{
	FHitResult Hit;
	TArray<AActor> ActorsToIgnore;
	APowerfulSongProjectile SongProjectile;

	FVector ForwardDirection;
	float MaxDistance = 0.0f;

	float DistanceMoved = 0.0f;

	int BounceTotal = 1;
	int BounceCurrent = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SongProjectile = Cast<APowerfulSongProjectile>(Owner);

		ActorsToIgnore.Add(Game::GetMay());
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SongProjectile.TargetActor != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SongProjectile.bActive)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ForwardDirection = Owner.ActorForwardVector;
		MaxDistance = SongProjectile.MaxDistance;
		DistanceMoved = 0.0f;
		BounceCurrent = 0;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SongProjectile.TargetActor != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!SongProjectile.bActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SongProjectile.ProjectileLifetimeExpired();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BounceCurrent < BounceTotal)
		{
			Hit.Reset();
			const float TraceLength = 250.0f;
			const FVector StartLoc = Owner.ActorCenterLocation;
			const FVector EndLoc = Owner.ActorCenterLocation + Owner.ActorForwardVector * TraceLength;
			System::LineTraceSingle(StartLoc, EndLoc, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, false);

			if(Hit.bBlockingHit)
			{
				
				const FVector Normal = Hit.Normal;
				float Dot = Normal.DotProduct(FVector::UpVector);

				if(Dot != 0.0f && Dot > 0.6f)
				{
					ForwardDirection = ForwardDirection.ConstrainToPlane(Normal);
				}
				else
				{
					ForwardDirection = FMath::GetReflectionVector(Owner.ActorForwardVector, Normal);
					BounceCurrent++;
					DistanceMoved = MaxDistance * 0.89f;
				}
				
				Owner.SetActorRotation(ForwardDirection.ToOrientationQuat());
				SongProjectile.BP_OnProjectileBounce();
			}
		}

		if(DistanceMoved > MaxDistance)
		{
			SongProjectile.bActive = false;
		}

		const FVector CurrentLocation = Owner.ActorLocation;
		Owner.AddActorWorldOffset(Owner.ActorForwardVector * SongProjectile.MovementSpeed * DeltaTime);
		DistanceMoved += Owner.ActorLocation.Distance(CurrentLocation);
	}

	UFUNCTION(NetFunction)
	private void NetOnImpact(USongReactionComponent SongReaction)
	{
		FPowerfulSongInfo Info;
		Info.Instigator = SongProjectile.OwnerPlayer;
		Info.ImpactLocation = SongProjectile.ActorCenterLocation;
		Info.Direction = SongProjectile.ActorForwardVector;
		Info.Projectile = SongProjectile;

		SongReaction.OnPowerfulSongImpact.Broadcast(Info);
	}
}
