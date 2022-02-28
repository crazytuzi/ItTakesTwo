import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Gifts.HeliumPackage.HeliumPackage;

class UHeliumPackagePlayerCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	//default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"LevelSpecific";
	AHeliumPackage Package;
	AHazePlayerCharacter Player;

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION()
	bool GetIsPlayerIsCarryingPickup() const property
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::GetOrCreate(Player);
		AHeliumPackage NewPackage = Cast<AHeliumPackage>(PickupComp.CurrentPickup);

		if(NewPackage != nullptr)
			return true;
		else
			return false;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsPlayerIsCarryingPickup)
			return EHazeNetworkActivation::ActivateFromControl;

		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsPlayerIsCarryingPickup)
			return EHazeNetworkDeactivation::DontDeactivate;

		else
			return EHazeNetworkDeactivation::DeactivateFromControl;
	}
	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UMovementSettings::SetGravityMultiplier(Player, 2.5f, this);
		UMovementSettings::SetActorMaxFallSpeed(Owner, 250.0f, Instigator = this);
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::GetOrCreate(Player);
		Package = Cast<AHeliumPackage>(PickupComp.CurrentPickup);
		Package.SetCurrentState(EHeliumPackageState::PickedUpByPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings::ClearGravityMultiplier(Player, this);
		UMovementSettings::ClearActorMaxFallSpeed(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// if (!MoveComp.IsGrounded() && IsActioning(ActionNames::MovementJump))
		// {
			
		// }

		// else
		// {
		// 	UMovementSettings::ClearGravityMultiplier(Player, this);
		// }

		// if (MoveComp.IsGrounded())
		// {
		// 	Package.bIsGrounded = true;
		// }

		// else
		// {
		// 	Package.bIsGrounded = false;
		// }
		
	}
}