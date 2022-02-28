import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

/* 
	Lets the swarm know where they can be parked next to the queen.
	It needs to inherit from USceneComponent due to the Meta = (MakeEditWidget)
*/ 

event void FOnSwarmParked(ASwarmActor Swarm);
event void FOnSwarmUnparked(ASwarmActor Swarm);

UCLASS(HideCategories = "Physics LOD Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class UQueenParkingSpotComponent : USceneComponent 
{
	// If the parking spots should rotate when the queen rotates.
	UPROPERTY(Category = "ParkingSpotSettings")
	bool bRotateParkingSpotsWithQueen = false;

	// Will save the Root location on begin play and just use that. 
	UPROPERTY(Category = "ParkingSpotSettings")
	bool bUseFixedRootLocation = true;

	// Sheet that holds the capabilities for the swarm that define how it should act when parked. 
	UPROPERTY(Category = "ParkingSpotSettings")
	UHazeCapabilitySheet SwarmParkingCapabilitySheet;

	UPROPERTY(AdvancedDisplay, Category = "ParkingSpotSettings")
	USwarmAnimationSettingsBaseDataAsset OptionalParkingAnimation;

	// the location for the parking spots. 
	UPROPERTY(Meta = (MakeEditWidget), Category = "ParkingSpotSettings")
	TArray<FTransform> ParkingSpots_LocalSpace;

	UPROPERTY(NotEditable, Category = "ParkingSpotSettings")
	TMap<ASwarmActor, USwarmAnimationSettingsBaseDataAsset> SwarmToPrevAnimSettingsMap;

	UPROPERTY(NotEditable, Category = "ParkingSpotSettings")
	TMap<ASwarmActor, int32> SwarmParkingSpotIndiciesMap;

	// Whether the swarm can park
	UPROPERTY(NotEditable, Category = "ParkingSpotSettings")
	TArray<int32> VacantIndices;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FOnSwarmParked OnSwarmParked;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FOnSwarmUnparked OnSwarmUnparked;

	TArray<FTransform> ParkingSpots_WorldSpaceFixed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay() 
	{
		UpdateParkingSpotLocations();
	}

	void SetParkingSpotsToWorldLoc(FVector InWorldLocation)
	{
		FVector Local = GetWorldTransform().InverseTransformPosition(InWorldLocation);

		for (FTransform& Spot : ParkingSpots_LocalSpace)
		{
			Spot.Location = Local;
		}

		UpdateParkingSpotLocations();
	}

	UFUNCTION()
	void UpdateParkingSpotLocations()
	{
		VacantIndices.Reset();
		ParkingSpots_WorldSpaceFixed.Reset();

		for (int32 i = 0; i < ParkingSpots_LocalSpace.Num(); ++i)
		{
			VacantIndices.Add(i);
			ParkingSpots_WorldSpaceFixed.Add(ParkingSpots_LocalSpace[i] * GetWorldTransform());
		}
	}

	UFUNCTION()
	void ParkSwarm(ASwarmActor InSwarm)
	{
		if (VacantIndices.Num() <= 0)
		{
			// All parking spots have been taken. 
			ensure(false);
			return;
		}

		if(SwarmParkingSpotIndiciesMap.Contains(InSwarm))
		{
			// this swarm is already parked!
			ensure(false);
			return;
		}

		if(SwarmParkingCapabilitySheet == nullptr)
		{
			devEnsure(false, "You forgot to assign BehaviourSheet on the ParkingSpotComponent");
			return;
		}

		int32 AssignedIndex = VacantIndices[0];
		SwarmParkingSpotIndiciesMap.Add(InSwarm, AssignedIndex);
		VacantIndices.RemoveAt(0);

		if(OptionalParkingAnimation != nullptr)
		{
			auto CurrentSwarmAnimSettings = InSwarm.SkelMeshComp.GetSwarmAnimSettingsDataAsset();	
			SwarmToPrevAnimSettingsMap.Add(InSwarm, CurrentSwarmAnimSettings);
			InSwarm.PlaySwarmAnimation(OptionalParkingAnimation, this, 0.2f);
		}

		InSwarm.SetCapabilityAttributeObject(n"Queen", GetOwner());
		InSwarm.AddCapabilitySheet(SwarmParkingCapabilitySheet);

		OnSwarmParked.Broadcast(InSwarm);
	}

	UFUNCTION()
	bool IsParked(ASwarmActor InSwarm)
	{
		return SwarmParkingSpotIndiciesMap.Contains(InSwarm);
	}

	UFUNCTION()
	void UnparkSwarm(ASwarmActor InSwarm)
	{
		if(SwarmParkingSpotIndiciesMap.Contains(InSwarm) == false)
		{
			// trying to unpark something that isn't parked!
			ensure(false);
			return;
		}

		if(SwarmParkingCapabilitySheet == nullptr)
		{
			devEnsure(false, "You forgot to assign BehaviourSheet on the ParkingSpotComponent");
			return;
		}
		
		if(SwarmToPrevAnimSettingsMap.Contains(InSwarm))
		{
			InSwarm.StopSwarmAnimationByInstigator(this);
			SwarmToPrevAnimSettingsMap.Remove(InSwarm);
		}

		int32 VacantIndex = SwarmParkingSpotIndiciesMap[InSwarm];
		SwarmParkingSpotIndiciesMap.Remove(InSwarm);
		VacantIndices.Add(VacantIndex);

		InSwarm.RemoveCapabilitySheet(SwarmParkingCapabilitySheet);

		OnSwarmUnparked.Broadcast(InSwarm);
	}

	UFUNCTION()
	void ParkSwarms(TArray<ASwarmActor> Swarms)
	{
		for(ASwarmActor Swarm : Swarms)
		{
			ParkSwarm(Swarm);
		}
	}

	UFUNCTION()
	void UnparkSwarms(TArray<ASwarmActor> Swarms)
	{
		for(ASwarmActor Swarm : Swarms)
		{
			UnparkSwarm(Swarm);
		}
	}
};