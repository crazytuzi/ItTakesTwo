import Cake.LevelSpecific.Tree.Queen.QueenActor;
import Cake.LevelSpecific.Tree.Queen.QueenSettings;

class UQuenOnHitCapability : UHazeCapability
{
	AQueenActor Queen = nullptr;
	UQueenSettings Settings = nullptr;
	bool bIsPlayingSlotAnimation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Queen = Cast<AQueenActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Queen.ArmorComponentHandler.HealthyArmorComponents.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Queen.ArmorComponentHandler.HealthyArmorComponents.Num() > 0) 
			return EHazeNetworkDeactivation::DontDeactivate;
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Queen.OnArmourTakenDamage.AddUFunction(this, n"HandleDamageTaken");
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Queen.OnArmourTakenDamage.Unbind(this, n"HandleDamageTaken");
    }

	UFUNCTION()
	void HandleDamageTaken(FVector HitLocation, USceneComponent HitComponent, FName HitSocket,	float DamageTaken)
	{
		if (IsActioning(n"SpecialAttack"))
		{
			return;
		}

		
		if (!bIsPlayingSlotAnimation)
		{
			FHazeAnimationDelegate AnimDelegate;
			AnimDelegate.BindUFunction(this, n"HitAnimationDone");
			UQueenArmorComponent QueenArmor = Cast<UQueenArmorComponent>(HitComponent);
			UAnimSequence AnimToPlay = QueenArmor.OnHitAnimation;

			Queen.PlaySlotAnimation(AnimDelegate, Animation = AnimToPlay, PlayRate = 1.f);
			bIsPlayingSlotAnimation = true;
		}
	}

	UFUNCTION()
	void HitAnimationDone()
	{
		bIsPlayingSlotAnimation = false;
	}
}