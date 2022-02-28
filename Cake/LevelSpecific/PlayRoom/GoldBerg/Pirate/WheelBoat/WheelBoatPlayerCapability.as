import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;

class UWheelBoatPlayerCapability : UHazeCapability
{
    default CapabilityTags.Add(n"WheelBoat");
    default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UOnWheelBoatComponent BoatComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BoatComp = UOnWheelBoatComponent::Get(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BoatComp.WheelBoat == nullptr)
            return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Player.BlockCapabilities(n"Movement", this);
        Player.BlockCapabilities(n"Collision", this);
        Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(CameraTags::Control, this);				
	
		Player.AddLocomotionAsset(Player.IsCody() ? BoatComp.WheelBoat.CodyLocomotion : BoatComp.WheelBoat.MayLocomotion, this);
		Player.BlockMovementSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CameraTags::Control, this);
		Player.UnblockCapabilities(n"Collision", this);
		Player.UnblockCapabilities(n"Death", this);
		Player.ClearLocomotionAssetByInstigator(this);
		Player.UnblockMovementSyncronization(this);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"WheelBoat";
		Player.RequestLocomotion(Data);
	}
};