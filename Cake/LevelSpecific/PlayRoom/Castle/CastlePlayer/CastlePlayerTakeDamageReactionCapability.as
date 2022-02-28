import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
class UCastlePlayerTakeDamageReactionCapability : UHazeCapability
{	
	AHazePlayerCharacter Player;
	UCastleComponent CastleComp;

	bool bShouldBeActive = false;
	FCastlePlayerDamageEvent Damage;

	UPROPERTY()
	TPerPlayer<FCastlePlayerTakeDamageReactionAnimations> PlayerAnimations;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Player = Cast<AHazePlayerCharacter>(Owner);
		CastleComp = UCastleComponent::GetOrCreate(Owner);

		CastleComp.OnDamageTaken.AddUFunction(this, n"OnDamageTaken");
    }

	UFUNCTION()
	void OnDamageTaken(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
	{
		bShouldBeActive = true;
		Damage = DamageEvent;
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (bShouldBeActive)
            return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;			
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DeactivateLocal;
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		Player.FlashPlayer(0.4f);

		TArray<UAnimSequence> Animations = PlayerAnimations[Player].Animations;
		if (Animations.Num() == 0)
			return;

		int AnimationIndex = FMath::RandRange(0, Animations.Num() - 1);
		UAnimSequence AnimationToPlay = Animations[AnimationIndex];

		if (AnimationToPlay != nullptr)
			Player.PlayAdditiveAnimation(FHazeAnimationDelegate(), AnimationToPlay, BlendTime = 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bShouldBeActive = false;
		Damage = FCastlePlayerDamageEvent();
	}
}

struct FCastlePlayerTakeDamageReactionAnimations
{
	UPROPERTY()
	TArray<UAnimSequence> Animations;
}