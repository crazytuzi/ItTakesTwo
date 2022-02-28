import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

UCLASS(Abstract)
class UCastleAbilityCapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(n"Castle");
    default CapabilityTags.Add(n"Ability");
    default CapabilityTags.Add(n"CastleAbility");
    default CapabilityTags.Add(n"GameplayAction");

	default TickGroup = ECapabilityTickGroups::ActionMovement;	

    default CapabilityDebugCategory = n"Castle";

    UPROPERTY(NotEditable)
    AHazePlayerCharacter OwningPlayer;
    UPROPERTY(NotEditable)
    UHazeBaseMovementComponent MoveComponent;
    UPROPERTY(NotEditable)
    UCastleComponent CastleComponent;	

	FName SlotName;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
        MoveComponent = UHazeBaseMovementComponent::Get(Owner);

		CastleComponent = UCastleComponent::Get(Owner);	

		Super::Setup(SetupParams);
	}

    UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return true;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::DontActivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
        OwningPlayer.BlockCapabilities(n"CastleAbility", this);
        OwningPlayer.BlockCapabilities(CapabilityTags::MovementAction, this);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        OwningPlayer.UnblockCapabilities(n"CastleAbility", this);
        OwningPlayer.UnblockCapabilities(CapabilityTags::MovementAction, this);
	} 

	UFUNCTION(BlueprintPure)
	UCastlePlayerAbilityBarWidget GetAbilityBarWidget() property
	{
		return CastleComponent.GetOrCreateHUD().GetAbilityBarForPlayer(OwningPlayer);
	}

	UFUNCTION(BlueprintPure)
	UCastlePlayerAbilitySlotWidget GetSlotWidget() property
	{
		return CastleComponent.GetOrCreateHUD().GetAbilityBarForPlayer(OwningPlayer).GetWidgetForSlot(SlotName);
	}

	UFUNCTION(BlueprintPure)
	FRotator GetOwningPlayersRotation() property
	{
		FRotator PureRotation = OwningPlayer.GetActorRotation();
		return FRotator(0, PureRotation.Yaw, 0);
	}   
}