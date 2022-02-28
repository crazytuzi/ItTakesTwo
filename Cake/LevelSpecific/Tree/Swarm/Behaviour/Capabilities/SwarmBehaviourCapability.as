
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

UCLASS(Abstract)
class USwarmBehaviourCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmBehaviour");

	default TickGroup = ECapabilityTickGroups::GamePlay;

	/* Should be overridden by children */
	ESwarmBehaviourState AssignedState = ESwarmBehaviourState::None;

	ASwarmActor SwarmActor = nullptr;
	USwarmVictimComponent VictimComp = nullptr;
	USwarmBehaviourSettings Settings = nullptr;
	USwarmMovementComponent MoveComp = nullptr;
	USwarmBehaviourComponent BehaviourComp = nullptr;
	USwarmSkeletalMeshComponent SkelMeshComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BaseSetup();
	}

	void BaseSetup()
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		MoveComp = USwarmMovementComponent::Get(Owner);
		Settings = USwarmBehaviourSettings::GetSettings(Owner);
		SkelMeshComp = USwarmSkeletalMeshComponent::Get(Owner);
		BehaviourComp = USwarmBehaviourComponent::Get(Owner);
		VictimComp = USwarmVictimComponent::Get(Owner);

		ensure(AssignedState != ESwarmBehaviourState::None);

		BehaviourComp.OnRotateTickGroupOrders.AddUFunction(
			this,
			n"HandleTickGroupOrderUpdated"
		);

		// LEGACY ACCORDING TO SYDNEY, Tyko
		//CapabilityTags.Add(GetSwarmCapabilityTag(AssignedState));
		
		SetTickGroupOrder(GetSwarmTickGroupOrder(AssignedState));
	}

	void PrioritizeState(ESwarmBehaviourState InState)
	{
		BehaviourComp.RequestStatePrioritization(InState);
	}

	UFUNCTION()
	void HandleTickGroupOrderUpdated(int DeltaSteps)
	{
		const int TickGroupOrder_Inital = int(GetSwarmTickGroupOrder(AssignedState));
		const int TickGroupOrder_MAX = int(GetSwarmTickGroupOrder(ESwarmBehaviourState::MAX));
		int TickGroupOrder_New = (TickGroupOrder_Inital + DeltaSteps) % TickGroupOrder_MAX;

		// Tyko stole TickGroupOrder = 0 for debug so we'll have to offset it.
		TickGroupOrder_New += 1;

		// We might exceed 200 due to the new offset mentioned above
		ensure(TickGroupOrder_New <= 200);

		SetTickGroupOrder(TickGroupOrder_New);
	}

	bool CalculateDesiredQuatWhileGentlemaning(FQuat& OutQuat) const
	{
		int GentlemanIndex = -1;
		if(SwarmActor.VictimComp.IsGentlemaning(GentlemanIndex))
		{
			// Hmm we dont support that many officially right now
			ensure(GentlemanIndex < 4);

			float Delta_DEG = 40.f;
			float TargetDeg = (-Delta_DEG * 0.5f) + (Delta_DEG * float(GentlemanIndex));

			const int NumSwarmOpponents = SwarmActor.VictimComp.GetNumSwarmOpponents();
			if(NumSwarmOpponents > 2)
			{
				Delta_DEG = 40.f;

				// Uneven num opponents
				if((NumSwarmOpponents % 2) != 0)
				{
					TargetDeg = (-Delta_DEG) + (Delta_DEG * float(GentlemanIndex));
				}
			}

			// ground normal is to unreliable in queen lvl
			const FVector GroundNormal = FVector::UpVector;
			// const FVector GroundNormal = VictimComp.GetVictimGroundNormal();

			OutQuat *= FQuat(GroundNormal, DEG_TO_RAD * TargetDeg);

			// PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Victim: " + VictimComp.CurrentVictim.GetName());
			// PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Gentleman index: " + GentlemanIndex);
			// System::DrawDebugSphere(Owner.GetActorLocation());

			return true;
		}

		// System::DrawDebugSphere(Owner.GetActorLocation());
		// PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Victim: " + VictimComp.CurrentVictim);
		// PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Gentleman index: " + GentlemanIndex);
		return false;
	}

	bool IsAtleastOnePlayerAttackable() const
	{
		for(AHazePlayerCharacter PlayerIter : Game::GetPlayers())
		{
			if(IsPlayerAttackable(PlayerIter))
			{
				return true;
			}
		}

		return false;
	}

	bool IsPlayerAttackable(AHazePlayerCharacter InPlayer) const
	{
		if(IsPlayerAliveAndGrounded(InPlayer))
		{
			// We placed it here so that we can debug it more easily. 
			// Don't merge it with the if statement above!
			if(!IsPlayerGrinding(InPlayer))
			{
				return true;
			}
		}
		return false;
	}

	bool IsPlayerAliveAndGrounded(AHazePlayerCharacter InPlayer) const
	{
		return SwarmActor.VictimComp.IsPlayerAliveAndGrounded(InPlayer);
	}

	bool IsPlayerGrinding(AHazePlayerCharacter InPlayer) const
	{
		return SwarmActor.VictimComp.IsPlayerGrinding(InPlayer);
	}

}


















