
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourSettingsContainer;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourStates;

event void FSwarmRotateTickGroupOrderEvent(int StepsToRotate);

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmBehaviourComponent : UActorComponent
{
	UPROPERTY(Category = "Behaviour")
	UHazeCapabilitySheet DefaultBehaviourSheet;
	UHazeCapabilitySheet CurrentBehaviourSheet;

	UPROPERTY(Category = "Behaviour")
	USwarmBehaviourBaseSettings DefaultSettings = nullptr;
	USwarmBehaviourBaseSettings CurrentBehaviourSettings = nullptr;

	/* Used to propagate out tickOrder changes to all capabilities.  */
 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FSwarmRotateTickGroupOrderEvent OnRotateTickGroupOrders;

	ESwarmBehaviourState StatePriorityRequested = ESwarmBehaviourState::None;
	ESwarmBehaviourState StatePriorityRequestedPrev = ESwarmBehaviourState::None;
	private bool bFinalizedBehaviour = false;
	private float TimeStamp_StateChanged = 0.f;
	private bool bStateOverrideRequested = false;

	ESwarmShape	PreviousShape = ESwarmShape::None;

	float TimeStamp_LastExplosionDuringState = 0.f;

	AHazeActor HazeOwner = nullptr;
	UHazeAITeam Team = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(GetOwner());

        Team = HazeOwner.JoinTeam(n"SwarmTeam");       

		// GetOrCreate Settings component and TransientDataAsset
		auto SettingsPtr = USwarmBehaviourSettings::GetSettings(HazeOwner);

		if (DefaultBehaviourSheet != nullptr)
			SwitchSheet(DefaultBehaviourSheet);

		if (DefaultSettings != nullptr)
			SwitchSettings(DefaultSettings);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
  		ResetTransientStateParams();

		// We have to check if we've left the team already because 
		// we leave the time when the actor gets disabled as well.
        if(Team != nullptr)
		{
			HazeOwner.LeaveTeam(n"SwarmTeam");
			Team = nullptr;
		}

    }

	void ResetTransientStateParams()
	{
		StatePriorityRequested = ESwarmBehaviourState::None;
		StatePriorityRequestedPrev = ESwarmBehaviourState::None;
		TimeStamp_StateChanged = 0.f;
		bFinalizedBehaviour = false;
	}

	void SwitchSheet(UHazeCapabilitySheet InSheet)
	{
		// remove previous sheet.
		if(CurrentBehaviourSheet != nullptr)
			HazeOwner.RemoveCapabilitySheet(CurrentBehaviourSheet);

		// Add new sheet.
		CurrentBehaviourSheet = InSheet;
		HazeOwner.AddCapabilitySheet(InSheet);

		ResetTickGroupOrder();
	}

	void SwitchSettings(USwarmBehaviourBaseSettings InSettings)
	{
		if (CurrentBehaviourSettings != nullptr)
		{
			PreviousShape = CurrentBehaviourSettings.Shape;
			HazeOwner.ClearSettingsWithAsset(CurrentBehaviourSettings, this);
		}

		CurrentBehaviourSettings = InSettings;

		HazeOwner.ApplySettings(InSettings, this, EHazeSettingsPriority::Defaults);
	}

	/* whether a capability has finalized behaviour this tick */
	bool HasBehaviourBeenFinalized() const
	{
		return bFinalizedBehaviour;
	}

	void FinalizeBehaviour()
	{
		bFinalizedBehaviour = true;
	}

	void UnfinalizeBehaviour()
	{
		bFinalizedBehaviour = false;
	}

	void ResetTickGroupOrder() 
	{
		ResetTransientStateParams();
		RequestStatePrioritization(ESwarmBehaviourState::MAX);
	}

	void OverrideStatePrioritization(ESwarmBehaviourState RequestedStateToPrioritize)
	{
		StatePriorityRequested = RequestedStateToPrioritize;
		bStateOverrideRequested = true;
	}

	void RequestStatePrioritization(ESwarmBehaviourState RequestedStateToPrioritize)
	{
		// Don't allow any new state to be requested until we handle the override
		if (bStateOverrideRequested)
			return;

		StatePriorityRequested = RequestedStateToPrioritize;
	}

	void PropagateStatePrioritization(ESwarmBehaviourState StateToPrioritize)
	{
 		StatePriorityRequestedPrev = StatePriorityRequested;
		bStateOverrideRequested = false;

		// Calculate how many steps every capability needs to 
		// rotate in order for the desired state to reach 
		// highest priority in the behaviour tree  
		const int TickGroupOrder_Inital = int(GetSwarmTickGroupOrder(StateToPrioritize));
		const int TickGroupOrder_MAX = int(GetSwarmTickGroupOrder(ESwarmBehaviourState::MAX));
		int DeltaSteps = TickGroupOrder_MAX - TickGroupOrder_Inital;
		OnRotateTickGroupOrders.Broadcast(DeltaSteps);
	}

	bool IsNewStatePriorityRequested() const
	{
		if (bStateOverrideRequested)
			return true;

		return StatePriorityRequested != StatePriorityRequestedPrev;
	}

    void ReportAttack()
    {
        Team.ReportAction(n"SwarmAttack");
    }

    void ReportAttackUltimate()
    {
        Team.ReportAction(n"SwarmAttackUltimate");
    }

	float GetTimeSincePlayerWasAttacked() const
	{
		return Time::GetGameTimeSince(Team.GetLastActionTime(n"SwarmAttack"));
	}

	bool IsAttackOnCooldown(float InCooldown) const
	{
		return Time::GetGameTimeSeconds() > (Team.GetLastActionTime(n"SwarmAttack") + InCooldown);
	}

	bool IsUltimateOnCooldown(float InCooldown) const
	{
		const float LastActionTime = Team.GetLastActionTime(n"SwarmAttackUltimate");
		if (LastActionTime == 0.f)
			return false;

		const float CurrentTime = FMath::Max(Time::GetGameTimeSeconds(), InCooldown);
		const float CooldownTimeThreshold = LastActionTime + InCooldown;
		return CurrentTime < CooldownTimeThreshold;

// 		return Time::GetGameTimeSeconds() < (Team.GetLastActionTime(n"SwarmAttackUltimate") + InCooldown);
	}

	void NotifyStateChanged()
	{
		TimeStamp_StateChanged = Time::GetGameTimeSeconds();
	}

    float GetStateDuration() const
    {
        return Time::GetGameTimeSince(TimeStamp_StateChanged);
    }

	bool HasExplodedSinceStateChanged_PostTimeWindow(float TimeWindow = 1.f) const
	{
		const float TimeBetween = TimeStamp_LastExplosionDuringState - TimeStamp_StateChanged;
		return TimeBetween >= TimeWindow;
	}

	bool HasExplodedSinceStateChanged_WithinTimeWindow(float TimeWindow = 1.f) const
	{
		const float TimeBetween = TimeStamp_LastExplosionDuringState - TimeStamp_StateChanged;
		if (TimeBetween < 0.f)
			return false;
		return TimeBetween < TimeWindow;
	}

}
