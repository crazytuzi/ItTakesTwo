import Cake.LevelSpecific.Basement.BasementBoss.BeingOfLight;

class UBeingOfLightPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ABeingOfLight BeingOfLight;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"BeingOfLight"))
        	return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BeingOfLight = Cast<ABeingOfLight>(GetAttributeObject(n"BeingOfLight"));

		GetActiveParentBlobActor().BlockCapabilities(CapabilityTags::Movement, this);
		GetActiveParentBlobActor().AttachToActor(BeingOfLight);
		GetActiveParentBlobActor().SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (GetActiveParentBlobActor() == nullptr)
			return;
			
		GetActiveParentBlobActor().UnblockCapabilities(CapabilityTags::Movement, this);
		GetActiveParentBlobActor().DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		BeingOfLight.UpdatePlayerInput(Player, Input.X);
	}
}