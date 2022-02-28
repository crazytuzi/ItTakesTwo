import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Mage.CastleMageFrozenOrb;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Mage.CastleMageFrozenOrbUltimate;

UCLASS(Abstract)
class UCastleMageFrozenOrbAbility : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityFrozenOrb");
    default CapabilityTags.Add(n"GameplayAction");

	default SlotName = n"FrozenOrb";

	float FrozenOrbCooldown = 2.f;
    float Cooldown = FrozenOrbCooldown;
    float CooldownCurrent = 0.f;	

	int SpawnOrbCounter = 0;

    UPROPERTY()
	TSubclassOf<ACastleMageFrozenOrb> FrozenOrbType;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
    {
        if (CooldownCurrent > 0)
            CooldownCurrent -= DeltaTime;

		if (SlotWidget != nullptr)
		{
			SlotWidget.CooldownDuration = Cooldown;
			SlotWidget.CooldownCurrent = CooldownCurrent;
		}

		if (WasActionStarted(ActionNames::CastleAbilitySecondary))
			SlotWidget.SlotPressed();
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!FrozenOrbType.IsValid())
			return EHazeNetworkActivation::DontActivate; 		

		if (CooldownCurrent > 0)
			return EHazeNetworkActivation::DontActivate; 

		if (!CastleComponent.bComboCanAttack)
			return EHazeNetworkActivation::DontActivate;   
		
		if (!IsActioning(ActionNames::CastleAbilitySecondary))
			return EHazeNetworkActivation::DontActivate;       

		return EHazeNetworkActivation::ActivateUsingCrumb;       
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
    {
		FVector AttackDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		if (AttackDirection.IsNearlyZero())
			AttackDirection = OwningPlayer.ActorForwardVector;

		auto TargetEnemy = CastleComponent.FindTargetEnemy(FRotator::MakeFromX(AttackDirection), 3250.f, 45.f);
		if (TargetEnemy != nullptr)
		{
			FVector ToEnemy = TargetEnemy.ActorLocation - Owner.ActorLocation;
			ToEnemy.Normalize();
			AttackDirection = ToEnemy;
		}

		ActivationParams.AddVector(n"Location", Owner.ActorLocation + FVector(0, 0, 100.f));
		ActivationParams.AddVector(n"Direction", AttackDirection);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (FrozenOrbType.IsValid())
		{
			ACastleMageFrozenOrb FrozenOrb = Cast<ACastleMageFrozenOrb>(SpawnActor(FrozenOrbType,
				ActivationParams.GetVector(n"Location"),
				FRotator::MakeFromX(ActivationParams.GetVector(n"Direction")),
				bDeferredSpawn = true));

			FrozenOrb.SetControlSide(OwningPlayer);
			FrozenOrb.OwningPlayer = OwningPlayer;	
			FrozenOrb.MakeNetworked(this, SpawnOrbCounter++);
			FinishSpawningActor(FrozenOrb);

			Cooldown = FrozenOrbCooldown;	
			CooldownCurrent = Cooldown;	
			
			PlayAnimation();
		}

		SlotWidget.SlotActivated();		

	} 

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{                 
        return EHazeNetworkDeactivation::DeactivateLocal;
	}  

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

    }

	void PlayAnimation()
	{       
		if (CastleComponent.MageAnimationData == nullptr)
			return;		

		FCastleAbilityAnimation AttackAnimData = CastleComponent.MageAnimationData.FrozenOrb;

        if (AttackAnimData.Animation != nullptr)
		{
			FHazeSlotAnimSettings AnimSettings;
			AnimSettings.BlendTime = AttackAnimData.AnimationSettings.BlendTime;
			AnimSettings.PlayRate = AttackAnimData.AnimationSettings.PlayRate;

			OwningPlayer.PlaySlotAnimation(AttackAnimData.Animation, AnimSettings);
		}			
	}
}