
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightHitReaction;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class UFlyingMachineMeleeApplyPendingDamageCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeTakeDamage);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = MeleeTags::Melee;

	AHazePlayerCharacter PlayerOwner;
	UFlyingMachineMeleeComponent HazeMeleeComponent;
	bool bHasDied = false;
	bool bIsInFinishState = false;
	bool bHasBlockedCapabilities = false;
	FHazeMeleeTarget CurrentTaret;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HazeMeleeComponent = Cast<UFlyingMachineMeleeComponent>(MeleeComponent);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerOwner != nullptr && !CanPlayerBeDamaged(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlayerOwner != nullptr && !CanPlayerBeDamaged(PlayerOwner))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bHasDied)
		{
			if(bHasBlockedCapabilities)
			{
				bHasBlockedCapabilities = false;
				CurrentTaret.UnblockCapabilities(MeleeTags::MeleeTakeDamage, this);
				SetMutuallyExclusive(MeleeTags::Melee, false);
				SetStateMovementType(EHazeMeleeMovementType::Idling);		
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MeleeComponent.ConsumePendingDamage();
		if(!bHasDied && MeleeComponent.GetHealth() <= 0)
		{
			bHasDied = true;

			if(HasControl())
			{
				if(!bHasBlockedCapabilities)
				{
					bHasBlockedCapabilities = true;
					SetMutuallyExclusive(MeleeTags::Melee, true);

					// If we die, we block the other actors option to die
					MeleeComponent.GetCurrentTarget(CurrentTaret);
					CurrentTaret.BlockCapabilities(MeleeTags::MeleeTakeDamage, this);
				}
			}
		}

		if(bHasDied && !bIsInFinishState)
		{
			if(ShouldActivateFinishHim())
			{
				bIsInFinishState = true;			
				SetStateMovementType(EHazeMeleeMovementType::FinishHim);
				if(CurrentTaret.bIsToTheRightOfMe)
					FaceRight();
				else
					FaceLeft();
			}
		}
	}	

	bool ShouldActivateFinishHim()const
	{
		if(!HazeMeleeComponent.bWaitingForFinish)
		 	return false;

		if(IsStateActive(EHazeMeleeStateType::HitReaction))
		 	return false;

		return true;
	}
}
