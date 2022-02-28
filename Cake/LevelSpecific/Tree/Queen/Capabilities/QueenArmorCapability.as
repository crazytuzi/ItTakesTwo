import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;
import Cake.LevelSpecific.Tree.Queen.QueenArmorComponentHandler;
import Peanuts.DamageFlash.DamageFlashStatics;

class UQueenArmorCapability : UQueenBaseCapability 
{
	default CapabilityTags.Add(n"QueenArmorTakeDamage");

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		
		if(Queen.ArmorComponentHandler.HealthyArmorComponents.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	int Index;

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
        Queen.OnDamageTaken.AddUFunction(this, n"HandleDamageTaken");
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Queen.OnDamageTaken.Unbind(this, n"HandleDamageTaken");
    }

	UFUNCTION()
	void FlashMaterial(int InIndex)
	{
		Index = InIndex;
		PerformFlash();
		System::SetTimer(this, n"PerformFlash", 0.2f, true);
		System::SetTimer(this, n"StopFlashling", 2, false);
	}

	UFUNCTION()
	void StopFlashling()
	{
		System::ClearTimer(this, "PerformFlash");
	}

	UFUNCTION()
	void PerformFlash()
	{
		FlashMaterialIndex(Queen.Mesh, Index, 0.2f);
	}

	UFUNCTION()
	void HandleDamageTaken(
		FVector HitLocation,
		USceneComponent HitComponent,
		FName HitSocket,
        float DamageTaken
	)
	{

		if (IsActioning(n"SpecialAttack"))
			return;

		if (!HasControl())
			return;

		// the IsActioning(SpecialAttack) statement above requires this to be networked. 
		// OnArmorTakenDamage listeners react to damage taken with unnecessary netfunction calls
		// which inevitably call SetActionState(SpecialAttack) which routes back here.
		// IsActioning(SpecialAttack) isn't immediate on both sides due to being networked.
		// OnArmorTakenDamage listeners shouldn't have to network their calls 
		// - because this is already networked by SapsExplosions (which this function subscribes to)
		// Listeners have to remove their netfunctions before we can remove the HasControl() here.

		TArray<UQueenArmorComponent> ArmorComponents = Queen.ArmorComponentHandler.HealthyArmorComponents;

		for (auto Component : ArmorComponents)
		{
			if (Component.SocketNames.Contains(HitSocket))
			{
				if (!Component.IgnoreDamage)
				{
					NetHandleArmorDamageTaken(HitLocation, HitComponent, HitSocket, DamageTaken, Component);
				}
				
				return;
			}
		}

	}

	UFUNCTION(NetFunction)
	void NetHandleArmorDamageTaken(
		FVector HitLocation,
		USceneComponent HitComponent,
		FName HitSocket,
		float DamageTaken,
		UQueenArmorComponent Component
	)
	{
		float ComponentDamageTaken = Component.HP;
		Component.HP -= DamageTaken;
		if(Component.HP <= 0)
		{
			PlayImpactAnimation(Component);
			Queen.ArmorComponentHandler.HealthyArmorComponents.Remove(Component);
			Queen.OnArmourTakenDamage.Broadcast(HitLocation, Component, HitSocket, ComponentDamageTaken);
		}
		else
		{
			Queen.OnArmourTakenDamage.Broadcast(HitLocation, Component, HitSocket, DamageTaken);
//			FlashMaterial(Component.MaterialIndex);
		}
	}

	void PlayImpactAnimation(UQueenArmorComponent Component)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Component.DetachfromQueenAnimToPlay;
		Params.PlayRate = 1.f;
		Queen.StopAllSlotAnimations(0);
		Queen.PlaySlotAnimation(Params);

		// !!! note that we replaced the networked function here because we networked HandleDamageTaken instead
		// Component.NetDetachFromQueen(true);
		Component.DetachFromQueen(true);
	}
}