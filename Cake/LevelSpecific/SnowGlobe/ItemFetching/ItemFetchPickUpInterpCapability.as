import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPickUp;

class UItemFetchPickUpInterpCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ItemFetchPickUpInterpCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AItemFetchPickUp Item;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Item = Cast<AItemFetchPickUp>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Item.PickUpState == EPickUpState::Recieved)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Item.PickUpState == EPickUpState::Complete)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Item.SetActorLocation(FMath::VInterpConstantTo(Item.ActorLocation, Item.DestinationLoc, DeltaTime, 1500.f));
		Item.SetActorRotation(FMath::RInterpConstantTo(Item.ActorRotation, Item.DestinationRot, DeltaTime, 500.f));

		float Distance = (Item.DestinationLoc - Item.ActorLocation).Size();

		if (Distance == 0.f)
			Item.PickUpState == EPickUpState::Complete;
	}
}