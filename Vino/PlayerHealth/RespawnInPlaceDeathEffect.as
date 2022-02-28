import Vino.PlayerHealth.TimedPlayerDeathEffect;
import Vino.PlayerHealth.RespawnInPlace;
import Vino.Checkpoints.Volumes.DeathVolume;

UCLASS(Abstract)
class URespawnInPlaceDeathEffect : UTimedPlayerDeathEffect
{
	default bAllowRespawnInPlace = true;
	default bHidePlayerAfterEffectFinishes = false;

	void Activate() override
	{
		Super::Activate();
	}

	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		// If we are inside an actual death volume that
		// has an effect that isn't a respawn in place effect,
		// then we consider ourselves gibbed and won't respawn in place.
		if (!IsGibbed())
		{
			TArray<AActor> Overlaps;
			Player.GetOverlappingActors(Overlaps);

			for (auto Overlap : Overlaps)
			{
				if (Cast<ADisallowRespawnInPlaceVolume>(Overlap) != nullptr)
				{
					TriggerGib();
					break;
				}

				auto DeathVolume = Cast<ADeathVolume>(Overlap);
				if (DeathVolume != nullptr)
				{
					UClass EffectClass = DeathVolume.DeathEffect.Get();
					bool bAllowsRespawnInPlace = false;

					if (EffectClass != nullptr)
						bAllowsRespawnInPlace = Cast<UPlayerDeathEffect>(EffectClass.GetDefaultObject()).bAllowRespawnInPlace;

					if (!bAllowsRespawnInPlace)
					{
						TriggerGib();
						break;
					}
				}
			}
		}

		// If the effect has finished and we still aren't grounded, gib
		// and prevent the respawn in place from occurring.
		if (bFinished && !IsGibbed())
		{
			auto MoveComp = UHazeBaseMovementComponent::Get(Player);
			if (!MoveComp.IsGrounded())
				TriggerGib();
		}
	}

	void TriggerGib()
	{
		bAllowRespawnInPlace = false;
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
		BP_Gib();
	}
	
	UFUNCTION(BlueprintPure)
	bool IsGibbed()
	{
		return !bAllowRespawnInPlace;
	}

	UFUNCTION()
	void BP_Gib() {}

	void Deactivate() override
	{
		if (!bAllowRespawnInPlace)
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);
			Player.SetActorHiddenInGame(false);
		}

		Super::Deactivate();
	}
};