import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagFloorDropOff;

class UTagFloorDropOffCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagFloorDropOffCapability");
	default CapabilityTags.Add(n"Tag");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ATagFloorDropOff DropFloor;

	FVector StartingLocation;
	FVector FinishLocation;

	float ZOffset = -6500.f;
	float MoveSpeed = 1500.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DropFloor = Cast<ATagFloorDropOff>(Owner);

		StartingLocation = DropFloor.ActorLocation;
		FinishLocation = StartingLocation + FVector(0.f, 0.f, ZOffset);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DropFloor.TagFloorDropOffState == ETagFloorDropOffState::DropDown || DropFloor.TagFloorDropOffState == ETagFloorDropOffState::RiseUp)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DropFloor.TagFloorDropOffState == ETagFloorDropOffState::Still)
			return EHazeNetworkDeactivation::DeactivateLocal;

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
		if (DropFloor.TagFloorDropOffState == ETagFloorDropOffState::DropDown)
		{
			DropDown(DeltaTime);
		}
		else if (DropFloor.TagFloorDropOffState == ETagFloorDropOffState::RiseUp)
		{
			RiseUp(DeltaTime);
		}
	}

	UFUNCTION()
	void DropDown(float DeltaTime)
	{
		FVector NextLoc = FMath::VInterpConstantTo(DropFloor.ActorLocation, FinishLocation, DeltaTime, MoveSpeed);
		DropFloor.SetActorLocation(NextLoc);
		
		if (DropFloor.ActorLocation == FinishLocation)
		{
			DropFloor.TagFloorDropOffState = ETagFloorDropOffState::Still;
		}
	}

	UFUNCTION()
	void RiseUp(float DeltaTime)
	{
		FVector NextLoc = FMath::VInterpConstantTo(DropFloor.ActorLocation, StartingLocation, DeltaTime, MoveSpeed * 2.f);
		DropFloor.SetActorLocation(NextLoc);
	
		if (DropFloor.ActorLocation == StartingLocation)
		{
			DropFloor.TagFloorDropOffState = ETagFloorDropOffState::Still;
		}	
	}

}