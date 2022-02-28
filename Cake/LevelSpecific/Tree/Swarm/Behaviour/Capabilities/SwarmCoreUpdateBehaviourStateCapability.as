
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

class USwarmCoreUpdateBehaviourStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmBehaviour");
	default CapabilityTags.Add(n"SwarmUpdateState");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	USwarmBehaviourComponent BehaviourComp = nullptr;

	TArray<ESwarmBehaviourState> RequestStatePriorityQueue;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = USwarmBehaviourComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (HasControl())
		{
			NetResetTickGroupOrder();
		}
	}

	int DebugNewStateCounter = 0;

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{

#if TEST
		DebugNewStateCounter -= 1;
		if(DebugNewStateCounter < 0) 
			DebugNewStateCounter = 0;
#endif TEST

		// Accumulate all requested States, in case replica lags behind.
		if (BehaviourComp.IsNewStatePriorityRequested() && HasControl())
		{
			NetAddRequestToQueue(BehaviourComp.StatePriorityRequested);

#if TEST
			DebugNewStateCounter += 2;
			if(DebugNewStateCounter > 100)
			{
				// Swarm is jumping between behaviour states to often.
				// This will trigger to many net messages to be sent. 
//				PrintToScreenScaled(Owner.GetName() + " Is stuck in limbo state, let sydney know pls.");
//				devEnsure(false, Owner + " Is switching behaviour states way to often and as a result sending to many net messages...\n Let sydney know about this please");
			}
#endif TEST

		}

		// Process Stack. Once per tick. 
		if (RequestStatePriorityQueue.Num() != 0)
		{
			BehaviourComp.PropagateStatePrioritization(RequestStatePriorityQueue[0]);
			RequestStatePriorityQueue.RemoveAt(0);
		}

		// reset it for next tick
		BehaviourComp.UnfinalizeBehaviour();

#if TEST
//		PrintDebug();
#endif TEST

	}

	UFUNCTION(NetFunction)
	void NetAddRequestToQueue(ESwarmBehaviourState StateRequested)
	{
		RequestStatePriorityQueue.Add(StateRequested);
	}

	UFUNCTION(NetFunction)
	void NetResetTickGroupOrder() 
	{
		BehaviourComp.ResetTickGroupOrder();
	}

	void PrintDebug() const
	{
		ASwarmActor DasSwarm = Cast<ASwarmActor>(Owner);
		// FString Str = "\n \n \n \n";
		FString Str = "\n";
		Str += "Swarm State for ";
		Str += Owner.GetName() + " ("+ DasSwarm.GetCurrentShape() + ")";
		Str += "\n";
		Str += "State Priority Requested: ";
		Str += GetSwarmDebugStateName(BehaviourComp.StatePriorityRequestedPrev);
		Str += " (Previous State)";
		Str += "\n";
		Str += "State Priority Requested: ";
		Str += GetSwarmDebugStateName(BehaviourComp.StatePriorityRequested);
		Str += " ";
		Str += BehaviourComp.GetStateDuration();
		Str += "\n";
		Str += "Queue Num: ";
		Str += RequestStatePriorityQueue.Num();

		if (RequestStatePriorityQueue.Num() > 0)
		{
			for(int i = 0; i < RequestStatePriorityQueue.Num(); ++i)
			{
				auto& State = RequestStatePriorityQueue[i];
				Str += "[" + i + "]";
				Str += "RequestStatePriorityQueue: ";
				Str += GetSwarmDebugStateName(State);
				Str += "\n";
			}
		}

		//Str += "\n";

		PrintToScreen(Str, 0.f, FLinearColor::Yellow);
	}

    /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FVector TempVec = FVector(400.f, 10.f, 0.f);

		FString Str = "Swarm State";

		Str += "\n";
		Str += "\n";

		Str += "State Priority Requested (Previous): <Yellow>";
		Str += GetSwarmDebugStateName(BehaviourComp.StatePriorityRequestedPrev);
		Str += "</>";

		Str += "\n";

		Str += "State Priority Requested: <Yellow>";
		Str += GetSwarmDebugStateName(BehaviourComp.StatePriorityRequested);
		Str += "</>";

		Str += "\n";
		Str += "\n";

		Str += "Queue Num: ";
		Str += RequestStatePriorityQueue.Num();
		Str += "\n";
		Str += "\n";

		if (RequestStatePriorityQueue.Num() > 0)
		{
			for(int i = 0; i < RequestStatePriorityQueue.Num(); ++i)
			{
				auto& State = RequestStatePriorityQueue[i];
				Str += "[" + i + "]";
				Str += "RequestStatePriorityQueue: <Blue>";
				Str += GetSwarmDebugStateName(State);
				Str += "</>";
				Str += "\n";
			}
		}

		Str += "\n";

        return Str;
	}

}
