import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPlayerComp;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchDropOffPoint;
import Cake.LevelSpecific.SnowGlobe.ItemFetching.ItemFetchPickUp;

class UItemFetchPlayerGiveCapability : UHazeCapability
{
	//If component bool is true
	//When player throws, rotate towards direction 
	//Play throwing animation

	//Throw Trajectory

	//Somehow needs to detatch from actors hand

	default CapabilityTags.Add(n"ItemFetchPlayerGiveCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	
	UItemFetchPlayerComp PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UItemFetchPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.CleanupCurrentMovementTrail();
		
		AItemFetchDropOffPoint DropOffPoint;
		
		AItemFetchPickUp ItemPickUp;

		if (PlayerComp.DropOffPoint != nullptr)
 			DropOffPoint = Cast<AItemFetchDropOffPoint>(PlayerComp.DropOffPoint);

		FVector Direction = (DropOffPoint.ActorLocation - Player.ActorLocation).GetSafeNormal();
		
		FRotator NewRot = FRotator::MakeFromX(Direction);
		
		Player.SmoothSetLocationAndRotation(Player.ActorLocation, NewRot, 1.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}