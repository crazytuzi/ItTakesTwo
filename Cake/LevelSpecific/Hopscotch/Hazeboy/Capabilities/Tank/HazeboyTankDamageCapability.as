import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyTankDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazeboyTank Tank;
	float HoldTime = 0.f;

	int NumOverlappedExplosions = 0;
	FVector ExplosionOrigin;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
		Tank.BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
		Tank.BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"HandleEndOverlap");
	}

	UFUNCTION()
	void HandleBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
	{
		auto Explosion = Cast<AHazeboyExplosion>(OtherActor);
		if (Explosion == nullptr)
			return;

		if (Explosion.OwnerPlayer == Tank.OwningPlayer)
			return;

		if (!Explosion.OwnerPlayer.HasControl())
			return;

		NetAddOverlappedExplosion(Explosion.ActorLocation);
	}

    UFUNCTION()
    void HandleEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		auto Explosion = Cast<AHazeboyExplosion>(OtherActor);
		if (Explosion == nullptr)
			return;

		if (Explosion.OwnerPlayer == Tank.OwningPlayer)
			return;

		if (!Explosion.OwnerPlayer.HasControl())
			return;

		NetSubtractOverlappedExplosion();
    }

	UFUNCTION(NetFunction)
	void NetAddOverlappedExplosion(FVector Origin)
	{
		NumOverlappedExplosions++;
		ensure(NumOverlappedExplosions >= 0);

		ExplosionOrigin = Origin;
	}

	UFUNCTION(NetFunction)
	void NetSubtractOverlappedExplosion()
	{
		NumOverlappedExplosions--;
		ensure(NumOverlappedExplosions >= 0);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (Tank.ImmuneTimer > 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (NumOverlappedExplosions <= 0 && HazeboyIsPointWithinRing(Tank.ActorLocation))
	        return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HazeboyPlayDamageBark(Tank.OwningPlayer);
		Tank.TakeDamage(ExplosionOrigin);
	}
}