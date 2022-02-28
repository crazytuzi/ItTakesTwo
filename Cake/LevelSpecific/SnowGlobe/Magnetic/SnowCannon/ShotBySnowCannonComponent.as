import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

event void FOnSnowCannonShotDestroyed(UShotBySnowCannonComponent Component);

enum EMagneticBasePadState
{
	Idle,
	IceSliding,
	Falling
};

class UShotBySnowCannonComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExploEvent;

	FHitResult IceWall;
	FOnSnowCannonShotDestroyed OnSnowCannonShotDestroyed;

	UPROPERTY(Category = Particles)
	UNiagaraSystem TrailFX;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> ExplodingDeathEffect;

	float SlideSpeed = 200.0f;
	float AccelerationSpeed = 2000.0f;
	float FallSpeed = 3500.0f;

	float RotationSpeed = 50.0f;
	FRotator RotationToRotate = FRotator(1, 0, 1);

	EMagneticBasePadState CurrentState;

	void Explode()
	{
		Niagara::SpawnSystemAtLocation(ExplosionEffect, Owner.ActorLocation);
		CurrentState = EMagneticBasePadState::Idle;
		OnSnowCannonShotDestroyed.Broadcast(this);

		TMap<FString, float> Rtpcs;
		Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -8.f);

		UHazeAkComponent::HazePostEventFireForgetWithRtpcs(ExploEvent, Owner.ActorTransform, Rtpcs);

		// Kill player if perching on exploding magnet
		for(AHazePlayerCharacter PlayerCharacter : Game::Players)
		{
			FHazeQueriedActivationPoint ActivePoint;
			if(PlayerCharacter.GetActivePoint(UMagneticPerchAndBoostComponent::StaticClass(), ActivePoint))
			{
				if(ActivePoint.Point.Owner == Owner && PlayerCharacter.IsAnyCapabilityActive(FMagneticTags::PlayerMagnetLaunchPerchCapability))
				{
					PlayerCharacter.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
					KillPlayer(PlayerCharacter, ExplodingDeathEffect);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetMagnetState(EMagneticBasePadState NetMagnetState)
	{
		CurrentState = NetMagnetState;
	}
}