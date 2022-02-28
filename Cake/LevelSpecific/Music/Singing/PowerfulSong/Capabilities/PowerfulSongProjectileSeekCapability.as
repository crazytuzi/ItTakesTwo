import Cake.LevelSpecific.Music.Singing.PowerfulSong.Capabilities.PowerfulSongProjectileBaseCapability;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class UPowerfulSongProjectileSeekCapability : UHazeCapability
{
	FHazeAcceleratedVector CurrentLocation;
	float TimeToReachTarget = 0;
	float Elapsed = 0;

	APowerfulSongProjectile SongProjectile;
	UMusicWeaponTargetingComponent Targeting;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SongProjectile = Cast<APowerfulSongProjectile>(Owner);
		Targeting = UMusicWeaponTargetingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(SongProjectile.TargetActor == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentLocation.Value = Owner.ActorLocation;
		Targeting.StartTargetingWithTime(Owner.ActorCenterLocation, SongProjectile.TargetComponent.WorldLocation, SongProjectile.TimeToReachTarget);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SongProjectile.TargetActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Targeting.HasReachedLocation())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SongProjectile.ProjectileLifetimeExpired();

		if(SongProjectile.TargetActor != nullptr)
		{
			USongReactionComponent SongReaction = USongReactionComponent::Get(SongProjectile.TargetActor);

			if(SongReaction != nullptr)
			{
				FPowerfulSongInfo Info;
				Info.Instigator = SongProjectile.OwnerPlayer;
				Info.ImpactLocation = SongProjectile.ActorCenterLocation;
				Info.Direction = SongProjectile.ActorForwardVector;
				Info.Projectile = SongProjectile;

				SongReaction.OnPowerfulSongImpact.Broadcast(Info);
			}

			SongProjectile.AddDebugHit(SongProjectile.TargetActor);
		}

		SongProjectile.TargetActor = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FMusicWeaponTargetingOutput Movement;
		Targeting.Move(DeltaTime, SongProjectile.TargetComponent.WorldLocation, Movement);
		Owner.SetActorLocationAndRotation(Movement.Location, Movement.Rotation);
	}
}
