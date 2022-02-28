import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)
class UCastleBasicAttackAbility : UCastleAbilityCapability
{
    default CapabilityTags.Add(n"AbilityBasicAttack");
    default CapabilityTags.Add(CapabilityTags::Input);

	UPROPERTY(Category = "Combo Data")
	int ComboNumber = 1;

	default TickGroupOrder = 10;

	UPROPERTY(Category = "Combo Data")
	float ComboTime = 0.f;
	UPROPERTY(Category = "Combo Data")
	float ComboTimeBeforeCancel = 0.16f;
	UPROPERTY(Category = "Combo Data")
	float ComboSuccessTime = 0.4f;
	UPROPERTY(Category = "Combo Data")
	float ComboAttackLength = 0.4f;	
	UPROPERTY(Category = "Combo Data")
	UAkAudioEvent ComboSound;

	UHazeAkComponent AkComp;

 	ACastleEnemy TargetEnemy;
	FVector AttackDirection;

	default SlotName = n"BasicAttack";

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
		AkComp = UHazeAkComponent::GetOrCreate(Owner);

		TickGroupOrder = 10 - ComboNumber;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::CastleAbilityPrimary) && ComboNumber == 1) 
			SlotWidget.SlotPressed();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComponent.CanCalculateMovement())
            return EHazeNetworkActivation::DontActivate;

        if (!WasActionStartedDuringTime(ActionNames::CastleAbilityPrimary, 0.1f))
            return EHazeNetworkActivation::DontActivate;

		if (CastleComponent.ComboCurrent == ComboNumber - 1 && CastleComponent.bComboCanAttack)
            return EHazeNetworkActivation::ActivateUsingCrumb; 

		if (ComboNumber == 1 && CastleComponent.bComboCanReset)
            return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComponent.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (CastleComponent.ComboCurrent != ComboNumber)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (ComboTime >= ComboAttackLength)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (WasActionStarted(ActionNames::CastleAbilityPrimary) && CastleComponent.bComboCanReset && ComboNumber == 1)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	float GetRangeForAutoTarget()
	{
		return 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		AttackDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (AttackDirection.IsNearlyZero())
			AttackDirection = OwningPlayer.ActorForwardVector;

		ActivationParams.AddVector(n"AttackDirection", AttackDirection.GetSafeNormal());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		ComboTime = 0.f;
		CastleComponent.ComboCurrent = ComboNumber;
		CastleComponent.bComboCanAttack = false;
		CastleComponent.bComboCanReset = false;

		SlotWidget.SlotActivated();

		AkComp.HazePostEvent(ComboSound);

		// Lock players movement and rotation
		AttackDirection = ActivationParams.GetVector(n"AttackDirection");
        OwningPlayer.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		
		//FaceTowardsEnemyTarget();
		UMovementSettings::SetMoveSpeed(Owner, 10.f, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ComboTime += DeltaTime;

		if (ComboTime >= ComboTimeBeforeCancel && ComboTime <= ComboSuccessTime)
		{
			CastleComponent.bComboCanAttack = true;
			CastleComponent.bComboCanReset = false;

		}
		else if (ComboTime > ComboSuccessTime)
		{
			CastleComponent.bComboCanAttack = false;
			CastleComponent.bComboCanReset = true;
		}
		else
		{
			CastleComponent.bComboCanAttack = false;
			CastleComponent.bComboCanReset = false;
		}

		if (ComboTime >= ComboAttackLength)
		{
			CastleComponent.ComboCurrent = 0;
			CastleComponent.bComboCanAttack = true;
			CastleComponent.bComboCanReset = false;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Unblock players movement and rotation
        OwningPlayer.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		OwningPlayer.ClearSettingsByInstigator(Instigator = this);

		if (CastleComponent.ComboCurrent == ComboNumber)
		{
			// We deactivated without another combo becoming active, so reset it
			CastleComponent.ComboCurrent = 0;
			CastleComponent.bComboCanAttack = true;
			CastleComponent.bComboCanReset = false;
		}
	}  

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		CastleComponent.ComboCurrent = 0;
		CastleComponent.bComboCanAttack = true;
		CastleComponent.bComboCanReset = false;

		//OwningPlayer.StopAllSlotAnimations(0.f);
	}
}