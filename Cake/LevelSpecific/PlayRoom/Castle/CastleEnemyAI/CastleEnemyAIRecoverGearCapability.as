import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyThiefComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Pickups.PlayerPickupComponent;

class UCastleEnemyAIRecoverGearCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityTags.Add(n"CastleEnemyAI");

	ACastleEnemy OwningThief;
	UCastleEnemyThiefComponent ThiefComponent;
	UPlayerPickupComponent PlayerPickupComponent;

	AHazePlayerCharacter PlayerHoldingGear;

	float RecoverTime = 3.5f;
	float RecoverTimeCurrent = 0.f;

	UPROPERTY()
	UAnimSequence StealGearAnim;
	UPROPERTY()
	UAnimSequence PickupGearAnim;

	ACastleElevatorSwitchPickupable GearPickup;
	FHazeAnimationDelegate AnimationBlendingOut;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
		OwningThief = Cast<ACastleEnemy>(Owner);
		OwningThief.OnKilled.AddUFunction(this, n"OnEnemyKilled");
        ThiefComponent = UCastleEnemyThiefComponent::GetOrCreate(Owner);
		GearPickup = ThiefComponent.GearToChase;

		AnimationBlendingOut.BindUFunction(this, n"OnThiefAnimationBlendingOut");
    }
	
    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {	
		if (!ThiefComponent.bInsideRecoverRange)
        	return EHazeNetworkActivation::DontActivate; 

		if (ThiefComponent.DestinationElevator.bGearPlacedInElevator)
        	return EHazeNetworkActivation::DontActivate; 		

		if (ThiefComponent.bGearRecovered)
        	return EHazeNetworkActivation::DontActivate; 

		return EHazeNetworkActivation::ActivateUsingCrumb; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (ThiefComponent.DestinationElevator.bGearPlacedInElevator)
        	return EHazeNetworkDeactivation::DeactivateLocal; 

		if (ThiefComponent.bGearRecovered)
        	return EHazeNetworkDeactivation::DeactivateLocal; 

        return EHazeNetworkDeactivation::DontDeactivate; 
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerHoldingGear = nullptr;
		PlayerPickupComponent = nullptr;

		OwningThief.BlockCapabilities(n"CastleEnemyMovement", this);

		PlayerHoldingGear = ThiefComponent.GearToChase.HoldingPlayer;
		if(PlayerHoldingGear != nullptr)
		{
			PlayerHoldingGear.BlockCapabilities(n"Movement", this);
			PlayerHoldingGear.BlockCapabilities(n"Castle", this);

			if (StealGearAnim != nullptr)
				PlayThiefAnim(StealGearAnim);

			GearPickup.OnPutDownEvent.AddUFunction(this, n"OnPickupDropped");

			PlayerPickupComponent = UPlayerPickupComponent::Get(PlayerHoldingGear);	
			PlayerPickupComponent.ForceDrop(false);
		}
		else
		{
			if (StealGearAnim != nullptr)
				PlayThiefAnim(PickupGearAnim);	

			ThiefComponent.GearToChase.InteractionComponent.Disable(n"ThiefStolePickup");
			ThiefComponent.GearToChase.AttachToActor(OwningThief, n"RightAttach");
		}
	}

	UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		if (PlayerHoldingGear != nullptr)
		{
			PlayerHoldingGear.UnblockCapabilities(n"Movement", this);
			PlayerHoldingGear.UnblockCapabilities(n"Castle", this);
		}

		RecoverTimeCurrent = 0.f;
		OwningThief.UnblockCapabilities(n"CastleEnemyMovement", this);
		GearPickup.OnPutDownEvent.Unbind(this, n"OnPickupDropped");
	}

	UFUNCTION()
	void OnPickupDropped(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		ThiefComponent.GearToChase.AttachToActor(OwningThief, n"RightAttach");		
		ThiefComponent.GearToChase.InteractionComponent.Disable(n"ThiefStolePickup");
	}
	
	UFUNCTION()
	void OnEnemyKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		ThiefComponent.GearToChase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ThiefComponent.GearToChase.InteractionComponent.Enable(n"ThiefStolePickup");

		GearPickup.OnPutDownEvent.Unbind(this, n"OnPickupDropped");
		PlayerPickupComponent = nullptr;
	}

	void PlayThiefAnim(UAnimSequence Animation)
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Animation;
		OwningThief.PlaySlotAnimation(FHazeAnimationDelegate(), AnimationBlendingOut, AnimParams);
	}

	UFUNCTION()
	void OnThiefAnimationBlendingOut()
	{
		ThiefComponent.bGearRecovered = true;
	}	
}